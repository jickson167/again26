#!/usr/bin/env bash
# 선수 생성기 HTML을 Flutter web 배포 경로(web/tools)에 복사
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

mkdir -p web/tools

cp player_row_generator_v3.html web/tools/
cp key_positions_v2.js web/tools/

if [[ -f web/env.js ]]; then
  cp web/env.js web/tools/generator_config.js
elif [[ -f generator_config.js ]]; then
  cp generator_config.js web/tools/generator_config.js
else
  echo "sync_web_tools: web/env.js 또는 generator_config.js 없음"
  exit 1
fi

echo "web/tools ← 선수 생성기 동기화 완료"
