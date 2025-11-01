# backend/ml/infer.py
import json
from pathlib import Path
from typing import List, Dict
import numpy as np
from PIL import Image
import tensorflow as tf
from tensorflow.keras.applications import mobilenet_v2

BASE_DIR = Path("backend/ml")
MODEL_PATH = BASE_DIR / "model.h5"
LABELS_PATH = BASE_DIR / "labels.json"
IMG_SIZE = (224, 224)

_model = None
_idx_to_code = None

def _load():
    global _model, _idx_to_code
    if _model is None:
        if not MODEL_PATH.exists() or not LABELS_PATH.exists():
            raise RuntimeError("Model/labels not found.")
        _model = tf.keras.models.load_model(MODEL_PATH)
        with open(LABELS_PATH, "r", encoding="utf-8") as f:
            _idx_to_code = {int(k): v for k, v in json.load(f).items()}

def available() -> bool:
    return MODEL_PATH.exists() and LABELS_PATH.exists()

def classify_pil(img: Image.Image, topk: int = 3) -> List[Dict]:
    _load()
    img = img.convert("RGB").resize(IMG_SIZE)
    x = np.array(img, dtype=np.float32)
    x = mobilenet_v2.preprocess_input(x)
    x = np.expand_dims(x, 0)  # (1,H,W,3)

    probs = _model.predict(x, verbose=0)[0]  # (C,)
    top_idx = probs.argsort()[::-1][:topk]
    out = []
    for i in top_idx:
        code = _idx_to_code.get(int(i), f"class_{i}")
        out.append({"code": code, "prob": float(probs[i])})
    return out
