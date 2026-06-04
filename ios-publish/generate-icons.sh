#!/bin/bash
# ChemClass iOS İkon Oluşturma Scripti
# Gerekli: Homebrew + ImageMagick veya librsvg
# Kurulum: brew install librsvg  (önerilir - SVG'yi doğrudan PNG'ye çevirir)
#
# Kullanım: ./generate-icons.sh chemclass-icon.svg

set -e

SVG="${1:-chemclass-icon.svg}"
OUT="ios-icons"

if [ ! -f "$SVG" ]; then
  echo "Hata: $SVG dosyası bulunamadı"
  echo "Kullanım: ./generate-icons.sh <dosya.svg>"
  exit 1
fi

mkdir -p "$OUT"

# rsvg-convert varsa kullan (en kaliteli)
if command -v rsvg-convert &>/dev/null; then
  CONVERT="rsvg_convert"
# ImageMagick varsa kullan
elif command -v convert &>/dev/null; then
  CONVERT="imagemagick"
else
  echo "Hata: rsvg-convert veya ImageMagick bulunamadı"
  echo "Kurulum: brew install librsvg"
  exit 1
fi

resize() {
  local size=$1
  local name=$2
  if [ "$CONVERT" = "rsvg_convert" ]; then
    rsvg-convert -w "$size" -h "$size" "$SVG" -o "$OUT/$name"
  else
    convert -background none -resize "${size}x${size}" "$SVG" "$OUT/$name"
  fi
  echo "  ✓ $name (${size}×${size})"
}

echo "İkonlar oluşturuluyor..."
echo ""

# iPhone ikonları
resize 20  "Icon-20.png"
resize 40  "Icon-20@2x.png"
resize 60  "Icon-20@3x.png"
resize 29  "Icon-29.png"
resize 58  "Icon-29@2x.png"
resize 87  "Icon-29@3x.png"
resize 40  "Icon-40.png"
resize 80  "Icon-40@2x.png"
resize 120 "Icon-40@3x.png"
resize 120 "Icon-60@2x.png"
resize 180 "Icon-60@3x.png"

# iPad ikonları
resize 20  "Icon-iPad-20.png"
resize 40  "Icon-iPad-20@2x.png"
resize 29  "Icon-iPad-29.png"
resize 58  "Icon-iPad-29@2x.png"
resize 40  "Icon-iPad-40.png"
resize 80  "Icon-iPad-40@2x.png"
resize 76  "Icon-iPad-76.png"
resize 152 "Icon-iPad-76@2x.png"
resize 167 "Icon-iPad-83.5@2x.png"

# App Store (gerekli)
resize 1024 "Icon-1024.png"

# Spotlight & Settings
resize 80  "Icon-Spotlight-40@2x.png"
resize 120 "Icon-Spotlight-40@3x.png"

echo ""
echo "✅ Tüm ikonlar '$OUT' klasörüne kaydedildi"
echo ""
echo "Toplam dosya sayısı: $(ls $OUT/*.png | wc -l | tr -d ' ')"
