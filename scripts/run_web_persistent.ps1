$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$chromeProfile = Join-Path $projectRoot ".chrome_profile"
$webPort = 7357

Set-Location $projectRoot
New-Item -ItemType Directory -Force -Path $chromeProfile | Out-Null

flutter run `
  -d chrome `
  --web-port $webPort `
  --web-browser-flag "--user-data-dir=$chromeProfile"
