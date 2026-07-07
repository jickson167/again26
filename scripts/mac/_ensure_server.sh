#!/usr/bin/env bash
# 로컬 Flutter Web(8080)이 떠 있는지 확인하고, 없으면 run_local.sh를 새 터미널에서 실행한다.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
PORT=8080

port_open() {
  lsof -ti :"$PORT" >/dev/null 2>&1
}

wait_ready() {
  bash "$ROOT/scripts/wait_for_local_server.sh"
}

if port_open; then
  exit 0
fi

osascript <<APPLESCRIPT
tell application "Terminal"
  activate
  do script "cd '$ROOT' && AGAIN26_SKIP_BROWSER=1 ./run_local.sh"
end tell
APPLESCRIPT

echo "로컬 서버 시작 중… (최대 약 3분)"
if ! wait_ready; then
  echo "서버가 아직 준비되지 않았습니다. 터미널에서 Flutter 빌드가 끝난 뒤 다시 시도하세요."
  exit 1
fi
