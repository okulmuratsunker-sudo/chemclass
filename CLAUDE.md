# Ders notu dizgi projesi (redoks-tepkimeleri.html)

## Standart talimat
- Yeni el yazısı ders notu sayfaları geldiğinde, **her zaman** mevcut
  `/home/user/chemclass/redoks-tepkimeleri.html` dosyasının üzerine yeni
  `<section class="page">` blokları olarak ekle. Ayrı dosya açma; mevcut
  paylaşılan `<style>` bloğunu (CSS bileşenleri, renk değişkenleri, `.cell`,
  `.she`, `.eqn-block`, `.frac` vb.) yeniden kullan/genişlet.

## Editöryel kurallar
- İçeriği sadakatle aktar; sadece açık OCR saçmalıklarını düzelt.
- Şıklardaki/ifadelerdeki kimyasal olarak tartışmalı sayıları "düzeltme" —
  kaynakta yazıldığı gibi aktar (ör. hesaplanan değer 2,27V olsa bile
  kaynakta "2,26 V" yazıyorsa öyle bırak).
- Bağlamı belirsiz, kopuk/yetim parçaları (ör. başlığı/sorusu olmayan şık
  kalıntıları) belgeye dahil etme.
- "Örnek N" numaralandırması belge boyunca kesintisiz devam eder.

## Doğrulama döngüsü (KOTA TASARRUFLU SIRAYLA)
Yardımcı scriptler `/home/user/chemclass/tools/render.js` ve
`/home/user/chemclass/tools/measure.js` içinde, repoya kayıtlı (kalıcı).
`/tmp` her oturumda sıfırlanır, sadece çıktı dosyaları (`*.pdf`, `*.png`)
için kullan.

1. Yeni sayfayı `</body></html>`'den önce ekle.
2. **Önce DOM yüksekliğini ölç** (ucuz, görsel yok):
   ```
   node /home/user/chemclass/tools/measure.js /home/user/chemclass/redoks-tepkimeleri.html
   ```
   Son `.page` bölümünün `heightMM` değeri tam **297.00** olmalı.
   - 297'den büyükse: fazlalık kadar mm'yi `.eqn-block`, `.cell`,
     `.statements`, `.answer-lines`, `.example`, `ul.notes`, `.two-col` gibi
     elemanlara satır-içi `style` ile küçük marj/padding/yükseklik/`.cell`
     genişliği azaltmaları uygulayarak düş, tekrar ölç. 297.00 olana kadar
     tekrarla — bu adımda PDF render veya ekran görüntüsü ALMA.
3. Ölçüm 297.00 olunca, **tek seferde** tam belgeyi render et ve sayfa
   sayısını doğrula:
   ```
   cd /tmp && node /home/user/chemclass/tools/render.js /home/user/chemclass/redoks-tepkimeleri.html /tmp/redoks.pdf \
     && pdfinfo /tmp/redoks.pdf | grep Pages
   ```
   PDF sayfa sayısı `.page` bölüm sayısına eşit olmalı.
4. Sadece **bir kez**, düşük çözünürlükte (100 değil **60 dpi**) son sayfayı
   PNG'ye çevirip görsel kontrol için oku:
   ```
   cd /tmp && rm -f rpage*.png && pdftoppm -png -r 60 -f N -l N /tmp/redoks.pdf rpage
   ```
5. Dosyayı tekrar tekrar baştan okuma — sadece düzenlenecek bölümü
   `offset`/`limit` ile oku.

## Tüm yeni sayfalar bittiğinde
- `.page-foot::after{ content:"Sayfa " counter(pagenum) " / N"; }` içindeki
  toplam sayfa sayısını güncelle, son bir tam render ile doğrula.
- Türkçe, açıklayıcı commit mesajıyla commit edip
  `claude/code-typesetting-review-a30bli` dalına push et.
- İstenirse PDF'i `SendUserFile` ile gönder, repo içine geçici PDF kopyası
  bırakma.
