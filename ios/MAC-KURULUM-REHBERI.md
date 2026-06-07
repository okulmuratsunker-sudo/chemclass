# ChemClass iOS Uygulamaları – Mac'te Kurulum ve App Store Yükleme Rehberi

Bu klasörde **iki hazır Xcode projesi** var, ikisi de `OgretmenimApp` şablonundan
türetilmiş çalışır durumdaki WKWebView sarmalayıcılar (canlı web sitesini
uygulama içinde gösterirler):

| Klasör | Uygulama | Bundle ID | Adres |
|---|---|---|---|
| `ChemClassApp/` | ChemClass (Öğretmen) | `com.muratsunker.chemclass` | chemclass.muratsunker.workers.dev |
| `ChemClassOgrenciApp/` | ChemClass Öğrenci | `com.muratsunker.chemclassogrenci` | chemclass-student.muratsunker.workers.dev |

İkon, marka renkleri, çevrimdışı ekranı, "aşağı çekerek yenile" — hepsi hazır.
Aşağıdaki adımları **her iki proje için ayrı ayrı** uygulayacaksın.

## Gereksinimler

- [ ] Mac + Xcode (App Store'dan ücretsiz, en güncel sürüm)
- [ ] Apple Developer Program üyeliği (yıllık $99) — appstoreconnect.apple.com

---

## ADIM 1 — Projeyi Aç

İlgili klasördeki `.xcodeproj` dosyasına çift tıkla:
- `ChemClassApp/ChemClassApp.xcodeproj`
- `ChemClassOgrenciApp/ChemClassOgrenciApp.xcodeproj`

## ADIM 2 — İmzalama (Signing)

1. Sol panelde proje adına (mavi ikon) tıkla → **TARGETS** altında uygulamayı seç
2. **Signing & Capabilities** sekmesi
3. **"Automatically manage signing"** işaretli olsun
4. **Team:** açılır menüden Apple Developer hesabını seç
5. **Bundle Identifier**'ın yukarıdaki tabloyla eşleştiğini doğrula

## ADIM 3 — Genel Ayarlar

**General** sekmesinde:
- **Display Name:** ChemClass / ChemClass Öğrenci (zaten ayarlı)
- **Version:** 1.0
- **Build:** 1
- **Deployment Target:** iOS 15.0+ (önerilir)

## ADIM 4 — Simülatörde / Cihazda Test Et

- Üst çubuktan bir simülatör seç (örn. iPhone 16) → **▶ Run**
- Uygulama açılmalı, canlı siteyi yüklemeli, giriş/sekme geçişleri çalışmalı
- Gerçek cihazda test ediyorsan: iPhone'u bağla, cihazı seç, ▶ Run, telefonda
  "Bu Geliştiriciye Güven" onayını ver (Ayarlar → Genel → VPN ve Cihaz Yönetimi)

## ADIM 5 — Ekran Görüntüsü Al

Simülatörde uygulama açıkken **Cmd+S** ile ekran görüntüsü kaydedilir
(Masaüstüne kaydedilir). Her uygulama için en az 3 görüntü al:
- ChemClass: Özet/Not Defteri, Madde Analizi, Öğrenciler
- ChemClass Öğrenci: Giriş, Puanım/Sıralama, Ödevler veya Mesajlar

## ADIM 6 — Archive (Arşivle)

1. Üst çubuktan cihaz olarak **"Any iOS Device (arm64)"** seç (simülatör değil!)
2. **Product → Archive**
3. 2-5 dakika sürer, bitince **Organizer** penceresi açılır

## ADIM 7 — App Store Connect'e Yükle

Organizer'da:
1. Yeni arşivi seç → **"Distribute App"**
2. **"App Store Connect"** → Next → **"Upload"** → Next
3. Varsayılanları bırak → Next → **Upload**
4. 5-15 dakika sürer; işlendiğinde e-posta gelir

## ADIM 8 — App Store Connect'te Uygulamayı Oluştur

**appstoreconnect.apple.com** → **My Apps** → **+** → **New App**

| Alan | ChemClass | ChemClass Öğrenci |
|---|---|---|
| Name | ChemClass | ChemClass Öğrenci |
| Primary Language | Turkish | Turkish |
| Bundle ID | com.muratsunker.chemclass | com.muratsunker.chemclassogrenci |
| SKU | chemclass001 | chemclassogrenci001 |

> İki uygulama App Store Connect'te **ayrı kayıtlar** olarak oluşturulmalı.

### Metadata
İlgili dosyadaki Türkçe/İngilizce metinleri kopyala-yapıştır:
- ChemClass → `../ios-publish/appstore-metadata.md`
- ChemClass Öğrenci → `../ios-publish/appstore-metadata-ogrenci.md`

Her iki uygulama için **Support URL** ve **Privacy Policy URL**:
```
https://muratsunker.github.io/chemclass/privacy-policy.html
```
(Bu sayfa artık her iki uygulamayı da kapsayacak şekilde güncellendi —
bkz. `../ios-publish/privacy-policy.html`. GitHub Pages veya Netlify'a
yüklemen yeterli; "Gizlilik Politikasını Yayınla" bölümüne bak.)

### Privacy Labels (App Privacy)
- **ChemClass (Öğretmen):** `appstore-metadata.md` → "Privacy Nutrition Labels" — neredeyse her şey "Not Collected"
- **ChemClass Öğrenci:** `appstore-metadata-ogrenci.md` → "Privacy Nutrition Labels" — öğrenci adı/okul no/puan/mesajlar **"Linked to you – App Functionality"** olarak işaretlenmeli (öğretmen uygulamasından farklı!)

### Age Rating
İkisi için de: tüm kategoriler **"None"**, sonuç **4+**

---

## ADIM 9 — Build Seç ve Review'a Gönder

1. Sol menüden **"+ Version or Platform"** ile 1.0 sürümünü oluştur
2. **Build** alanından az önce yüklediğin build'i seç (işlenmesi 15-30 dk sürebilir, gözükmezse bekle)
3. Ekran görüntülerini ekle, tüm zorunlu alanları doldur
4. **"Submit for Review"**

İnceleme süresi genelde 24-48 saat (bazen 1 hafta).

---

## Sıkça Karşılaşılan Sorunlar

- **"No accounts with iTunes Connect access"** → Xcode → Settings → Accounts → Apple ID ekle
- **"Provisioning profile doesn't include entitlement"** → Signing & Capabilities'te ekstra capability eklenmiş mi kontrol et, gereksizleri sil
- **Build App Store Connect'te görünmüyor** → 15-30 dk bekle, e-posta gelecek
- **"Missing compliance" uyarısı** → Export Compliance: **No** (özel şifreleme yok, sadece standart HTTPS)
- **"Bağlantı Yok" ekranı çıkıyor** → Simülatörün/cihazın internet bağlantısını kontrol et; Cloudflare Worker adresine erişilebildiğinden emin ol

---

## Notlar

- `ios-publish/capacitor-project/` ve eski `MAC-KURULUM-TALIMATLARI.md` artık
  **gerekli değil** — bu rehberdeki native Xcode projeleri çok daha basit ve
  bakımı kolay bir yol sunuyor. Capacitor klasörünü silmek istersen önce
  içinde özel bir şey kalmadığından emin ol.
- Push bildirimleri (arka planda bildirim) bu sürümde **dahil değil**;
  uygulamalar açıkken/önplandayken bildirim gösterimi web tarafında zaten
  çalışıyor. Gerçek arka plan push istenirse ayrı bir aşama (APNs + sunucu
  altyapısı) gerekir.
