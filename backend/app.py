from fastapi import FastAPI, UploadFile, File, Form, Header, HTTPException, Depends, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from typing import Optional, List, Dict
from io import BytesIO
from PIL import Image
from datetime import datetime
import os, json

# --- DB layer ---
from db.queries import (
    get_pests, get_pest_detail,
    get_drugs, get_drugs_for_pest,
    create_user, check_login,
    get_user, is_admin,
    create_pest, add_pest_photo, create_drug, link_drug_to_pest,
)

# --- ML inference ---
from ml_infer import (
    classify_image,
    MODEL_PATH, LABELS_PATH,
    reindex_static, index_info,
)

app = FastAPI(title="Durian Pest API")

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Static (để /static/xxx.jpg truy cập được)
if os.path.isdir("static"):
    app.mount("/static", StaticFiles(directory="static"), name="static")


# ---------- Helpers: auth qua header X-User ----------
def current_user(x_user: Optional[str] = Header(default=None, alias="X-User")) -> Optional[str]:
    return x_user

def require_admin(x_user: Optional[str] = Header(default=None, alias="X-User")) -> str:
    if not x_user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="X-User required")
    if not is_admin(x_user):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Admin required")
    return x_user


# ===================== PUBLIC APIs =====================

@app.get("/pests")
def list_pests(q: Optional[str] = None) -> Dict[str, List[Dict]]:
    return {"items": get_pests(q)}

@app.get("/pests/{code}")
def pest_detail(code: str) -> Dict[str, object]:
    pest = get_pest_detail(code)
    return {"pest": pest} if pest else {"error": "not_found"}

@app.get("/drugs")
def list_drugs() -> Dict[str, List[Dict]]:
    return {"items": get_drugs()}

@app.get("/pests/{code}/drugs")
def pest_drugs(code: str) -> Dict[str, List[Dict]]:
    return {"items": get_drugs_for_pest(code)}


@app.post("/classify")
async def classify(file: UploadFile = File(...)) -> Dict[str, List[Dict]]:
    """
    1) đọc ảnh từ client
    2) đưa vào ml_infer.classify_image (ảnh static + CNN)
    3) với mỗi dự đoán -> trả thêm detail + thuốc
    """
    img = Image.open(BytesIO(await file.read())).convert("RGB")
    preds = classify_image(img, topk=3)   # [{code, prob}, ...]

    results = []
    for p in preds:
        code = p["code"]
        prob = p["prob"]               # 0..1
        detail = get_pest_detail(code)
        drugs = get_drugs_for_pest(code)
        results.append({
            "prediction": {
                "code": code,
                "prob": prob,          # Flutter tự nhân 100 và clamp 0..100
            },
            "detail": detail,
            "drugs": drugs,
        })
    return {"results": results}


# ===================== AUTH =====================

@app.post("/auth/register")
def register(username: str = Form(...), password: str = Form(...)) -> Dict[str, bool]:
    ok = create_user(username, password)
    return {"ok": ok}

@app.post("/auth/login")
def login(username: str = Form(...), password: str = Form(...)) -> Dict[str, bool]:
    ok = check_login(username, password)
    return {"ok": ok}

@app.get("/auth/me")
def me(user: Optional[str] = Depends(current_user)) -> Dict[str, object]:
    if not user:
        return {"username": None, "is_admin": False}
    u = get_user(user)
    if not u:
        return {"username": user, "is_admin": False}
    return {"username": u["Username"], "is_admin": bool(u["IsAdmin"])}

@app.get("/health")
def health() -> Dict[str, bool]:
    return {"ok": True}


# ===================== ML INFO / DEBUG =====================

@app.get("/ml/info")
def ml_info() -> Dict[str, object]:
    def stat(path: str):
        try:
            s = os.stat(path)
            return {
                "path": os.path.abspath(path),
                "size": s.st_size,
                "mtime": datetime.fromtimestamp(s.st_mtime).isoformat()
            }
        except Exception:
            return None

    num_classes = 0
    try:
        with open(LABELS_PATH, "r", encoding="utf-8") as f:
            num_classes = len(json.load(f))
    except Exception:
        pass

    return {
        "model": stat(MODEL_PATH),
        "labels": stat(LABELS_PATH),
        "num_classes": num_classes
    }

@app.get("/ml/index")
def ml_index() -> Dict[str, object]:
    return index_info()

@app.post("/ml/reindex")
def ml_reindex() -> Dict[str, object]:
    return reindex_static()


# ===================== ADMIN APIs =====================

@app.post("/admin/pests", dependencies=[Depends(require_admin)])
def admin_create_pest(
    Code: str = Form(...),
    TenThuong: Optional[str] = Form(""),
    TenKhoaHoc: Optional[str] = Form(""),
    MoTaNgan: Optional[str] = Form(""),
    NhanBiet: Optional[str] = Form(None),
    BienPhapIPM: Optional[str] = Form(None),
    TacHai: Optional[str] = Form(""),
) -> Dict[str, object]:
    ok, new_id, err = create_pest({
        "Code": Code,
        "TenThuong": TenThuong,
        "TenKhoaHoc": TenKhoaHoc,
        "MoTaNgan": MoTaNgan,
        "NhanBiet": NhanBiet,
        "BienPhapIPM": BienPhapIPM,
        "TacHai": TacHai,
    })
    if not ok:
        raise HTTPException(status_code=400, detail=f"create_pest failed: {err}")
    return {"ok": True, "id": new_id}

@app.post("/admin/pests/{code}/photos", dependencies=[Depends(require_admin)])
def admin_add_photo(code: str, url: str = Form(...)) -> Dict[str, bool]:
    ok = add_pest_photo(code, url)
    if not ok:
        raise HTTPException(status_code=400, detail="add_photo failed (code không tồn tại hoặc URL trùng)")
    return {"ok": True}

@app.post("/admin/drugs", dependencies=[Depends(require_admin)])
def admin_create_drug(
    Ten: str = Form(...),
    HoatChat: Optional[str] = Form(""),
    Nhom: Optional[str] = Form(""),
    Hang: Optional[str] = Form(""),
    HuongDan: Optional[str] = Form(""),
    GhiChu: Optional[str] = Form(""),
) -> Dict[str, object]:
    ok, new_id, err = create_drug({
        "Ten": Ten,
        "HoatChat": HoatChat,
        "Nhom": Nhom,
        "Hang": Hang,
        "HuongDan": HuongDan,
        "GhiChu": GhiChu,
    })
    if not ok:
        raise HTTPException(status_code=400, detail=f"create_drug failed: {err}")
    return {"ok": True, "id": new_id}

@app.post("/admin/pests/{code}/drugs", dependencies=[Depends(require_admin)])
def admin_link_drug(code: str, drug_id: int = Form(...)) -> Dict[str, bool]:
    ok = link_drug_to_pest(code, drug_id)
    if not ok:
        raise HTTPException(status_code=400, detail="link failed (code không tồn tại hoặc đã gắn)")
    return {"ok": True}
