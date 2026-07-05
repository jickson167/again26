#!/usr/bin/env bash
# again26 웹 매니저 배포 (GitHub Pages)
# 사용: ./deploy.sh
#       ./deploy.sh "커밋 메시지"   ← 변경사항 있을 때
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

echo "▶ 원격 최신 반영..."
git pull --rebase origin main

DIRTY=false
if ! git diff --quiet || ! git diff --cached --quiet; then
  DIRTY=true
elif [ -n "$(git ls-files --others --exclude-standard)" ]; then
  DIRTY=true
fi

if $DIRTY; then
  MSG="${1:-업데이트 배포}"
  echo "▶ 변경사항 커밋: $MSG"
  git add -A
  git commit -m "$MSG"
  git push origin main
else
  echo "▶ 커밋할 변경 없음 → GitHub Actions 재배포만 실행"
  gh workflow run deploy-web.yml --ref main
  sleep 3
fi

RUN_ID="$(gh run list --workflow=deploy-web.yml --limit 1 --json databaseId -q '.[0].databaseId')"
echo "▶ 배포 진행 중 (run $RUN_ID)..."
gh run watch "$RUN_ID"

echo ""
echo "✓ 배포 완료"
echo "  https://jickson167.github.io/again26/"
echo "  https://jickson167.github.io/again26/admin"
