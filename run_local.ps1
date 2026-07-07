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

function Stop-PortListener {
    param([int]$Port)
    try {
        $connections = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue
        foreach ($conn in $connections) {
            $pid = $conn.OwningProcess
            if ($pid -and $pid -ne 0) {
                Write-Host "$Port 포트 사용 중 (PID $pid) -> 종료"
                Stop-Process -Id $pid -Force -ErrorAction SilentlyContinue
            }
        }
    } catch {
        # Get-NetTCPConnection 미지원 환경은 무시
    }
}

if (-not (Test-Path "env.json")) {
    if (Test-Path "generator_config.js") {
        Sync-EnvJsonFromGeneratorConfig
    } elseif (Test-Path "env.example.json") {
        Copy-Item "env.example.json" "env.json"
        Write-Host "env.json <- env.example.json 복사됨. Supabase URL·키를 입력하세요."
        exit 1
    } else {
        Write-Host "env.json 없음."
        Write-Host "  Copy-Item env.example.json env.json  후 Supabase URL·키 입력"
        exit 1
    }
}

& "$PSScriptRoot\scripts\write_web_env.ps1"
& "$PSScriptRoot\scripts\sync_web_tools.ps1"

$cfg = Get-Content "env.json" -Raw -Encoding UTF8 | ConvertFrom-Json
$url = [string]$cfg.SUPABASE_URL
$key = [string]$cfg.SUPABASE_ANON_KEY
if (-not $url -or -not $key -or $url -match "YOUR_" -or $key -match "YOUR_") {
    Write-Host "env.json에 SUPABASE_URL / SUPABASE_ANON_KEY를 설정하세요."
    exit 1
}

Stop-PortListener -Port 8080

$localOpenUrl = if ($env:LOCAL_OPEN_URL) { $env:LOCAL_OPEN_URL } else { "http://localhost:8080/admin" }
$skipBrowser = $env:AGAIN26_SKIP_BROWSER -eq "1"

Write-Host ""
Write-Host "Again26 로컬 서버 실행..."
Write-Host "  서버만 띄우고, 평소 쓰는 Chrome으로 매니저 페이지를 엽니다."
Write-Host "  매니저: http://localhost:8080/admin"
Write-Host "  게임:   http://localhost:8080/"
Write-Host "  hot reload: r  |  hot restart: R  |  종료: q"
Write-Host ""

if (-not $skipBrowser) {
    Start-Job -ScriptBlock {
        param($OpenUrl)
        for ($i = 0; $i -lt 90; $i++) {
            try {
                $resp = Invoke-WebRequest -Uri "http://127.0.0.1:8080/" -UseBasicParsing -TimeoutSec 2
                if ($resp.StatusCode -ge 200 -and $resp.StatusCode -lt 500) {
                    Start-Process $OpenUrl
                    return
                }
            } catch {
                Start-Sleep -Seconds 2
            }
        }
    } -ArgumentList $localOpenUrl | Out-Null
}

flutter run -d web-server --web-port 8080 `
  --dart-define=SUPABASE_URL="$url" `
  --dart-define=SUPABASE_ANON_KEY="$key"
