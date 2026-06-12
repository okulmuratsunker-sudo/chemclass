from PIL import Image

BASE = "/home/user/chemclass/apps/chemclass_flutter/android/app/src"

DENSITIES = {
    "mipmap-mdpi": 48,
    "mipmap-hdpi": 72,
    "mipmap-xhdpi": 96,
    "mipmap-xxhdpi": 144,
    "mipmap-xxxhdpi": 192,
}

TARGETS = {
    "/home/user/chemclass/apps/chemclass_flutter/assets/icon/icon_teacher.png": f"{BASE}/main/res",
    "/home/user/chemclass/apps/chemclass_flutter/assets/icon/icon_student.png": f"{BASE}/student/res",
}

for src_path, out_root in TARGETS.items():
    src = Image.open(src_path).convert("RGB")
    for folder, size in DENSITIES.items():
        out_path = f"{out_root}/{folder}/ic_launcher.png"
        resized = src.resize((size, size), Image.LANCZOS)
        resized.save(out_path)
        print(f"{out_path} -> {size}x{size}")

print("done")
