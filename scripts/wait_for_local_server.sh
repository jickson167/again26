#!/usr/bin/env bash
# localhost:8080 Flutter web-server 준비 대기
# web-server 디버그 모드는 브라우저 첫 접속 시 컴파일이 끝나야 앱이 뜬다.
set -euo pipefail

PORT="${LOCAL_WEB_PORT:-8080}"
TRIES="${LOCAL_WEB_WAIT_TRIES:-90}"
WARMUP_SEC="${LOCAL_WEB_WARMUP_SEC:-18}"

html_ready() {
  curl -sf "http://127.0.0.1:$PORT/" >/dev/null 2>&1
}

js_ready() {
  curl -sf "http://127.0.0.1:$PORT/flutter_bootstrap.js" >/dev/null 2>&1 \
    && curl -sf "http://127.0.0.1:$PORT/main.dart.js" >/dev/null 2>&1
}

warmup_compile() {
  # 첫 HTTP 요청으로 컴파일을 시작시키고, 완료될 때까지 대기
  curl -sf "http://127.0.0.1:$PORT/admin" >/dev/null 2>&1 || true
  curl -sf "http://127.0.0.1:$PORT/flutter_bootstrap.js" >/dev/null 2>&1 || true
  curl -sf "http://127.0.0.1:$PORT/main.dart.js" >/dev/null 2>&1 || true
  sleep "$WARMUP_SEC"
}

for _ in $(seq 1 "$TRIES"); do
  if html_ready && js_ready; then
    warmup_compile
    exit 0
  fi
  sleep 2
done

echo "로컬 서버(http://127.0.0.1:$PORT) 준비 시간 초과" >&2
exit 1
