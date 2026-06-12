from PIL import Image

SRC = "/home/user/chemclass/apps/chemclass_flutter/assets/icon/icon_teacher.png"
OUT_DIR = "/home/user/chemclass/apps/chemclass_flutter/ios/Runner/Assets.xcassets/AppIcon.appiconset"

SIZES = {
    "Icon-App-20x20@1x.png": 20,
    "Icon-App-20x20@2x.png": 40,
    "Icon-App-20x20@3x.png": 60,
    "Icon-App-29x29@1x.png": 29,
    "Icon-App-29x29@2x.png": 58,
    "Icon-App-29x29@3x.png": 87,
    "Icon-App-40x40@1x.png": 40,
    "Icon-App-40x40@2x.png": 80,
    "Icon-App-40x40@3x.png": 120,
    "Icon-App-60x60@2x.png": 120,
    "Icon-App-60x60@3x.png": 180,
    "Icon-App-76x76@1x.png": 76,
    "Icon-App-76x76@2x.png": 152,
    "Icon-App-83.5x83.5@2x.png": 167,
    "Icon-App-1024x1024@1x.png": 1024,
}

src = Image.open(SRC).convert("RGB")

for filename, size in SIZES.items():
    resized = src.resize((size, size), Image.LANCZOS)
    resized.save(f"{OUT_DIR}/{filename}")
    print(f"{filename} -> {size}x{size}")

print("done")
