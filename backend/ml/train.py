# backend/ml/train.py
import json, os
from pathlib import Path
import tensorflow as tf
from tensorflow.keras import layers, models
from tensorflow.keras.applications import mobilenet_v2
from tensorflow.keras.preprocessing.image import ImageDataGenerator

# ==== cấu hình cơ bản ====
IMG_SIZE = (224, 224)
BATCH_SIZE = 16
EPOCHS = 10
DATA_DIR = Path("data")                  # chứa train/ và val/
OUT_DIR = Path("backend/ml")             # lưu model.h5 + labels.json

OUT_DIR.mkdir(parents=True, exist_ok=True)

def build_model(num_classes: int):
    base = mobilenet_v2.MobileNetV2(include_top=False, input_shape=(IMG_SIZE[0], IMG_SIZE[1], 3), weights="imagenet")
    base.trainable = False  # fine-tune sau nếu cần

    inputs = layers.Input(shape=(IMG_SIZE[0], IMG_SIZE[1], 3))
    x = mobilenet_v2.preprocess_input(inputs)
    x = base(x, training=False)
    x = layers.GlobalAveragePooling2D()(x)
    x = layers.Dropout(0.2)(x)
    outputs = layers.Dense(num_classes, activation="softmax")(x)
    model = models.Model(inputs, outputs)
    model.compile(optimizer="adam", loss="categorical_crossentropy", metrics=["accuracy"])
    return model

def main():
    train_dir = DATA_DIR / "train"
    val_dir = DATA_DIR / "val"
    if not train_dir.exists() or not val_dir.exists():
        raise SystemExit("❌ Không tìm thấy data/train và data/val")

    # gen dữ liệu + augment cơ bản
    train_gen = ImageDataGenerator(
        rotation_range=12, width_shift_range=0.05, height_shift_range=0.05,
        zoom_range=0.1, horizontal_flip=True
    )
    val_gen = ImageDataGenerator()

    train_flow = train_gen.flow_from_directory(
        str(train_dir), target_size=IMG_SIZE, batch_size=BATCH_SIZE,
        class_mode="categorical", shuffle=True
    )
    val_flow = val_gen.flow_from_directory(
        str(val_dir), target_size=IMG_SIZE, batch_size=BATCH_SIZE,
        class_mode="categorical", shuffle=False
    )

    num_classes = train_flow.num_classes
    class_indices = train_flow.class_indices  # {'helopeltis':0, 'thrips':1,...}
    # đảo mapping -> lưu ra labels.json: index -> code
    idx_to_code = {int(v): k for k, v in class_indices.items()}

    model = build_model(num_classes)
    model.summary()

    ckpt = tf.keras.callbacks.ModelCheckpoint(
        filepath=str(OUT_DIR / "model.h5"),
        monitor="val_accuracy", save_best_only=True, verbose=1
    )
    es = tf.keras.callbacks.EarlyStopping(monitor="val_accuracy", patience=3, restore_best_weights=True)

    model.fit(train_flow, validation_data=val_flow, epochs=EPOCHS, callbacks=[ckpt, es])

    # luôn lưu thêm 1 bản cuối
    model.save(OUT_DIR / "model.h5")
    with open(OUT_DIR / "labels.json", "w", encoding="utf-8") as f:
        json.dump(idx_to_code, f, ensure_ascii=False, indent=2)

    print("✅ Done. Saved:", OUT_DIR / "model.h5", "and", OUT_DIR / "labels.json")

if __name__ == "__main__":
    # GPU optional; nếu chỉ CPU thì Keras vẫn chạy được
    os.environ.setdefault("TF_CPP_MIN_LOG_LEVEL", "2")
    main()
