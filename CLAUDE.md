# Ders notu dizgi projesi (redoks-tepkimeleri.html)

## Standart talimat
- Yeni el yazısı ders notu sayfaları geldiğinde, **her zaman** mevcut
  `/home/user/chemclass/redoks-tepkimeleri.html` dosyasının üzerine yeni
  `<section class="page">` blokları olarak ekle. Ayrı dosya açma; mevcut
  paylaşılan `<style>` bloğunu (CSS bileşenleri, renk değişkenleri, `.cell`,
  `.she`, `.eqn-block`, `.frac` vb.) yeniden kullan/genişlet.

## Kota verimliliği (önemli — maliyeti büyük ölçüde azaltır)
- **Kaynak PDF okuma**: Önce **120-150 dpi** ile kırp/oku. Sadece el yazısı
  gerçekten okunamıyorsa o bölgeyi 200+ dpi ile tekrar kırp. Tüm kaynak
  sayfayı yüksek dpi'da okumaktan kaçın.
- **SVG hücre/diyagram şablonları**: Sıfırdan tasarlama. Belgede zaten
  benzer bir hücre diyagramı varsa (galvanik hücre, elektroliz hücresi,
  Hoffman düzeneği vb.) o `<svg>` bloğunu **kopyala**, sadece pattern id'lerini
  (çakışmasın diye benzersiz numara ver), etiketleri, renkleri ve
  gerekirse elektrot/sıvı seviyelerini değiştir. Geometriyi (koordinatlar,
  viewBox, path'ler) yeniden hesaplamaya çalışma.
- **Doğrulama görüntüleri**: Aşağıdaki "Doğrulama döngüsü"ndeki tek 60 dpi
  son sayfa kontrolü dışında ekstra debug ekran görüntüsü/kırpma alma.
  Bir overlay/diyagram sorunundan şüpheleniyorsan önce kodu/koordinatları
  mantık yürüterek kontrol et, görsel kontrolü en sona bırak.

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
   Son `.page` bölümünün `heightMM` değeri **290.00-297.00** aralığında
   olmalı (tam 297.00 şart değil — `min-height:297mm` zaten taşmayı önler).
   - 297'den büyükse: fazlalık kadar mm'yi `.eqn-block`, `.cell`,
     `.statements`, `.answer-lines`, `.example`, `ul.notes`, `.two-col` gibi
     elemanlara satır-içi `style` ile küçük marj/padding/yükseklik/`.cell`
     genişliği azaltmaları uygulayarak düş, tekrar ölç. 290-297 aralığına
     girince dur — bu adımda PDF render veya ekran görüntüsü ALMA. Her
     denemede büyük adımlarla küçült (ör. %50→%40 gibi), tek tek mm
     denemekle çok tur harcama.
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
