$ErrorActionPreference = "Stop"
Set-Location (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path))

if (-not (Get-Command supabase -ErrorAction SilentlyContinue)) {
    Write-Error @"
Supabase CLI가 없습니다.
  scoop install supabase
  또는 https://supabase.com/docs/guides/cli/getting-started
"@
}

Write-Host "▶ naver-userinfo Edge Function 배포..."
supabase functions deploy naver-userinfo

Write-Host ""
Write-Host "✓ Userinfo URL (Supabase Custom Provider에 등록):"
Write-Host "  https://ghjasnmmhwdxloscgcvc.supabase.co/functions/v1/naver-userinfo"
