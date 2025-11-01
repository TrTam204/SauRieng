import os
import glob
from typing import List, Dict, Optional
import numpy as np
from PIL import Image

import tensorflow as tf
from tensorflow.keras.applications import mobilenet_v2
from tensorflow.keras.applications.mobilenet_v2 import preprocess_input

# =========================
#  CẤU HÌNH
# =========================
# nơi bạn để model CNN (nếu có)
MODEL_PATH = os.path.join("models", "mobilenetv2_durian.h5")
LABELS_PATH = os.path.join("models", "labels.json")

# nơi bạn để ảnh mẫu để so khớp trực tiếp
STATIC_GLOB = os.environ.get("STATIC_INDEX_GLOB", "static/*.jpg")

IMG_SIZE = int(os.environ.get("STATIC_INDEX_IMG_SIZE", "224"))
# nhiệt độ cho softmax của static: càng nhỏ càng nhọn
STATIC_TEMP = float(os.environ.get("STATIC_INDEX_T", "0.05"))

# =========================
#  FEATURE EXTRACTOR CHO STATIC
# =========================
_base = mobilenet_v2.MobileNetV2(
    include_top=False,
    pooling="avg",
    weights="imagenet"
)
_feat_model = tf.keras.Model(_base.input, _base.output)

def _prep_image(pil_or_path) -> np.ndarray:
    """đưa ảnh về (1,224,224,3) + preprocess mobilenetv2"""
    if isinstance(pil_or_path, Image.Image):
        img = pil_or_path.convert("RGB")
    else:
        img = Image.open(pil_or_path).convert("RGB")
    img = img.resize((IMG_SIZE, IMG_SIZE))
    arr = np.array(img, dtype=np.float32)
    arr = np.expand_dims(arr, 0)
    arr = preprocess_input(arr)
    return arr

def _embed(arr4d: np.ndarray) -> np.ndarray:
    """trả về vector L2-normalize"""
    vec = _feat_model(arr4d, training=False).numpy()
    vec /= (np.linalg.norm(vec, axis=1, keepdims=True) + 1e-10)
    return vec

# =========================
#  INDEX STATIC (IN-MEMORY)
# =========================
STATIC_INDEX: Optional[np.ndarray] = None   # (M,1280)
STATIC_LABELS: List[str] = []               # ['sau_rom', 'sau_duc_la', ...]
STATIC_FILES: List[str] = []                # ['static/sau_rom.jpg', ...]

def build_static_index() -> None:
    """Quét lại static/*.jpg và build index"""
    global STATIC_INDEX, STATIC_LABELS, STATIC_FILES

    paths = sorted(glob.glob(STATIC_GLOB))
    if not paths:
        STATIC_INDEX = None
        STATIC_LABELS = []
        STATIC_FILES = []
        print("[ml_infer] static index: 0 file (không tìm thấy ảnh trong static)", flush=True)
        return

    # đọc tất cả ảnh → embed 1 lượt
    batch = np.vstack([_prep_image(p) for p in paths])   # (M,224,224,3)
    STATIC_INDEX = _embed(batch)                         # (M,1280)

    STATIC_FILES = paths
    STATIC_LABELS = [
        os.path.splitext(os.path.basename(p))[0] for p in paths
    ]
    print(f"[ml_infer] built index: {len(STATIC_LABELS)} classes", flush=True)

# build ngay lúc import
build_static_index()

def reindex_static() -> Dict[str, object]:
    build_static_index()
    return {
        "count": len(STATIC_LABELS),
        "labels": STATIC_LABELS,
        "files": STATIC_FILES,
    }

def index_info() -> Dict[str, object]:
    return {
        "count": len(STATIC_LABELS),
        "labels": STATIC_LABELS,
    }

# =========================
#  CNN (TÙY CHỌN)
# =========================
CNN_MODEL = None
CNN_LABELS: List[str] = []

def _load_cnn_if_any():
    """có file .h5 và labels.json thì load; không có thì bỏ qua"""
    global CNN_MODEL, CNN_LABELS
    if CNN_MODEL is not None:
        return
    if not os.path.isfile(MODEL_PATH) or not os.path.isfile(LABELS_PATH):
        print("[ml_infer] no CNN model found -> chỉ dùng static", flush=True)
        CNN_MODEL = None
        CNN_LABELS = []
        return
    try:
        CNN_MODEL = tf.keras.models.load_model(MODEL_PATH)
        with open(LABELS_PATH, "r", encoding="utf-8") as f:
            import json
            CNN_LABELS = json.load(f)
        print(f"[ml_infer] loaded CNN model: {MODEL_PATH} ({len(CNN_LABELS)} classes)", flush=True)
    except Exception as e:
        print("[ml_infer] load CNN failed:", e, flush=True)
        CNN_MODEL = None
        CNN_LABELS = []

def _cnn_predict(pil_img: Image.Image, topk: int = 3) -> List[Dict[str, float]]:
    """trả list [{code, prob}] từ CNN; nếu không có CNN → []"""
    _load_cnn_if_any()
    if CNN_MODEL is None or not CNN_LABELS:
        return []
    arr = pil_img.resize((224, 224)).convert("RGB")
    x = np.array(arr, dtype=np.float32)
    x = np.expand_dims(x, 0) / 255.0
    preds = CNN_MODEL.predict(x, verbose=0)[0]    # (C,)
    # softmax nếu model chưa softmax
    if preds.ndim == 1:
        # chuẩn hoá
        ex = np.exp(preds - preds.max())
        probs = ex / (ex.sum() + 1e-12)
    else:
        probs = preds
    order = np.argsort(-probs)[:topk]
    out = []
    for i in order:
        if i < len(CNN_LABELS):
            out.append({"code": CNN_LABELS[i], "prob": float(probs[i])})
    return out

# =========================
#  HÀM CHÍNH GỌI TỪ /classify
# =========================
def classify_image(pil_img: Image.Image, topk: int = 3) -> List[Dict[str, float]]:
    """
    1. nếu có static index → so khớp static
    2. gọi thêm CNN (nếu có) → merge
    3. chuẩn hoá lại để tổng = 1
    """
    results: List[Dict[str, float]] = []

    # 1) STATIC
    if STATIC_INDEX is not None and len(STATIC_LABELS) > 0:
        q = _embed(_prep_image(pil_img))[0]             # (1280,)
        sims = (STATIC_INDEX @ q[:, None]).ravel()      # (M,)
        z = sims / STATIC_TEMP
        z -= z.max()
        p = np.exp(z); p /= (p.sum() + 1e-12)
        order = np.argsort(-p)[:topk]
        for i in order:
            results.append({
                "code": STATIC_LABELS[i],
                "prob": float(p[i])
            })

    # 2) CNN
    cnn_res = _cnn_predict(pil_img, topk=topk)
    # gộp 2 list theo code: nếu trùng code thì lấy max(prob)
    merged: Dict[str, float] = {}
    for r in results:
        merged[r["code"]] = max(merged.get(r["code"], 0.0), r["prob"])
    for r in cnn_res:
        merged[r["code"]] = max(merged.get(r["code"], 0.0), r["prob"])

    if not merged:
        return []

    # chuẩn hoá lại
    codes = list(merged.keys())
    probs = np.array([merged[c] for c in codes], dtype=np.float32)
    probs_sum = float(probs.sum()) or 1.0
    probs = probs / probs_sum

    # sort lại
    order = np.argsort(-probs)[:topk]
    final = []
    for idx in order:
        final.append({
            "code": codes[idx],
            "prob": float(probs[idx])
        })
    return final
