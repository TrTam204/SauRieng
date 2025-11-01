# backend/db/queries.py
import pyodbc
import hashlib
import json
from typing import List, Dict, Any, Optional, Tuple

# ====== KẾT NỐI SQL SERVER (LocalDB) ======
CONN_STR = (
    "DRIVER={ODBC Driver 17 for SQL Server};"
    "SERVER=(localdb)\\MSSQLLocalDB;"
    "DATABASE=SauRiengDb;"
    "Trusted_Connection=yes;"
)


def get_conn():
    return pyodbc.connect(CONN_STR)


def rows_to_dicts(cursor, rows):
    cols = [c[0] for c in cursor.description]
    return [dict(zip(cols, r)) for r in rows]


def _maybe_json(value: Any):
    if value is None:
        return None
    if isinstance(value, (dict, list)):
        return value
    try:
        return json.loads(value)
    except Exception:
        return None


# ===================== PESTS =====================

def get_pests(search: Optional[str] = None) -> List[Dict[str, Any]]:
    cn = get_conn()
    cur = cn.cursor()
    if search:
        cur.execute(
            """
            SELECT Id, Code, TenThuong, TenKhoaHoc, MoTaNgan, NhanBiet, BienPhapIPM, TacHai
            FROM dbo.Pests
            WHERE TenThuong LIKE ? OR TenKhoaHoc LIKE ? OR Code LIKE ?
            ORDER BY TenThuong
            """,
            f"%{search}%", f"%{search}%", f"%{search}%"
        )
    else:
        cur.execute(
            """
            SELECT Id, Code, TenThuong, TenKhoaHoc, MoTaNgan, NhanBiet, BienPhapIPM, TacHai
            FROM dbo.Pests
            ORDER BY TenThuong
            """
        )

    pests = rows_to_dicts(cur, cur.fetchall())

    # lấy 1 ảnh nếu bảng ảnh đúng, nếu không thì bỏ qua
    for p in pests:
        try:
            cur.execute(
                "SELECT TOP 1 Url FROM dbo.PestPhotos WHERE PestId = ? ORDER BY Id ASC",
                p["Id"]
            )
            r = cur.fetchone()
            p["Photos"] = [r[0]] if r else []
        except Exception:
            # bảng ảnh chưa đúng cấu trúc -> cứ để rỗng
            p["Photos"] = []

        p["NhanBietDecoded"] = _maybe_json(p.get("NhanBiet"))
        p["BienPhapIPMDecoded"] = _maybe_json(p.get("BienPhapIPM"))

    cn.close()
    return pests


def get_pest_detail(code: str) -> Optional[Dict[str, Any]]:
    cn = get_conn()
    cur = cn.cursor()

    cur.execute("SELECT TOP 1 * FROM dbo.Pests WHERE Code = ?", code)
    row = cur.fetchone()
    if not row:
        cn.close()
        return None

    cols = [c[0] for c in cur.description]
    pest = dict(zip(cols, row))

    # ảnh
    try:
        cur.execute(
            """
            SELECT Url
            FROM dbo.PestPhotos
            WHERE PestId = ?
            ORDER BY Id ASC
            """,
            pest["Id"]
        )
        pest["Photos"] = [r[0] for r in cur.fetchall()]
    except Exception:
        pest["Photos"] = []

    pest["NhanBietDecoded"] = _maybe_json(pest.get("NhanBiet"))
    pest["BienPhapIPMDecoded"] = _maybe_json(pest.get("BienPhapIPM"))

    cn.close()
    return pest


def create_pest(data: Dict[str, Any]) -> Tuple[bool, Optional[int], Optional[str]]:
    cn = get_conn()
    cur = cn.cursor()
    try:
        cur.execute(
            """
            INSERT INTO dbo.Pests (Code, TenThuong, TenKhoaHoc, MoTaNgan, NhanBiet, BienPhapIPM, TacHai)
            OUTPUT INSERTED.Id
            VALUES (?, ?, ?, ?, ?, ?, ?)
            """,
            data.get("Code"),
            data.get("TenThuong"),
            data.get("TenKhoaHoc"),
            data.get("MoTaNgan"),
            data.get("NhanBiet"),
            data.get("BienPhapIPM"),
            data.get("TacHai"),
        )
        new_id = int(cur.fetchone()[0])
        cn.commit()
        return True, new_id, None
    except Exception as e:
        cn.rollback()
        return False, None, str(e)
    finally:
        cn.close()


def add_pest_photo(code: str, url: str) -> bool:
    cn = get_conn()
    cur = cn.cursor()
    try:
        cur.execute("SELECT Id FROM dbo.Pests WHERE Code = ?", code)
        r = cur.fetchone()
        if not r:
            cn.close()
            return False
        pest_id = int(r[0])

        # nếu bảng đúng cột
        cur.execute("INSERT INTO dbo.PestPhotos (PestId, Url) VALUES(?, ?)", pest_id, url)
        cn.commit()
        return True
    except Exception:
        cn.rollback()
        return False
    finally:
        cn.close()


# ===================== DRUGS =====================

def get_drugs() -> List[Dict[str, Any]]:
    cn = get_conn()
    cur = cn.cursor()
    try:
        cur.execute("SELECT * FROM dbo.Drugs ORDER BY Ten")
        rows = rows_to_dicts(cur, cur.fetchall())
    except Exception:
        rows = []
    cn.close()
    return rows


def get_drugs_for_pest(code: str) -> List[Dict[str, Any]]:
    """
    Trường hợp bảng hoặc cột không đúng -> trả [] để API không 500.
    """
    cn = get_conn()
    cur = cn.cursor()
    try:
        cur.execute(
            """
            SELECT d.*
            FROM dbo.Drugs d
            JOIN dbo.PestDrugs pd ON pd.DrugId = d.Id
            JOIN dbo.Pests p ON p.Id = pd.PestId
            WHERE p.Code = ?
            ORDER BY d.Ten
            """,
            code
        )
        rows = rows_to_dicts(cur, cur.fetchall())
    except Exception:
        rows = []
    cn.close()
    return rows


def create_drug(data: Dict[str, Any]) -> Tuple[bool, Optional[int], Optional[str]]:
    cn = get_conn()
    cur = cn.cursor()
    try:
        cur.execute(
            """
            INSERT INTO dbo.Drugs (Ten, HoatChat, Nhom, Hang, HuongDan, GhiChu)
            OUTPUT INSERTED.Id
            VALUES (?, ?, ?, ?, ?, ?)
            """,
            data.get("Ten"),
            data.get("HoatChat"),
            data.get("Nhom"),
            data.get("Hang"),
            data.get("HuongDan"),
            data.get("GhiChu"),
        )
        new_id = int(cur.fetchone()[0])
        cn.commit()
        return True, new_id, None
    except Exception as e:
        cn.rollback()
        return False, None, str(e)
    finally:
        cn.close()


def link_drug_to_pest(code: str, drug_id: int) -> bool:
    cn = get_conn()
    cur = cn.cursor()
    try:
        cur.execute("SELECT Id FROM dbo.Pests WHERE Code = ?", code)
        r = cur.fetchone()
        if not r:
            cn.close()
            return False
        pest_id = int(r[0])

        # nếu bảng mapping chưa đúng sẽ rơi vào except → False
        cur.execute(
            """
            MERGE dbo.PestDrugs AS t
            USING (SELECT ? AS PestId, ? AS DrugId) AS s
            ON (t.PestId = s.PestId AND t.DrugId = s.DrugId)
            WHEN NOT MATCHED THEN
            INSERT (PestId, DrugId) VALUES (s.PestId, s.DrugId);
            """,
            pest_id,
            int(drug_id),
        )
        cn.commit()
        return True
    except Exception:
        cn.rollback()
        return False
    finally:
        cn.close()


# ===================== AUTH =====================

def sha256_hex(s: str) -> str:
    return hashlib.sha256(s.encode("utf-8")).hexdigest()


def create_user(username: str, password: str) -> bool:
    cn = get_conn()
    cur = cn.cursor()
    try:
        cur.execute(
            "INSERT INTO dbo.Users (Username, PasswordHash) VALUES (?, ?)",
            username,
            sha256_hex(password),
        )
        cn.commit()
        return True
    except Exception:
        cn.rollback()
        return False
    finally:
        cn.close()


def check_login(username: str, password: str) -> bool:
    cn = get_conn()
    cur = cn.cursor()
    cur.execute("SELECT PasswordHash FROM dbo.Users WHERE Username = ?", username)
    row = cur.fetchone()
    cn.close()
    return bool(row and row[0] == sha256_hex(password))


def get_user(username: str) -> Optional[Dict[str, Any]]:
    cn = get_conn()
    cur = cn.cursor()
    cur.execute("SELECT TOP 1 * FROM dbo.Users WHERE Username = ?", username)
    row = cur.fetchone()
    if not row:
        cn.close()
        return None
    cols = [c[0] for c in cur.description]
    u = dict(zip(cols, row))
    cn.close()
    return u


def is_admin(username: str) -> bool:
    u = get_user(username)
    return bool(u and u.get("IsAdmin"))
