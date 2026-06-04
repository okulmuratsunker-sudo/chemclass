#!/bin/bash
# ChemClass iOS Setup Script
# Bu scripti Mac'te chemclass-ios klasöründe çalıştır

set -e

echo "=================================="
echo "  ChemClass iOS Kurulum Scripti"
echo "=================================="
echo ""

# 1. www klasörü oluştur ve index.html kopyala
echo "▶ Web dosyaları hazırlanıyor..."
mkdir -p www
if [ -f "../ogretmen-dosyasi.html" ]; then
  cp ../ogretmen-dosyasi.html www/index.html
  echo "  ✓ ogretmen-dosyasi.html → www/index.html"
elif [ -f "../../ogretmen-dosyasi.html" ]; then
  cp ../../ogretmen-dosyasi.html www/index.html
  echo "  ✓ ogretmen-dosyasi.html → www/index.html"
else
  echo "  ⚠ ogretmen-dosyasi.html bulunamadı. Lütfen manuel olarak www/index.html olarak kopyalayın."
fi

# 2. npm bağımlılıklarını yükle
echo ""
echo "▶ npm paketleri yükleniyor..."
npm install

# 3. iOS platformu ekle
echo ""
echo "▶ iOS platformu ekleniyor..."
npx cap add ios

# 4. Capacitor sync
echo ""
echo "▶ Capacitor sync yapılıyor..."
npx cap sync ios

# 5. İkonları kopyala
echo ""
echo "▶ Uygulama ikonları kopyalanıyor..."
ICON_DIR="ios/App/App/Assets.xcassets/AppIcon.appiconset"
if [ -d "$ICON_DIR" ]; then
  cp ../ios-icons/*.png "$ICON_DIR/" 2>/dev/null && echo "  ✓ İkonlar kopyalandı" || echo "  ⚠ İkonlar ../ios-icons klasöründe bulunamadı"
else
  echo "  ⚠ AppIcon klasörü bulunamadı. Xcode'u açtıktan sonra ikonları manuel ekleyin."
fi

# 6. PrivacyInfo.xcprivacy kopyala
echo ""
echo "▶ Privacy manifest kopyalanıyor..."
PRIVACY_DIR="ios/App/App"
if [ -d "$PRIVACY_DIR" ]; then
  cp ../PrivacyInfo.xcprivacy "$PRIVACY_DIR/" 2>/dev/null && echo "  ✓ PrivacyInfo.xcprivacy kopyalandı" || echo "  ⚠ PrivacyInfo.xcprivacy bulunamadı"
fi

echo ""
echo "=================================="
echo "  Kurulum tamamlandı!"
echo "=================================="
echo ""
echo "Sıradaki adım: Xcode'u açmak için:"
echo "  npx cap open ios"
echo ""
echo "Xcode'da yapılacaklar:"
echo "  1. Signing & Capabilities → Team seç (Apple Developer hesabın)"
echo "  2. Bundle Identifier: com.muratsunker.chemclass"
echo "  3. Version: 1.0, Build: 1"
echo "  4. Product → Archive → Distribute App → App Store Connect"
echo ""
