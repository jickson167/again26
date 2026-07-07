#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$DIR/../.." && pwd)"

bash "$DIR/_ensure_server.sh"
bash "$ROOT/scripts/open_local_url.sh" "http://localhost:8080/admin"
