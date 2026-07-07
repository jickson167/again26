#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

if [[ ! -f env.json ]]; then
  if [[ -f generator_config.js ]]; then
    python3 <<'PY'
import json, re
from pathlib import Path

text = Path("generator_config.js").read_text(encoding="utf-8")
url = re.search(r"SUPABASE_URL:\s*'([^']*)'", text)
key = re.search(r"SUPABASE_ANON_KEY:\s*'([^']*)'", text)
if not url or not key:
    raise SystemExit("generator_config.js에서 Supabase 설정을 찾을 수 없습니다.")
Path("env.json").write_text(
    json.dumps(
        {"SUPABASE_URL": url.group(1), "SUPABASE_ANON_KEY": key.group(1)},
        indent=2,
    )
    + "\n",
    encoding="utf-8",
)
print("env.json ← generator_config.js 생성 완료")
PY
  else
    echo "env.json / generator_config.js 없음."
    exit 1
  fi
fi

bash scripts/write_web_env.sh
bash scripts/sync_web_tools.sh

SUPABASE_URL="$(python3 -c "import json; print(json.load(open('env.json'))['SUPABASE_URL'])")"
SUPABASE_ANON_KEY="$(python3 -c "import json; print(json.load(open('env.json'))['SUPABASE_ANON_KEY'])")"

if lsof -ti :8080 >/dev/null 2>&1; then
  echo "8080 포트 사용 중 → 이전 Flutter 프로세스 종료"
  lsof -ti :8080 | xargs kill -9 2>/dev/null || true
  sleep 1
fi

LOCAL_OPEN_URL="${LOCAL_OPEN_URL:-http://localhost:8080/admin}"

echo ""
echo "Again26 로컬 서버 실행..."
echo "  서버만 띄우고, 평소 쓰는 Chrome으로 매니저 페이지를 엽니다."
echo "  매니저: http://localhost:8080/admin"
echo "  게임:   http://localhost:8080/"
echo "  종료:   터미널에서 q"
echo ""

if [[ "${AGAIN26_SKIP_BROWSER:-0}" != "1" ]]; then
  (
    bash scripts/wait_for_local_server.sh
    bash scripts/open_local_url.sh "$LOCAL_OPEN_URL"
  ) &
fi

flutter run -d web-server --web-port 8080 \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY"
