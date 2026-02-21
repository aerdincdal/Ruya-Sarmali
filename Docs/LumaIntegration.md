# Luma Dream Machine entegrasyonu

Uygulama `LumaAIService` aracılığıyla Dream Machine API’sine bağlanır. Servis şu şekilde çalışır:

1. `POST https://api.lumalabs.ai/dream-machine/v1/generations/video`  
   Gönderilen JSON örneği (`ray-2` modeli 9 saniyeye kadar 9:16 / 1080p klip üretiyor):
   ```json
   {
     "prompt": "Kullanıcının rüya promptu ve astro yorumu",
     "model": "ray-2",
     "generation_type": "video",
     "aspect_ratio": "9:16",
     "resolution": "1080p",
     "duration": "9s"
   }
   ```
2. API `id` ve `state` döner. Bu değer `pollGeneration` fonksiyonuna aktarılır.
3. `GET https://api.lumalabs.ai/dream-machine/v1/generations/{id}` çağrısı 3 sn arayla yapılır.  
   - `state == "completed"` olduğunda `assets.video` URL’si alınır.  
   - `state == "failed"` ise hata kullanıcıya iletilir.  
   - 60 deneme sonunda hâlâ tamamlanmamışsa zaman aşımı hatası verilir.

## Anahtarlar
- `.env` veya Xcode Run Scheme’de `LUMAAI_API_KEY` çevresel değişkenini ayarlayın.  
- Alternatif olarak `Info.plist` içindeki `LUMAAI_API_KEY` alanına değeri girin.

## Hata durumları
- API yanıtı 200 dışı gelirse servis hata mesajını UI’a gönderir.  
- Video URL bulunamazsa sentetik video (DreamVideoSynthesizer) yine oluşturulup kaydedilir, bu nedenle kullanıcı tarafında süreç kesilmez.

Bu doküman Swift tarafında yapılan entegrasyonu Dream Machine resmi belgeleriyle hizalamak için hazırlanmıştır.*** End Patch
