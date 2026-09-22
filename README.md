# Vaat: Dolandırıcı Kariyeri

Hicivli, tur bazlı, 2D pixel art bir dolandırıcı kariyeri simülasyonu. Oyuncu sırayla farklı türde şemalar kurar (klasik Ponzi, saadet zinciri, üretim kılıfı, kripto borsası, borsa manipülasyonu…), her birini batmadan satar, devreder veya kaçarak terk eder. Kazanmak yok, sadece daha iyi kaçmak var.

Açık kaynak. Mobil, Flutter. Türkiye pazarı için Türkçe, sonra İngilizce.

> Bu oyun hicivdir, yatırım tavsiyesi değildir. Gerçek hayatta yüksek ve düzenli getiri vaadi görürseniz SPK'ya sorun.

## Depo yapısı

```
packages/sim/     Saf Dart simülasyon motoru, Flutter bağımlılığı yok, kendi testleri var
content/          Denge parametreleri (balance.json) ve olay kartları (events/*.json)
app/              Flutter uygulaması: Riverpod state, 5 tab, HUD; içerik assets/content sembolik bağıyla gelir
assets/           Pixel art kaynakları ve export'ları (henüz yok)
```

## Simülasyonu terminalde çalıştırma

```bash
cd packages/sim
dart pub get
dart test
dart run bin/run.dart sim --weeks 260 --rate 0.012 --skim 0.13 --seed 42
dart run bin/run.dart verify
dart run bin/run.dart sweep --seeds 30
```

`sim` bir şemayı hafta hafta koşturur ve çöküş anını yazar. `verify` tasarım dokümanındaki aylık çöküş tablosunu basit modelle yeniden üretir. `sweep` birkaç vaat oranını çok seed ile koşturup çöküş haftasının medyanını basar; denge değişince ilk bakılan yer.

## Uygulamayı çalıştırma

```bash
cd app
flutter pub get
flutter test
flutter run
```

İçerik dosyaları `app/assets/content` sembolik bağıyla depo kökündeki `content/` klasöründen okunur; JSON'u tek yerden düzenleyin.

Tur yapısı: "Hafta kapat" basılınca olaysız haftalar otomatik akar (en fazla 8), bir olay kartı düşünce veya şema bitince durur. Cevapsız bırakılan kart hafta kapanırken SON seçenekle kapanır; olay yazarken son seçenek her zaman pasif olan olmalı.

## Kod standardı

İngilizce tanımlayıcı, Türkçe yorum. Yorumlar "ne"yi değil "neden"i anlatır. Simülasyon deterministiktir: aynı seed ve aynı hamle dizisi aynı sonucu verir.

## Lisans

Kararlaştırılacak.
