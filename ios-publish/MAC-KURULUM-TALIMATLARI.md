# ChemClass – Mac'te iOS Kurulum Talimatları

## Gereksinimler (Önceden Kurulu Olması Gerekenler)

- [ ] Xcode (App Store'dan ücretsiz indir — en son sürüm)
- [ ] Node.js (nodejs.org'dan indir — LTS sürümü)
- [ ] Homebrew (brew.sh — terminal: `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`)

---

## ADIM 1 — Dosyaları Mac'e Kopyala

Bu ZIP dosyasını Mac'e indir ve aç. Sonra içindeki `chemclass-ios` klasörünü masaüstüne koy.

---

## ADIM 2 — İkon Oluştur

Terminal'i aç ve şunları çalıştır:

```bash
# librsvg kur (bir kez yeterli)
brew install librsvg

# chemclass-ios klasörüne git
cd ~/Desktop/chemclass-ios

# İkonları oluştur
chmod +x generate-icons.sh
./generate-icons.sh chemclass-icon.svg
```

`ios-icons/` klasörünün içinde ~22 PNG dosyası oluşacak.

---

## ADIM 3 — iOS Projesini Kur

```bash
# capacitor-project klasörüne gir
cd ~/Desktop/chemclass-ios/capacitor-project

# ogretmen-dosyasi.html'i web klasörüne kopyala
mkdir -p www
cp ../ogretmen-dosyasi.html www/index.html

# kurulum scriptini çalıştır
chmod +x setup-ios.sh
./setup-ios.sh
```

Bu script otomatik olarak:
- npm paketlerini yükler
- iOS platformunu ekler
- Capacitor sync yapar
- İkonları ve PrivacyInfo'yu kopyalar

---

## ADIM 4 — Xcode'u Aç

```bash
npx cap open ios
```

Xcode otomatik açılacak.

---

## ADIM 5 — Xcode'da Ayarlar

Xcode açıldığında:

### 5a. Signing & Capabilities
1. Sol panelde `App` projesine tıkla
2. `Signing & Capabilities` sekmesini aç
3. **Team:** Apple Developer hesabını seç (açılır menüden)
4. **Bundle Identifier:** `com.muratsunker.chemclass` yazılı olduğunu kontrol et
5. "Automatically manage signing" işaretli olsun

### 5b. General
1. `General` sekmesini aç
2. **Version:** `1.0`
3. **Build:** `1`
4. **Deployment Target:** iOS 15.0 veya üzeri

### 5c. İkonları Kontrol Et
1. Sol panelde `Assets.xcassets` → `AppIcon`'a tıkla
2. Tüm kutucukların dolu olduğunu kontrol et
3. Eğer boşsa: Finder'dan `ios-icons/` klasörünü aç, dosyaları sürükle bırak

---

## ADIM 6 — Gerçek Cihazda Test (Opsiyonel ama Önerilir)

iPhone'u Mac'e bağla:
1. Xcode'da üstteki cihaz seçicisinden iPhone'unu seç
2. ▶ (Run) butonuna bas
3. iPhone'da "Güven" seç (ilk kez bağlanıyorsa)
4. Uygulamanın açıldığını ve çalıştığını doğrula

---

## ADIM 7 — Archive (Arşiv Oluştur)

1. Xcode'da üstten `Product` → `Archive` seç
2. İşlem 2-5 dakika sürer
3. Bitince **Organizer** penceresi açılır

---

## ADIM 8 — App Store'a Yükle

Organizer penceresinde:
1. Yeni oluşan arşivi seç
2. **"Distribute App"** butonuna tıkla
3. **"App Store Connect"** seç → Next
4. **"Upload"** seç → Next
5. Varsayılan seçenekleri bırak → Next → Upload
6. Yükleme 5-10 dakika sürer

---

## ADIM 9 — App Store Connect'te Uygulama Oluştur

Tarayıcıda **appstoreconnect.apple.com** adresine git:

1. **"My Apps"** → **"+"** → **"New App"**
2. Bilgileri doldur:
   - **Name:** ChemClass
   - **Primary Language:** Turkish
   - **Bundle ID:** `com.muratsunker.chemclass` (açılır listeden seç)
   - **SKU:** chemclass001
3. **Create** butonuna bas

### Metadata Ekle
`appstore-metadata.md` dosyasındaki Türkçe ve İngilizce metinleri kopyala yapıştır:
- App Description
- Keywords
- Support URL: `https://muratsunker.github.io/chemclass/privacy-policy.html`
- Privacy Policy URL: aynı

### Ekran Görüntüleri
- Simulator'da veya gerçek cihazda ekran görüntüsü al (Cmd+S)
- En az 3 ekran görüntüsü ekle

### Privacy Labels
`appstore-metadata.md` dosyasındaki talimatlara göre doldur.
Kısaca: **hiçbir veri toplamıyoruz** → hepsini "Not Collected" işaretle.

---

## ADIM 10 — Build Seç ve Review'a Gönder

1. App Store Connect'te **"+ Version or Platform"** ile iOS versiyonu ekle
2. **Build** bölümünden yüklediğin build'i seç (birkaç dakika bekle, işlenirken gözükmeyebilir)
3. Tüm alanları doldurduktan sonra **"Submit for Review"** butonuna bas

**İnceleme süresi:** Genellikle 24-48 saat, bazen 1 hafta.

---

## Sıkça Karşılaşılan Sorunlar

### "No accounts with iTunes Connect access"
→ Xcode Preferences → Accounts → Apple ID ekle

### "Provisioning profile doesn't include entitlement"
→ Xcode → Signing & Capabilities → Tüm entitlements'ı sil, temizle

### Build işlenmedi (App Store Connect'te görünmüyor)
→ 15-30 dakika bekle, email gelecek

### "Missing compliance" uyarısı
→ Export Compliance: No (şifreleme kullanmıyoruz, sadece HTTPS)

---

## Gizlilik Politikasını Yayınla (GitHub Pages)

```bash
# GitHub'da chemclass reposuna gir
# Settings → Pages → Source: main branch, /docs klasörü

# privacy-policy.html dosyasını docs/ klasörüne kopyala
# Adres: https://muratsunker.github.io/chemclass/privacy-policy.html
```

Alternatif: Netlify'a sürükle bırak ile 30 saniyede yayınla (netlify.com → "Add new site" → Drop folder)

---

## Destek

Sorun yaşarsan: muratsunker@gmail.com
