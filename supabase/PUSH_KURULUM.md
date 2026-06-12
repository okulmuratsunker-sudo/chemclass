# ChemClass — Push Bildirimleri (FCM) Kurulum Rehberi

Bu rehber, uygulama kapalıyken/arka plandayken de "canlı" bildirim
gönderebilmek (gerçek push) için gereken **tek seferlik** kurulumu anlatır.
Aşağıdaki adımlar sadece Firebase/Apple/Supabase hesabına sahip olan kişi
(sen) tarafından yapılabilir — kod tarafı (Flutter + Edge Function) zaten
hazır ve hiçbiri yapılmadan da uygulamalar normal çalışır (sadece push
bildirimleri devre dışı kalır).

## Şu an ne çalışıyor, ne bekliyor?

- ✅ **"Canlı" katman (Realtime broadcast):** Öğretmen mesaj/ödev gönderdiğinde,
  uygulama açıkken öğrenci tarafında anında yenileniyor — ekstra kurulum
  gerekmez, zaten aktif.
- ⏳ **Gerçek push bildirimi (FCM):** Uygulama kapalı/arka plandayken de
  telefona bildirim düşmesi için bu rehberdeki adımların tamamlanması
  gerekiyor.

---

## Gereksinimler

- [ ] Google hesabı (Firebase Console için — ücretsiz)
- [ ] Apple Developer hesabı (iOS push için — APNs anahtarı)
- [ ] Supabase CLI (`npm install -g supabase` veya `brew install supabase/tap/supabase`)
- [ ] Supabase proje erişimi: `krqyzhmioqtfihwrblmb`

---

## ADIM 1 — Firebase Projesi Oluştur

1. https://console.firebase.google.com adresine gir
2. **"Add project" / "Proje ekle"** → isim: `ChemClass` (istediğin isim)
3. Google Analytics'i istersen kapat → **Create project**

---

## ADIM 2 — Android Uygulamalarını Ekle (her iki uygulama için)

Firebase projesinde **2 ayrı Android uygulaması** ekleyeceksin (Öğretmen ve Öğrenci):

### 2a. ChemClass (Öğretmen)
1. Proje ana sayfasında **Android ikonuna** tıkla ("Add app")
2. **Android package name:** `com.muratsunker.chemclass.chemclass_teacher`
3. **App nickname:** ChemClass Öğretmen
4. **Register app** → **`google-services.json` dosyasını indir**
5. Bu dosyayı şuraya koy:
   `flutter/chemclass_teacher/android/app/google-services.json`
6. "Next" → "Next" → **Continue to console** (Gradle adımlarını ADIM 4'te yapacağız)

### 2b. ChemClass Öğrenci
1. Aynı projede tekrar **"Add app" → Android**
2. **Android package name:** `com.muratsunker.chemclass.chemclass_student`
3. **App nickname:** ChemClass Öğrenci
4. **Register app** → **`google-services.json` dosyasını indir**
5. Bu dosyayı şuraya koy:
   `flutter/chemclass_student/android/app/google-services.json`
6. "Continue to console"

---

## ADIM 3 — iOS Uygulamalarını Ekle (her iki uygulama için)

### 3a. ChemClass (Öğretmen)
1. **"Add app" → iOS**
2. **iOS bundle ID:** `com.muratsunker.chemclass.chemclassTeacher`
3. **App nickname:** ChemClass Öğretmen
4. **Register app** → **`GoogleService-Info.plist` dosyasını indir**
5. Bu dosyayı Xcode ile ekle (önemli — Finder'dan sürükleyip kopyalamak yetmez):
   - `flutter/chemclass_teacher/ios` klasöründe `open Runner.xcworkspace`
   - Sol panelde `Runner` klasörüne sağ tık → **Add Files to "Runner"...**
   - İndirdiğin `GoogleService-Info.plist`'i seç, **"Copy items if needed"** işaretli olsun
6. "Continue to console" (APNs anahtarını ADIM 3c'de ekleyeceğiz)

### 3b. ChemClass Öğrenci
1. Aynı projede tekrar **"Add app" → iOS**
2. **iOS bundle ID:** `com.muratsunker.chemclass.chemclassStudent`
3. **App nickname:** ChemClass Öğrenci
4. **Register app** → **`GoogleService-Info.plist` dosyasını indir**
5. Aynı şekilde Xcode ile `flutter/chemclass_student/ios/Runner.xcworkspace` içine ekle
6. "Continue to console"

### 3c. APNs Anahtarı (iOS push için zorunlu)
1. https://developer.apple.com/account → **Certificates, Identifiers & Profiles → Keys**
2. **"+"** → isim ver (örn. `ChemClass Push`) → **Apple Push Notifications service (APNs)** işaretle → **Continue → Register**
3. `.p8` dosyasını indir (⚠️ sadece bir kez indirilebilir, sakla), **Key ID**'yi not al
4. Firebase Console → **Project settings → Cloud Messaging** sekmesi
5. Her iki iOS uygulaması için **"Apple app configuration" → APNs Authentication Key → Upload**
   - `.p8` dosyasını yükle, **Key ID** ve **Team ID** (Apple Developer hesabının üst kısmında) gir

---

## ADIM 4 — Android Gradle Ayarları (her iki uygulama için)

Her iki uygulamada da (`flutter/chemclass_teacher` ve `flutter/chemclass_student`)
aynı 2 değişikliği yap:

**`android/settings.gradle`** — `plugins { ... }` bloğunun içine ekle:

```gradle
plugins {
    id "dev.flutter.flutter-plugin-loader" version "1.0.0"
    id "com.android.application" version "8.1.0" apply false
    id "org.jetbrains.kotlin.android" version "1.8.22" apply false
    id "com.google.gms.google-services" version "4.4.2" apply false   // ← ekle
}
```

**`android/app/build.gradle`** — `plugins { ... }` bloğunun içine ekle:

```gradle
plugins {
    id "com.android.application"
    id "kotlin-android"
    id "dev.flutter.flutter-gradle-plugin"
    id "com.google.gms.google-services"   // ← ekle
}
```

> ⚠️ Bu eklemeleri **`google-services.json` dosyası `android/app/` içine
> konduktan sonra** yap — dosya yoksa Gradle build hata verir.

---

## ADIM 5 — Xcode'da Push Notification Capability (her iki uygulama için)

1. `ios` klasöründe `Runner.xcworkspace`'i aç
2. Sol panelde `Runner` projesine tıkla → **Signing & Capabilities**
3. **"+ Capability"** → **Push Notifications** ekle
4. **"+ Capability"** → **Background Modes** ekle → **"Remote notifications"** işaretle
   (Info.plist'te `UIBackgroundModes` zaten kod tarafında eklendi, Xcode bu adımda
   karşılık gelen entitlement'ı oluşturur)

---

## ADIM 6 — Firebase Servis Hesabı JSON'u Oluştur (FCM v1 için)

Edge Function, push göndermek için bir **servis hesabı anahtarına** ihtiyaç duyar:

1. Firebase Console → **Project settings (⚙️) → Service accounts**
2. **"Generate new private key"** → onayla → bir `.json` dosyası iner
3. Bu dosyanın **tüm içeriğini** kopyala (ADIM 8'de Supabase secret olarak kullanılacak)

---

## ADIM 7 — Supabase: Veritabanı Kurulumu

Supabase Dashboard → **SQL Editor** → proje `krqyzhmioqtfihwrblmb`:

1. Eğer daha önce çalıştırmadıysan önce `supabase/student_app_setup.sql` dosyasını çalıştır
2. Ardından **`supabase/push_notifications_setup.sql`** dosyasının tamamını yapıştır ve **Run**

Bu dosya şunları oluşturur:
- `chemclass_push_tokens` tablosu (her cihaz için bir FCM token)
- `register_teacher_push_token`, `register_student_push_token`, `unregister_push_token`
  fonksiyonları (uygulamalar giriş yapınca/çıkınca otomatik çağırır — kod tarafı hazır)

---

## ADIM 8 — Edge Function'ı Deploy Et ve Secret Ayarla

Terminalde proje köküne git (`chemclass/`):

```bash
supabase login
supabase link --project-ref krqyzhmioqtfihwrblmb

# ADIM 6'da indirdiğin JSON dosyasının TAM içeriğini secret olarak kaydet
supabase secrets set FCM_SERVICE_ACCOUNT_JSON="$(cat /path/to/service-account.json)" --project-ref krqyzhmioqtfihwrblmb

# Edge Function'ı deploy et
supabase functions deploy send-push --project-ref krqyzhmioqtfihwrblmb
```

Deploy başarılı olursa fonksiyonun URL'i şu şekilde olacak:
`https://krqyzhmioqtfihwrblmb.supabase.co/functions/v1/send-push`

---

## ADIM 9 — Database Webhooks Oluştur

Supabase Dashboard → **Database → Webhooks → Create a new hook**

### Webhook 1 — Mesajlar
- **Name:** `chemclass-messages-push`
- **Table:** `chemclass_messages`
- **Events:** ☑ Insert
- **Type:** Supabase Edge Functions
- **Edge Function:** `send-push`

### Webhook 2 — Ödev/Duyuru/Görevler
- **Name:** `chemclass-assignments-push`
- **Table:** `chemclass_assignments`
- **Events:** ☑ Insert
- **Type:** Supabase Edge Functions
- **Edge Function:** `send-push`

(Dashboard "Supabase Edge Functions" tipini seçtiğinde URL ve yetkilendirme
header'ı otomatik doldurulur.)

---

## ADIM 10 — Test Et

1. Uygulamaları (Öğretmen + Öğrenci) gerçek cihaza yükle, **giriş yap**
   (bu, cihazın FCM token'ını otomatik olarak Supabase'e kaydeder)
2. Öğrenci uygulamasını **kapat / arka plana al**
3. Öğretmen uygulamasından o öğrenciye/sınıfa mesaj veya ödev gönder
4. Öğrenci telefonunda sistem bildirimi düşmeli 🎉

### Sorun giderme
- `supabase functions logs send-push --project-ref krqyzhmioqtfihwrblmb` ile
  Edge Function loglarına bak
- "no devices to notify" → giriş yapılmamış ya da token kaydı henüz oluşmamış
  olabilir (uygulamayı kapatıp tekrar aç)
- iOS'ta hiç bildirim gelmiyorsa → ADIM 3c (APNs anahtarı) ve ADIM 5
  (capability) tekrar kontrol edilmeli

---

## Destek

Sorun yaşarsan: muratsunker@gmail.com
