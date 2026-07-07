#!/usr/bin/env bash
# 평소 쓰는 Chrome(로그인·지문 저장됨)으로 URL을 연다.
# 기존 localhost 탭(흰 화면) 재사용 대신 새 탭 + 캐시 우회.
set -euo pipefail

URL="${1:-http://localhost:8080/admin}"
CACHE_BUST="${URL}?_t=$(date +%s)"

open_in_chrome() {
  osascript <<APPLESCRIPT
tell application "Google Chrome"
  activate
  if (count of windows) = 0 then
    make new window with properties {URL:"${CACHE_BUST}"}
  else
    tell window 1
      make new tab with properties {URL:"${CACHE_BUST}"}
      set active tab index to (count of tabs)
    end tell
  end if
end tell
APPLESCRIPT
}

if open_in_chrome 2>/dev/null; then
  exit 0
fi

open "$CACHE_BUST"
