$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $Root

$envPath = Join-Path $Root "env.json"
if (-not (Test-Path $envPath)) {
    Write-Host "env.json 없음. run_local.ps1 실행 또는 generator_config.js → env.json 생성 필요."
    exit 1
}

$cfg = Get-Content $envPath -Raw -Encoding UTF8 | ConvertFrom-Json
$url = [string]$cfg.SUPABASE_URL
$key = [string]$cfg.SUPABASE_ANON_KEY
if (-not $url -or -not $key -or $url -match "YOUR_" -or $key -match "YOUR_") {
    Write-Host "env.json에 SUPABASE_URL / SUPABASE_ANON_KEY를 설정하세요."
    exit 1
}

$escapedUrl = ($url | ConvertTo-Json -Compress)
$escapedKey = ($key | ConvertTo-Json -Compress)
$content = @"
window.AGAIN26_CONFIG = {
  SUPABASE_URL: $escapedUrl,
  SUPABASE_ANON_KEY: $escapedKey,
};
"@

$out = Join-Path $Root "web\env.js"
[System.IO.File]::WriteAllText($out, $content + "`n", [System.Text.UTF8Encoding]::new($false))
Write-Host "web/env.js <- env.json 동기화 완료"
