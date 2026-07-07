#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
bash "$DIR/_ensure_server.sh"

URL="http://localhost:8080/"
if open -a "Google Chrome" "$URL" 2>/dev/null; then
  :
else
  open "$URL"
fi
