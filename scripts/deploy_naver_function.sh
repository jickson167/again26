#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if ! command -v supabase >/dev/null 2>&1; then
  echo "Supabase CLI가 없습니다."
  echo "  brew install supabase/tap/supabase"
  exit 1
fi

echo "▶ naver-userinfo Edge Function 배포..."
supabase functions deploy naver-userinfo

echo ""
echo "✓ Userinfo URL (Supabase Custom Provider에 등록):"
echo "  https://ghjasnmmhwdxloscgcvc.supabase.co/functions/v1/naver-userinfo"
