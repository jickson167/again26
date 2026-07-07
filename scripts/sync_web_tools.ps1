$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $Root

$toolsDir = Join-Path $Root "web\tools"
New-Item -ItemType Directory -Force -Path $toolsDir | Out-Null

Copy-Item -Force "player_row_generator_v3.html" (Join-Path $toolsDir "player_row_generator_v3.html")
Copy-Item -Force "coach_row_generator_v1.html" (Join-Path $toolsDir "coach_row_generator_v1.html")
Copy-Item -Force "key_positions_v2.js" (Join-Path $toolsDir "key_positions_v2.js")

$envJs = Join-Path $Root "web\env.js"
$generatorConfig = Join-Path $Root "generator_config.js"
$destConfig = Join-Path $toolsDir "generator_config.js"

if (Test-Path $envJs) {
    Copy-Item -Force $envJs $destConfig
} elseif (Test-Path $generatorConfig) {
    Copy-Item -Force $generatorConfig $destConfig
} else {
    Write-Error "sync_web_tools: web/env.js 또는 generator_config.js 없음"
}

Write-Host "web/tools <- 선수·감독 생성기 동기화 완료"
