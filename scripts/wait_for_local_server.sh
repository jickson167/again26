#!/usr/bin/env bash
# localhost:8080 Flutter web-server 준비 대기 (HTML + JS 번들)
set -euo pipefail

PORT="${LOCAL_WEB_PORT:-8080}"
TRIES="${LOCAL_WEB_WAIT_TRIES:-120}"

html_ready() {
  curl -sf "http://127.0.0.1:$PORT/" >/dev/null 2>&1
}

js_ready() {
  curl -sf "http://127.0.0.1:$PORT/flutter_bootstrap.js" >/dev/null 2>&1 \
    && curl -sf "http://127.0.0.1:$PORT/main.dart.js" >/dev/null 2>&1
}

for _ in $(seq 1 "$TRIES"); do
  if html_ready && js_ready; then
    # 첫 빌드 직후 JS 실행·첫 프레임까지 여유
    sleep 3
    exit 0
  fi
  sleep 2
done

echo "로컬 서버(http://127.0.0.1:$PORT) 준비 시간 초과" >&2
exit 1
