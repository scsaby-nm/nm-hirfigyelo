# NM Hírfigyelő - egyszerű fejléc javítás
# Használat:
#   1) Másold ezt a fájlt a projekt gyökerébe: C:\a\b
#   2) Futtasd:
#      powershell -ExecutionPolicy Bypass -File .\fix-nm-header-simple.ps1

$ErrorActionPreference = "Stop"

$root = Get-Location
$workerPath = Join-Path $root "src\worker.mjs"

if (!(Test-Path $workerPath)) {
  Write-Host "HIBA: Nem találom a src\worker.mjs fájlt itt: $workerPath" -ForegroundColor Red
  Write-Host "Menj előbb a projekt mappába: cd C:\a\b" -ForegroundColor Yellow
  exit 1
}

$backupDir = Join-Path $root ("backups\header-fix-" + (Get-Date -Format "yyyyMMdd-HHmmss"))
New-Item -ItemType Directory -Force -Path $backupDir | Out-Null
Copy-Item $workerPath (Join-Path $backupDir "worker.mjs.bak") -Force

$text = Get-Content $workerPath -Raw -Encoding UTF8

$oldMainBrand = @'
<div class="brand nm-hero-header">
        <div class="nm-header-card">
          <div class="nm-logo-wrap"><img src="/channel-logo.jpg" alt="Nemzeti Minimumok log\xF3" class="nm-logo"></div>
          <div class="nm-title-block">
            <div class="nm-title-script">Nemzeti</div>
            <div class="nm-title-main">MINIMUMOK</div>
            <div class="nm-tagline">IGAZS\xC1G \u2022 SZABADS\xC1G \u2022 \xD6SSZEFOG\xC1S</div>
          </div>
        </div>
      </div>
'@

$newMainBrand = @'
<div class="brand nm-simple-header" style="display:flex;align-items:center;justify-content:center;flex:1;min-width:0;text-align:center;">
        <div style="color:#fff;font-weight:900;font-size:clamp(23px,6vw,38px);line-height:1;letter-spacing:.3px;text-transform:none;text-shadow:0 2px 10px rgba(0,0,0,.55);white-space:nowrap;">Nemzeti Minimumok</div>
      </div>
'@

$oldCompactBrand = @'
<a class="brand nm-hero-header" href="${homePath}" aria-label="Nemzeti Minimumok f\u0151oldal">
        <div class="nm-header-card">
          <div class="nm-logo-wrap"><img src="/channel-logo.jpg" alt="" class="nm-logo"></div>
          <div class="nm-title-block">
            <div class="nm-title-script">Nemzeti</div>
            <div class="nm-title-main">MINIMUMOK</div>
            <div class="nm-tagline">IGAZS\xC1G \u2022 SZABADS\xC1G \u2022 \xD6SSZEFOG\xC1S</div>
          </div>
        </div>
      </a>
'@

$newCompactBrand = @'
<a class="brand nm-simple-header" href="${homePath}" aria-label="Nemzeti Minimumok főoldal" style="display:flex;align-items:center;justify-content:center;flex:1;min-width:0;text-align:center;text-decoration:none;">
        <span style="color:#fff;font-weight:900;font-size:clamp(23px,6vw,38px);line-height:1;letter-spacing:.3px;text-transform:none;text-shadow:0 2px 10px rgba(0,0,0,.55);white-space:nowrap;">Nemzeti Minimumok</span>
      </a>
'@

$changed = $false

if ($text.Contains($oldMainBrand)) {
  $text = $text.Replace($oldMainBrand, $newMainBrand)
  $changed = $true
  Write-Host "OK: főoldali logós fejléc blokk cserélve." -ForegroundColor Green
} else {
  Write-Host "INFO: főoldali logós fejléc blokk már nincs meg, vagy már javítva van." -ForegroundColor Yellow
}

if ($text.Contains($oldCompactBrand)) {
  $text = $text.Replace($oldCompactBrand, $newCompactBrand)
  $changed = $true
  Write-Host "OK: cikkoldali/admin logós fejléc blokk cserélve." -ForegroundColor Green
} else {
  Write-Host "INFO: cikkoldali/admin logós fejléc blokk már nincs meg, vagy már javítva van." -ForegroundColor Yellow
}

# Fejléc magasság és háttér hard override, inline style-lal, hogy a régi CSS ne tudja visszahozni a bannert.
$text = $text.Replace(
  '<header class="site-header">',
  '<header class="site-header" style="min-height:0!important;height:auto!important;padding:12px 10px!important;margin:0 0 14px!important;border-radius:0 0 18px 18px!important;background:#070707!important;background-image:none!important;border:0!important;border-bottom:2px solid #c9152d!important;box-shadow:0 8px 22px rgba(0,0,0,.28)!important;overflow:visible!important;">'
)

$text = $text.Replace(
  '<header class="site-header compact-reader-header">',
  '<header class="site-header compact-reader-header" style="min-height:0!important;height:auto!important;padding:12px 10px!important;margin:0 0 14px!important;border-radius:0 0 18px 18px!important;background:#070707!important;background-image:none!important;border:0!important;border-bottom:2px solid #c9152d!important;box-shadow:0 8px 22px rgba(0,0,0,.28)!important;overflow:visible!important;">'
)

# Header layout inline override: maradjon menü + cím + keresés egy sorban, mobilon is vállalhatóan.
$text = $text.Replace(
  '<div class="header-layout">',
  '<div class="header-layout" style="display:flex!important;align-items:center!important;justify-content:space-between!important;gap:10px!important;width:100%!important;max-width:1220px!important;margin:0 auto!important;padding:0!important;">'
)

Set-Content -Path $workerPath -Value $text -Encoding UTF8

Write-Host ""
Write-Host "Backup elkészült itt: $backupDir" -ForegroundColor Cyan
Write-Host "Fejléc javítás kész. Deploy indul..." -ForegroundColor Cyan
Write-Host ""

npx wrangler deploy

Write-Host ""
Write-Host "Kész. Ellenőrizd inkognitóban vagy mobilon teljes frissítéssel." -ForegroundColor Green
