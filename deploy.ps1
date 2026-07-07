$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

$Message = if ($args.Count -gt 0) { $args -join " " } else { "업데이트 배포" }

Write-Host "▶ 원격 최신 반영..."
git pull --rebase origin main

$dirty = $false
if ((git status --porcelain)) {
    $dirty = $true
}

if ($dirty) {
    Write-Host "▶ 변경사항 커밋: $Message"
    git add -A
    git commit -m $Message
    git push origin main
} else {
    Write-Host "▶ 커밋할 변경 없음 -> GitHub Actions 재배포"
    gh workflow run deploy-web.yml --ref main
    Start-Sleep -Seconds 3
}

$runId = gh run list --workflow=deploy-web.yml --limit 1 --json databaseId -q ".[0].databaseId"
Write-Host "▶ 배포 진행 중 (run $runId)..."
gh run watch $runId

Write-Host ""
Write-Host "✓ 배포 완료"
Write-Host "  https://jickson167.github.io/again26/"
Write-Host "  https://jickson167.github.io/again26/admin"
