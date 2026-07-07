#!/usr/bin/env bash
# 평소 쓰는 Chrome으로 URL을 연다.
set -euo pipefail

URL="${1:-http://localhost:8080/admin}"

open_in_chrome() {
  osascript <<APPLESCRIPT
tell application "Google Chrome"
  activate
  if (count of windows) = 0 then
    make new window with properties {URL:"${URL}"}
  else
    tell window 1
      make new tab with properties {URL:"${URL}"}
      set active tab index to (count of tabs)
    end tell
  end if
end tell
APPLESCRIPT
}

if open_in_chrome 2>/dev/null; then
  exit 0
fi

open "$URL"
