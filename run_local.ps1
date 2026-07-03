$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

function Sync-EnvJsonFromGeneratorConfig {
    $js = Get-Content "generator_config.js" -Raw -Encoding UTF8
    $urlM = [regex]::Match($js, "SUPABASE_URL:\s*'([^']*)'")
    $keyM = [regex]::Match($js, "SUPABASE_ANON_KEY:\s*'([^']*)'")
    if (-not $urlM.Success -or -not $keyM.Success) {
        throw "generator_config.js에서 Supabase 설정을 찾을 수 없습니다."
    }
    $obj = [ordered]@{
        SUPABASE_URL      = $urlM.Groups[1].Value
        SUPABASE_ANON_KEY = $keyM.Groups[1].Value
    }
    ($obj | ConvertTo-Json) + "`n" | Set-Content "env.json" -Encoding UTF8
    Write-Host "env.json <- generator_config.js 생성 완료"
}

if (-not (Test-Path "env.json")) {
    if (Test-Path "generator_config.js") {
        Sync-EnvJsonFromGeneratorConfig
    } else {
        Write-Host "env.json / generator_config.js 없음."
        Write-Host "  cp env.example.json env.json  후 Supabase URL·키 입력"
        exit 1
    }
}

& "$PSScriptRoot\scripts\write_web_env.ps1"

Write-Host ""
Write-Host "매니저 로컬 실행 (Chrome)..."
Write-Host "  홈:     http://localhost:<포트>/"
Write-Host "  관리자: http://localhost:<포트>/admin"
Write-Host "  종료:   q"
Write-Host ""

flutter run -d chrome
