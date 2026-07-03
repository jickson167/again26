#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if [[ ! -f env.json ]]; then
  echo "env.json 없음. 아래 중 하나를 하세요:"
  echo "  cp env.example.json env.json   # 후에 Supabase URL·키 입력"
  echo "  또는 generator_config.js 내용을 env.json 형식으로 복사"
  exit 1
fi

python3 <<'PY'
import json
from pathlib import Path

root = Path(".")
cfg = json.loads(root.joinpath("env.json").read_text(encoding="utf-8"))
url = cfg.get("SUPABASE_URL", "").strip()
key = cfg.get("SUPABASE_ANON_KEY", "").strip()
if not url or not key or "YOUR_" in url or "YOUR_" in key:
    raise SystemExit("env.json에 SUPABASE_URL / SUPABASE_ANON_KEY를 설정하세요.")

content = (
    "window.AGAIN26_CONFIG = {\n"
    f"  SUPABASE_URL: {json.dumps(url)},\n"
    f"  SUPABASE_ANON_KEY: {json.dumps(key)},\n"
    "};\n"
)
root.joinpath("web/env.js").write_text(content, encoding="utf-8")
print("web/env.js ← env.json 동기화 완료")
PY
