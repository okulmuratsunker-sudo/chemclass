# ChemClass Öğrenci – App Store Connect Metadata

## Uygulama Bilgileri

**App ID (Bundle ID):** `com.muratsunker.chemclassogrenci`
**Platform:** iOS (iPhone + iPad)
**Kategori:** Education (Ana Kategori)
**Alt Kategori:** Productivity
**Fiyat:** Free (Ücretsiz)
**Version:** 1.0
**Copyright:** © 2025 Murat Sünker

---

## Türkçe Metadata

### Ad (App Name — max 30 karakter)
```
ChemClass Öğrenci
```

### Alt Başlık (Subtitle — max 30 karakter)
```
Kimya Dersi Takip Uygulaması
```

### Açıklama (Description — max 4000 karakter)
```
ChemClass Öğrenci, kimya öğretmeninizin paylaştığı sınıf koduyla giriş yaparak derse ait tüm bilgilere tek bir yerden ulaşmanızı sağlar.

ÖZELLİKLER

🏆 Puanım
• Toplam puanınızı ve sınıf sıralamasındaki yerinizi görün
• Kazanılan / düşülen puan dökümünü inceleyin
• Sınıf ortalaması ile kendi performansınızı karşılaştırın

📚 Ödevler & Duyurular
• Öğretmeninizin paylaştığı ödev, duyuru ve görevleri anında görün
• Yeni paylaşımlardan bildirimle haberdar olun

💬 Öğretmenle Mesajlaşma
• Öğretmeninize doğrudan mesaj gönderin, yanıtları aynı ekrandan takip edin

🔔 Bildirimler
• Yeni ödev, duyuru ve mesajlar için anlık uygulama içi bildirim

Giriş yapmak için öğretmeninizden aldığınız sınıf kodu ve okul numaranız yeterlidir — ayrı bir kayıt işlemi gerekmez.
```

### Anahtar Kelimeler (Keywords — max 100 karakter, virgülle ayrılmış)
```
kimya,öğrenci,not takip,ödev,sınıf,puan,sıralama,öğretmen,duyuru,mesaj
```

### Destek URL
```
https://muratsunker.github.io/chemclass/privacy-policy.html
```

### Pazarlama URL (opsiyonel)
```
https://chemclass-student.muratsunker.workers.dev
```

### Gizlilik Politikası URL (ZORUNLU)
```
https://muratsunker.github.io/chemclass/privacy-policy.html
```

---

## English Metadata (İngilizce — App Store tüm ülkeler için ister)

### Name
```
ChemClass Student
```

### Subtitle
```
Track Your Chemistry Class
```

### Description
```
ChemClass Student lets you sign in with the class code your chemistry teacher shares, giving you one place to follow everything about your class.

FEATURES

🏆 My Score
• See your total score and class ranking
• Review a breakdown of points earned and deducted
• Compare your performance with the class average

📚 Assignments & Announcements
• Instantly see homework, announcements, and tasks shared by your teacher
• Get notified about new posts

💬 Message Your Teacher
• Send messages directly to your teacher and follow replies in the same screen

🔔 Notifications
• In-app alerts for new assignments, announcements, and messages

All you need to sign in is the class code and school number provided by your teacher — no separate registration required.
```

### Keywords
```
chemistry,student,grades,homework,classroom,score,ranking,teacher,announcements,messaging
```

---

## App Store Connect – "What's New" (v1.0)

**Türkçe:**
```
ChemClass Öğrenci'nin ilk sürümüne hoş geldiniz! Puanınızı, ödevleri, duyuruları takip edin ve öğretmeninizle doğrudan mesajlaşın.
```

**English:**
```
Welcome to the first version of ChemClass Student! Track your score, assignments, and announcements, and message your teacher directly.
```

---

## Ekran Görüntüleri (Screenshots)

App Store için her cihaz boyutu için ekran görüntüsü gerekir:

| Cihaz | Boyut |
|-------|-------|
| iPhone 6.9" (Pro Max) | 1320×2868 px |
| iPhone 6.5" (Plus) | 1242×2688 px |
| iPad Pro 13" | 2064×2752 px |

**Minimum:** iPhone 6.5" zorunlu. iPad ekleyelecekse iPad Pro 13" de gerekli.
**Öneri:** Simulator'da 3-4 ekran görüntüsü al (Giriş, Puanım/Sıralama, Ödevler, Mesajlar)

---

## Privacy Nutrition Labels (App Store Connect → App Privacy)

Bu uygulama öğrenci adı, okul numarası, puan/not bilgisi ve öğretmenle yapılan
yazışmaları saklar. Bu nedenle teacher (ChemClass) uygulamasından **farklı**
olarak aşağıdaki kutular işaretlenmelidir:

### Data Linked to You
- **User Content** (mesajlar) → "Linked to you", amaç: **App Functionality**
- **Identifiers** (öğrenci adı, okul no, sınıf adı) → "Linked to you", amaç: **App Functionality**

### Data Not Collected ✅ (diğerleri için)
- Contact Info, Health & Fitness, Financial Info, Location, Contacts,
  Browsing History, Search History, Purchases, Usage Data, Diagnostics

### Data Used to Track You
- **Seç:** No (reklam/analitik takip yapılmıyor)

> Not: Bu veriler yalnızca ilgili öğretmenle ve ChemClass'ın bulut altyapısı
> (Supabase) ile paylaşılır; üçüncü taraf reklam/analitik ile paylaşılmaz.

---

## Age Rating

App Store Connect → "Age Rating" bölümünde:
- Tüm içerik kategorilerinde **"None"** seç
- **Rating:** 4+ (genel kullanım; uygulama orta/lise düzeyi kimya dersi öğrencilerine yöneliktir)

---

## Önemli Notlar

1. **Bundle ID** `com.muratsunker.chemclassogrenci` olarak Xcode'da ayarlandığından emin ol
2. **App Store Connect'te yeni uygulama** oluştururken aynı Bundle ID'yi gir — ChemClass (öğretmen) uygulamasından **ayrı** bir kayıt olmalı
3. Giriş ekranı sınıf kodu + okul numarası istediği için **"Sign in with Apple"** zorunluluğu doğmaz (üçüncü taraf hesap sistemi kullanılmıyor)
4. **TestFlight** ile önce birkaç öğrenciye gönder, test et, sonra App Review'a gönder
5. **Privacy Policy URL** canlı (erişilebilir) olmalı ve hem öğretmen hem öğrenci uygulamasını kapsamalı (bkz. güncellenmiş `privacy-policy.html`)
