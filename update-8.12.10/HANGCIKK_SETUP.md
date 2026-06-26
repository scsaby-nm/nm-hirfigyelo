# Hangcikk automatikus generalas - beallitas

Ez a kor a Google Text-to-Speech + Cloudflare R2 alapot epiti be JSON service account kulcs nelkul.

## Cloudflare R2

Bucket letrehozasa:

```powershell
npx wrangler r2 bucket create nm-audio
```

Fontos: az R2 binding csak akkor keruljon vissza a `wrangler.toml` fajlba, ha az R2 mar engedelyezve van a Cloudflare fiokban. Kulonben a `npx wrangler deploy` megall ezzel:

```text
Please enable R2 through the Cloudflare Dashboard. [code: 10042]
```

Ha az R2 mar engedelyezve van, ezt lehet visszatenni:

```toml
[[r2_buckets]]
binding = "AUDIO_BUCKET"
bucket_name = "nm-audio"
```

Allits be publikus R2 elerest vagy custom domaint:

```text
https://audio.nemzetiminimumok.hu
```

## Worker valtozok

A `wrangler.toml` alapbol ezt hasznalja:

```toml
[vars]
AUDIO_PUBLIC_BASE_URL = "https://audio.nemzetiminimumok.hu"
GOOGLE_TTS_VOICE = "hu-HU-Wavenet-A"
```

Ha mas audio domaint hasznalsz, ezt ird at.

## Google hitelesites JSON kulcs nelkul

A Worker ket kulcsmentes modot tamogat.

### 1. Token broker ajanlott

A `GOOGLE_TTS_TOKEN_URL` egy sajat vagy felhos token broker endpoint, amely Workload Identity Federation/OAuth alapon rovid eletu Google access tokent ad vissza:

```json
{
  "access_token": "ya29...."
}
```

Secret beallitas:

```powershell
npx wrangler secret put GOOGLE_TTS_TOKEN_URL
```

Ha a broker sajat vedelmet hasznal:

```powershell
npx wrangler secret put GOOGLE_TTS_TOKEN_BROKER_TOKEN
```

### 2. Ideiglenes rovid eletu access token

Csak tesztre:

```powershell
npx wrangler secret put GOOGLE_TTS_ACCESS_TOKEN
```

Ez nem Service Account JSON kulcs, de lejar, ezert eles rendszerhez token broker kell.

## D1 migracio

Az eles adatbazisban az audio mezok mar leteznek. Ezert jelenleg ne futtasd ujra a `0006_audio_articles.sql` migraciot, mert `duplicate column name: audio_enabled` hibaval megallhat.

Altalanos migracio parancs csak akkor kell, ha tenylegesen uj, meg nem alkalmazott migracio van:

```powershell
npx wrangler d1 migrations apply nm_hirfigyelo_db --remote
```

## Deploy

```powershell
npx wrangler deploy
```

## Hasznalat

1. Nyisd meg az admin feluletet.
2. Egy mar publikalt NM cikket nyiss meg szerkesztesre.
3. A Hangoscikk resznel kattints: `Hangcikk keszitese`.
4. A Worker a cikk szovegebol MP3-at general.
5. Az MP3 R2-be kerul: `audio/{articleSlug}.mp3`.
6. A cikk `audio_url` mezoje D1-ben frissul.
7. A publikus cikkoldalon megjelenik a HTML audio player.

## Fontos

Ha a cikkhez mar van `audio_url`, a Worker nem general ujat automatikusan. Ujrageneralashoz az admin felulet megerositest ker.
