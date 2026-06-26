# NM Hírfigyelő 8.7 – végleges Wrangler átállás

## Mit tartalmaz?

- Külön `public` JPG-assets, Base64 nélkül.
- `DB` D1 binding.
- `AI` Workers AI binding.
- RSS-, időjárás- és sportadat-cache.
- D1-ben tárolt angol fordítások.
- Külön `article_view` és `article_click` események.

## Automatikus telepítés Windows alatt

1. Telepíts Node.js-t.
2. Nyiss PowerShellt ebben a mappában.
3. Jelentkezz be:

   ```powershell
   npx wrangler login
   ```

4. Futtasd:

   ```powershell
   .\setup-and-deploy.ps1
   ```

A szkript:

1. megkeresi a meglévő `nm_hirfigyelo_db` adatbázist;
2. beírja a valódi D1 UUID-t a `wrangler.toml` fájlba;
3. létrehozza az indexeket és a fordítási cache-táblát;
4. deployolja a Workert és a képeket.

A már beállított `EDITOR_PASSWORD` Secret változatlanul megmarad. Ha mégsem lenne beállítva, külön futtasd: `npx wrangler secret put EDITOR_PASSWORD`.

## Miért tűnhetett el a számláló?

A számláló `-` értéket mutat, ha a Worker nem kapja meg a `DB` bindingot. A telepítőszkript ezt automatikusan javítja a meglévő D1 UUID-jének beállításával.

Telepítés után ellenőrizd:

- `/api/counter` – JSON-ban valós szám;
- `/api/stats` – Admin-belépést kér;
- egy cikk alján – `Cikkmegtekintések` valós számmal.

## Domain

A deploy után a Cloudflare Dashboardban ellenőrizd a **Settings → Domains & Routes** részt. A `nemzetiminimumok.hu` és a `www.nemzetiminimumok.hu` ennek a Workernek az útvonala legyen.
