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

echo ""
echo "매니저 로컬 실행 (Chrome)..."
echo "  홈:     http://localhost:<포트>/"
echo "  관리자: http://localhost:<포트>/admin"
echo "  종료:   q"
echo ""

flutter run -d chrome
