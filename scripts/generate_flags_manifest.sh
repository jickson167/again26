#!/usr/bin/env bash
# web/flags/*.png|jpg 목록 → manifest.json (국기 매핑 툴용)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FLAGS_DIR="$ROOT/web/flags"
OUT="$FLAGS_DIR/manifest.json"

if [[ ! -d "$FLAGS_DIR" ]]; then
  echo "web/flags 없음"
  exit 1
fi

python3 <<PY
import json
from pathlib import Path

flags_dir = Path("$FLAGS_DIR")
files = sorted(
    p.name
    for p in flags_dir.iterdir()
    if p.is_file() and p.suffix.lower() in {".png", ".jpg", ".jpeg", ".webp"}
    and p.name.startswith("flags_")
)
manifest = {
    "version": 1,
    "count": len(files),
    "files": files,
}
Path("$OUT").write_text(
    json.dumps(manifest, ensure_ascii=False, indent=2) + "\n",
    encoding="utf-8",
)
print(f"web/flags/manifest.json ← {len(files)}개 국기")
PY
