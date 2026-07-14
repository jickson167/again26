#!/usr/bin/env bash
# 타이틀 로고 동기화:
#   assets/images/again26icon.png
#     → web/again26icon.png
#     → lib/assets/again26_title_logo.dart (임베드 바이트)
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT/assets/images/again26icon.png"
DST_WEB="$ROOT/web/again26icon.png"
DST_DART="$ROOT/lib/assets/again26_title_logo.dart"

if [[ ! -f "$SRC" ]]; then
  echo "없음: $SRC"
  exit 1
fi

python3 - <<PY
from PIL import Image
from pathlib import Path
import base64

src = Path("$SRC")
img = Image.open(src).convert("RGBA")
bg = Image.new("RGBA", img.size, (15, 23, 42, 255))
out = Image.alpha_composite(bg, img).convert("RGB")
out.save("$DST_WEB", format="PNG", optimize=True)
print("web/again26icon.png ← assets/images/again26icon.png")

# Flutter 웹 에셋/캐시와 무관하게 항상 보이게 임베드
raw = src.read_bytes()
b64 = base64.b64encode(raw).decode("ascii")
chunks = [b64[i : i + 76] for i in range(0, len(b64), 76)]
lines = "\n".join(f"  '{c}'" for c in chunks)
Path("$DST_DART").write_text(
    "// Generated from assets/images/again26icon.png — do not edit by hand.\n"
    "import 'dart:convert';\n"
    "import 'dart:typed_data';\n"
    "\n"
    "final Uint8List again26TitleLogoBytes = Uint8List.fromList(\n"
    "  base64Decode(\n"
    f"{lines}\n"
    "  ),\n"
    ");\n",
    encoding="utf-8",
)
print("lib/assets/again26_title_logo.dart ← assets/images/again26icon.png")
PY
