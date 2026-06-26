# NM Hírfigyelő - fejléc hard fix v2
# Ez a script REGEX-szel cseréli a két valódi logós fejlécblokkot.
# Használat:
#   cd C:\a\b
#   powershell -ExecutionPolicy Bypass -File .\fix-nm-header-v2.ps1

$ErrorActionPreference = "Stop"

$root = Get-Location
$workerPath = Join-Path $root "src\worker.mjs"

if (!(Test-Path $workerPath)) {
  Write-Host "HIBA: Nem találom a src\worker.mjs fájlt." -ForegroundColor Red
  Write-Host "Előbb menj a projekt mappába: cd C:\a\b" -ForegroundColor Yellow
  exit 1
}

$backupDir = Join-Path $root ("backups\fix-nm-header-v2-" + (Get-Date -Format "yyyyMMdd-HHmmss"))
New-Item -ItemType Directory -Force -Path $backupDir | Out-Null
Copy-Item $workerPath (Join-Path $backupDir "worker.mjs.bak") -Force

$text = Get-Content $workerPath -Raw -Encoding UTF8
$original = $text

# 1) Főoldali nagy logós blokk cseréje.
$mainPattern = '(?s)<div class="brand nm-hero-header">.*?</div>\s*(?=\$\{data\.isEditor)'
$mainReplacement = @'
<div class="brand nm-simple-header">
        <div class="nm-simple-title">Nemzeti Minimumok</div>
      </div>
      '@

$mainMatches = [regex]::Matches($text, $mainPattern).Count
$text = [regex]::Replace($text, $mainPattern, $mainReplacement)

# 2) Cikkoldali/admin kompakt logós blokk cseréje.
$compactPattern = '(?s)<a class="brand nm-hero-header" href="\$\{homePath\}" aria-label="[^"]*">.*?</a>\s*(?=\$\{isEditor)'
$compactReplacement = @'
<a class="brand nm-simple-header" href="${homePath}" aria-label="Nemzeti Minimumok főoldal">
        <span class="nm-simple-title">Nemzeti Minimumok</span>
      </a>
      '@

$compactMatches = [regex]::Matches($text, $compactPattern).Count
$text = [regex]::Replace($text, $compactPattern, $compactReplacement)

# 3) Régi header tag inline felülírása: ez megakadályozza, hogy a régi CSS visszanövelje a fejlécet.
$headerInline = '<header class="site-header" style="min-height:0!important;height:auto!important;padding:12px 10px!important;margin:0 0 14px!important;border-radius:0 0 18px 18px!important;background:#070707!important;background-image:none!important;border:0!important;border-bottom:2px solid #c9152d!important;box-shadow:0 8px 22px rgba(0,0,0,.28)!important;overflow:visible!important;">'
$compactHeaderInline = '<header class="site-header compact-reader-header" style="min-height:0!important;height:auto!important;padding:12px 10px!important;margin:0 0 14px!important;border-radius:0 0 18px 18px!important;background:#070707!important;background-image:none!important;border:0!important;border-bottom:2px solid #c9152d!important;box-shadow:0 8px 22px rgba(0,0,0,.28)!important;overflow:visible!important;">'

$text = $text -replace '<header class="site-header"(?: style="[^"]*")?>', $headerInline
$text = $text -replace '<header class="site-header compact-reader-header"(?: style="[^"]*")?>', $compactHeaderInline

# 4) Header layout inline felülírás.
$layoutInline = '<div class="header-layout" style="display:flex!important;align-items:center!important;justify-content:space-between!important;gap:10px!important;width:100%!important;max-width:1220px!important;margin:0 auto!important;padding:0!important;">'
$text = $text -replace '<div class="header-layout"(?: style="[^"]*")?>', $layoutInline

# 5) Biztonsági CSS override minden oldalon: a nm-header-card/logó akkor is eltűnik, ha valahol bent marad.
$hardCss = @'
var NM_HEADER_HARD_FIX_CSS = `
.site-header{min-height:0!important;height:auto!important;padding:12px 10px!important;margin:0 0 14px!important;border-radius:0 0 18px 18px!important;background:#070707!important;background-image:none!important;border:0!important;border-bottom:2px solid #c9152d!important;box-shadow:0 8px 22px rgba(0,0,0,.28)!important;overflow:visible!important}
.site-header .header-layout{display:flex!important;align-items:center!important;justify-content:space-between!important;gap:10px!important;width:100%!important;max-width:1220px!important;margin:0 auto!important;padding:0!important;min-height:0!important}
.nm-header-card,.nm-logo-wrap,.nm-logo,.nm-title-block,.nm-title-script,.nm-title-main,.nm-tagline,.channel-logo-frame,.channel-logo,.header-inline-logo{display:none!important}
.nm-simple-header{display:flex!important;align-items:center!important;justify-content:center!important;flex:1 1 auto!important;min-width:0!important;text-align:center!important;text-decoration:none!important;background:none!important;border:0!important;box-shadow:none!important;padding:0!important;margin:0!important}
.nm-simple-title{display:block!important;color:#fff!important;font-weight:900!important;font-size:clamp(23px,6vw,38px)!important;line-height:1!important;letter-spacing:.2px!important;text-transform:none!important;text-shadow:0 2px 10px rgba(0,0,0,.55)!important;white-space:nowrap!important}
@media(max-width:760px){body.main-page,body.article-page,body.prompt-page,body.publish-page{padding-top:0!important}.site-header{position:relative!important;top:auto!important;left:auto!important;right:auto!important;width:100%!important;max-width:100%!important}.nm-simple-title{font-size:clamp(23px,7vw,32px)!important}}
`;
'@

if ($text -notmatch 'NM_HEADER_HARD_FIX_CSS') {
  $text = $text -replace '(var VERSION = .*?;\s*)', ('$1' + "`r`n" + $hardCss + "`r`n")
}

# 6) Minden style blokk elejére beletesszük az override-ot.
$text = $text -replace '<style>', '<style>${NM_HEADER_HARD_FIX_CSS}'

Set-Content -Path $workerPath -Value $text -Encoding UTF8

Write-Host ""
Write-Host "Talált főoldali logós blokkok: $mainMatches" -ForegroundColor Cyan
Write-Host "Talált kompakt logós blokkok: $compactMatches" -ForegroundColor Cyan

if ($mainMatches -eq 0 -and $compactMatches -eq 0 -and $original -eq $text) {
  Write-Host "FIGYELEM: nem történt módosítás. Lehet, hogy nem az aktuális worker.mjs van ebben a mappában." -ForegroundColor Yellow
} else {
  Write-Host "OK: fejléc javítva a worker.mjs-ben." -ForegroundColor Green
}

Write-Host "Backup: $backupDir" -ForegroundColor Green
Write-Host ""
Write-Host "Deploy indul..." -ForegroundColor Cyan
npx wrangler deploy

Write-Host ""
Write-Host "KÉSZ. Mobilon nyisd meg privát/inkognitó módban, vagy frissíts teljesen." -ForegroundColor Green
