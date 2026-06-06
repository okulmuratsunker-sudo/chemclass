# Kasa Worker — Kurulum

## Ön Koşullar

1. Cloudflare hesabı (ücretsiz plan yeterli)
2. Node.js kurulu olmalı
3. Terminal açık

---

## Adım 1 — Wrangler CLI Kur

```bash
npm install -g wrangler
wrangler login
```

---

## Adım 2 — D1 Veritabanı Oluştur

```bash
cd kasa-worker
wrangler d1 create kasa-db
```

Çıktıda görünen `database_id` değerini kopyala ve `wrangler.toml` içindeki
`REPLACE_WITH_YOUR_D1_DATABASE_ID` yerine yapıştır.

---

## Adım 3 — Veritabanı Şemasını Uygula

```bash
wrangler d1 execute kasa-db --file=schema.sql
```

---

## Adım 4 — R2 Bucket Oluştur

```bash
wrangler r2 bucket create kasa-files
```

---

## Adım 5 — JWT Secret Ayarla

```bash
wrangler secret put JWT_SECRET
```

İstediğin güçlü bir şifre gir (en az 32 karakter öneririm, örn. rastgele bir UUID).

---

## Adım 6 — Deploy Et

```bash
wrangler deploy
```

Çıktıda `https://kasa-worker.<kullanıcıadın>.workers.dev` gibi bir URL göreceksin.

---

## Adım 7 — Kasa Uygulamasına Bağla

1. Kasa uygulamasını aç
2. **Ayarlar** sekmesine git
3. **Worker URL** alanına deploy çıktısındaki URL'yi yapıştır
4. Kaydet
5. Faturalar veya Kimlikler sekmesine git → **Kayıt Ol** ile hesap oluştur

---

## Ücretler

Cloudflare ücretsiz planında:
- Worker: 100.000 istek/gün
- D1: 5 GB depolama, 25M okuma/gün
- R2: 10 GB depolama, 10M okuma/ay

Kişisel kullanımda bu sınırlara ulaşmak neredeyse imkânsız → **ek ücret çıkmaz**.
