$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

Write-Host "=== Again26 Windows 초기 설정 ==="
Write-Host ""

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    Write-Error "Flutter SDK가 PATH에 없습니다. https://docs.flutter.dev/get-started/install/windows"
}

Write-Host "▶ flutter pub get"
flutter pub get

if (-not (Test-Path "env.json")) {
    if (Test-Path "generator_config.js") {
        $js = Get-Content "generator_config.js" -Raw -Encoding UTF8
        $urlM = [regex]::Match($js, "SUPABASE_URL:\s*'([^']*)'")
        $keyM = [regex]::Match($js, "SUPABASE_ANON_KEY:\s*'([^']*)'")
        if ($urlM.Success -and $keyM.Success) {
            $obj = [ordered]@{
                SUPABASE_URL      = $urlM.Groups[1].Value
                SUPABASE_ANON_KEY = $keyM.Groups[1].Value
            }
            ($obj | ConvertTo-Json) + "`n" | Set-Content "env.json" -Encoding UTF8
            Write-Host "▶ env.json <- generator_config.js"
        }
    } else {
        Copy-Item "env.example.json" "env.json"
        Write-Host ""
        Write-Host "▶ env.json 생성됨 -> Supabase URL·Publishable Key 입력 필요"
        Write-Host "  $PSScriptRoot\env.json"
        exit 0
    }
}

& "$PSScriptRoot\scripts\write_web_env.ps1"
& "$PSScriptRoot\scripts\sync_web_tools.ps1"

Write-Host ""
Write-Host "✓ 설정 완료"
Write-Host "  실행: .\run_local.ps1"
Write-Host "  Cursor: Run and Debug (F5) -> Again26 매니저 (Chrome)"
