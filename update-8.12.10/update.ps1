param(
  [switch]$NoDeploy
)

$ErrorActionPreference = "Stop"

Write-Host "NM 8.12.10 frissítés indul..." -ForegroundColor Cyan

$root = Get-Location
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backupDir = Join-Path $root "backup"
New-Item -ItemType Directory -Force -Path $backupDir | Out-Null

$packageDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$sourceWorker = Join-Path $packageDir "worker.mjs"

if (!(Test-Path $sourceWorker)) {
  throw "Nem található a frissítő csomagban a worker.mjs: $sourceWorker"
}

# A wrangler.toml main mezője alapján döntünk, de ha nincs, automatikusan keresünk.
$targetWorker = $null
$wrangler = Join-Path $root "wrangler.toml"
if (Test-Path $wrangler) {
  $mainLine = Select-String -Path $wrangler -Pattern '^\s*main\s*=\s*"(.+)"' | Select-Object -First 1
  if ($mainLine -and $mainLine.Matches.Count -gt 0) {
    $targetWorker = Join-Path $root $mainLine.Matches[0].Groups[1].Value
  }
}

if (-not $targetWorker) {
  if (Test-Path (Join-Path $root "worker.mjs")) { $targetWorker = Join-Path $root "worker.mjs" }
  elseif (Test-Path (Join-Path $root "src\worker.mjs")) { $targetWorker = Join-Path $root "src\worker.mjs" }
  else { $targetWorker = Join-Path $root "worker.mjs" }
}

$targetDir = Split-Path -Parent $targetWorker
New-Item -ItemType Directory -Force -Path $targetDir | Out-Null

if (Test-Path $targetWorker) {
  Copy-Item $targetWorker (Join-Path $backupDir "worker-before-8.12.10-$stamp.mjs") -Force
  Write-Host "Biztonsági mentés kész." -ForegroundColor Green
}

Copy-Item $sourceWorker $targetWorker -Force
Write-Host "Worker frissítve: $targetWorker" -ForegroundColor Green

# Public és migration fájlok frissítése, ha vannak a csomagban.
if (Test-Path (Join-Path $packageDir "public")) {
  Copy-Item (Join-Path $packageDir "public") (Join-Path $root "public") -Recurse -Force
  Write-Host "Public fájlok frissítve." -ForegroundColor Green
}

if (Test-Path (Join-Path $packageDir "migrations")) {
  Copy-Item (Join-Path $packageDir "migrations") (Join-Path $root "migrations") -Recurse -Force
  Write-Host "Migrations fájlok frissítve." -ForegroundColor Green
}

if (Test-Path (Join-Path $packageDir "HANGCIKK_SETUP.md")) {
  Copy-Item (Join-Path $packageDir "HANGCIKK_SETUP.md") (Join-Path $root "HANGCIKK_SETUP.md") -Force
}

Write-Host "Szintaxis ellenőrzés..." -ForegroundColor Cyan
node --check $targetWorker

if ($NoDeploy) {
  Write-Host "Deploy kihagyva (-NoDeploy)." -ForegroundColor Yellow
  exit 0
}

Write-Host "Deploy indul..." -ForegroundColor Cyan
npx wrangler deploy
