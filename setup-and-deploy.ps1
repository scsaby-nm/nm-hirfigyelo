$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

Write-Host "NM Hirfigyelo 9.1.0 - Cloudflare setup and deployment" -ForegroundColor Cyan

$databaseName = "nm_hirfigyelo_db"
$rawList = npx wrangler d1 list --json
$databases = $rawList | ConvertFrom-Json
$database = $databases | Where-Object { $_.name -eq $databaseName } | Select-Object -First 1

if (-not $database) {
  throw "The D1 database '$databaseName' was not found. Check the active Cloudflare account and database name."
}

$databaseId = $database.uuid
if (-not $databaseId) { $databaseId = $database.id }
if (-not $databaseId) {
  throw "The D1 database ID could not be read from the Wrangler response."
}

$configPath = Join-Path $PSScriptRoot "wrangler.toml"
$config = [IO.File]::ReadAllText($configPath)
$config = [regex]::Replace($config, 'database_id = "[^"]+"', "database_id = `"$databaseId`"")
[IO.File]::WriteAllText($configPath, $config, (New-Object Text.UTF8Encoding($false)))

Write-Host "D1 binding: DB -> $databaseName ($databaseId)" -ForegroundColor Green

npx wrangler d1 execute $databaseName --remote --file=migrations/0001_performance.sql
if ($LASTEXITCODE -ne 0) { throw "The D1 migration failed." }

npx wrangler d1 execute $databaseName --remote --file=migrations/0002_content_push.sql
if ($LASTEXITCODE -ne 0) { throw "The content and push migration failed." }

npx wrangler d1 execute $databaseName --remote --file=migrations/0003_nm_articles.sql
if ($LASTEXITCODE -ne 0) { throw "The NM articles migration failed." }

npx wrangler d1 execute $databaseName --remote --file=migrations/0004_push_outbox.sql
if ($LASTEXITCODE -ne 0) { throw "The push outbox migration failed." }

npx wrangler d1 execute $databaseName --remote --file=migrations/0005_hidden_articles.sql
if ($LASTEXITCODE -ne 0) { throw "The hidden articles migration failed." }

$audioMigrationCommands = @(
  "ALTER TABLE nm_articles ADD COLUMN audio_url TEXT",
  "ALTER TABLE nm_articles ADD COLUMN audio_duration TEXT",
  "ALTER TABLE nm_articles ADD COLUMN audio_enabled INTEGER DEFAULT 0",
  "ALTER TABLE nm_articles ADD COLUMN audio_summary TEXT",
  "CREATE INDEX IF NOT EXISTS idx_nm_articles_audio_created ON nm_articles(audio_enabled, created_at DESC)"
)
foreach ($command in $audioMigrationCommands) {
  npx wrangler d1 execute $databaseName --remote --command=$command
  if ($LASTEXITCODE -ne 0) {
    Write-Host "Audio migration step skipped or already applied: $command" -ForegroundColor Yellow
  }
}

npx wrangler deploy
if ($LASTEXITCODE -ne 0) { throw "The Worker deployment failed." }

Write-Host "Done. Check these routes:" -ForegroundColor Green
Write-Host "  /api/counter"
Write-Host "  /health"
Write-Host "  /editor"
Write-Host "  /hangoscikkek"
Write-Host "  /api/editor/push/outbox"




