# Temizle – iPhone'a Kurulum (Sadece Windows ile)

Mac olmadan iOS uygulaması derlemek için GitHub'ın ücretsiz Mac sunucularını kullanıyoruz.
Akış: **GitHub'a yükle → GitHub .ipa dosyasını üretir → Sideloadly ile iPhone'a kur.**

---

## 1. GitHub'da derleme (bir kez, ~10 dk)

1. https://github.com adresinde ücretsiz hesap aç (varsa giriş yap).
2. Sağ üstte **+ → New repository**. Ad: `Temizle`. **Public** seçebilirsin (Mac derleme dakikaları
   public depolarda sınırsız ücretsizdir; Private de olur ama aylık ücretsiz kota daha düşüktür). **Create repository**.
3. Açılan sayfada **uploading an existing file** bağlantısına tıkla.
4. Bu zip'ten çıkardığın `Temizle` klasörünün **içindekileri** (`.github`, `Sources`, `Resources`,
   `project.yml`, `KURULUM.md`) sürükleyip bırak → **Commit changes**.
   - `.github` klasörü Windows'ta gizli görünebilir. Gezginde **Görünüm → Gizli öğeler**'i aç.
   - Yüklemeden sonra depoda `.github/workflows/build.yml` dosyası görünmeli. Görünmüyorsa:
     **Actions → set up a workflow yourself** de, `build.yml` içeriğini yapıştırıp kaydet.
5. Üstteki **Actions** sekmesine gir. "iOS IPA olustur" işi kendiliğinden başlar
   (başlamazsa soldan seç → **Run workflow**). 5-10 dakika sürer.
6. Yeşil tik çıkınca işin içine gir, en altta **Artifacts → Temizle-ipa**'yı indir.
   İnen zip'i aç → içinden **Temizle.ipa** çıkar.

> Kırmızı çarpı çıkarsa: aynı sayfadaki **build-log** dosyasını indirip bana gönder, düzeltelim.

---

## 2. Bilgisayarı hazırla (bir kez)

1. **iTunes** ve **iCloud**'u **Apple'ın sitesinden** kur (Microsoft Store sürümleri değil —
   Sideloadly web sürümlerini istiyor). Store sürümü kuruluysa önce kaldır.
2. **Sideloadly**'yi https://sideloadly.io adresinden indirip kur.

## 3. iPhone'u hazırla (bir kez)

1. iPhone'u kabloyla bilgisayara tak, telefonda **"Bu bilgisayara güven"** → Güven, şifreni gir.
2. iPhone'da **Ayarlar → Gizlilik ve Güvenlik → Geliştirici Modu → Aç** → telefon yeniden başlar → **Aç**'ı onayla.
   (Bu seçenek görünmüyorsa önce 4. adımdaki kurulumu bir kez dene; sonra belirir.)

## 4. Uygulamayı kur

1. Sideloadly'yi aç. Üstte iPhone'unun adı görünmeli.
2. **Temizle.ipa**'yı Sideloadly penceresine sürükle.
3. **Apple ID** kutusuna Apple kimliğini yaz → **Start** → Apple ID şifresini (ve 2FA kodunu) gir.
   - İstersen bunun için ayrı/ikinci bir Apple ID kullanabilirsin; ücretsiz hesap yeterli.
4. "Done" yazınca telefonda **Ayarlar → Genel → VPN ve Aygıt Yönetimi** → Apple ID'ne dokun → **Güven**.
5. Ana ekrandan **Temizle**'yi aç → **İzin ver** → **Tam Erişime İzin Ver**.

---

## Bilmen gerekenler

- **7 günlük süre:** Ücretsiz Apple ID ile kurulan uygulamalar 7 gün sonra açılmaz.
  Aynı .ipa'yı Sideloadly ile tekrar kurman yeterli; ayarların ve "tutulanlar" listen silinmez.
  (Sideloadly'deki otomatik yenileme seçeneği aynı Wi-Fi'deyken bunu kendisi yapabilir.)
  Yıllık 99$'lık Apple Developer hesabıyla süre 1 yıla çıkar.
- Ücretsiz hesapla aynı anda en fazla 3 kendi-kurulumu uygulama olabilir.
- **Silme güvenli:** Hiçbir şey sen onaylamadan silinmez. Kaydırdıkların önce "silinecekler"
  listesine girer; çöp kutusu simgesinden gözden geçirip toplu silersin. iOS ayrıca kendi onayını sorar.
  Silinenler 30 gün **Fotoğraflar → Son Silinenler**'de durur; yer hemen açılsın istersen oradan da sil.

## Uygulama nasıl kullanılır

| Hareket | Sonuç |
|---|---|
| **Sola kaydır** veya yeşil ✓ | **Tut** (bir daha sorulmaz) |
| **Sağa kaydır** veya kırmızı 🗑 | **Silinecekler**'e ekle |
| ↶ Geri al | Son kararı geri alır |
| Videoda ▶ | Videoyu oynatır |

**Modlar:** Tümü · Aya göre · Videolar (en büyükler önce) · Ekran görüntüleri · Rastgele · Geçmişte bugün

## Kodu değiştirince

Depodaki bir dosyayı GitHub'da düzenleyip kaydettiğinde derleme otomatik yeniden çalışır;
yeni .ipa'yı indirip Sideloadly ile üzerine kurarsın.
