#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
MAC="$ROOT/scripts/mac"
DESKTOP="${HOME}/Desktop"

install_one() {
  local src_name="$1"
  local dest_name="$2"
  cp "$MAC/$src_name" "$DESKTOP/$dest_name"
  chmod +x "$DESKTOP/$dest_name"
  echo "  ✓ $DESKTOP/$dest_name"
}

echo "Again26 바로가기 → 데스크탑 설치"
echo ""

install_one "open_admin.command" "Again26 매니저.command"

echo ""
echo "완료. 데스크탑에서 더블클릭하세요."
echo "  · Again26 매니저 → http://localhost:8080/admin"
echo "  (평소 쓰는 Chrome 프로필로 열립니다 — Google/네이버 자동로그인 유지)"
