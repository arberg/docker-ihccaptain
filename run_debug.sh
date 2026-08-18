#!/usr/bin/env bash
set -e

BASE_DIR="$(cd "$(dirname "$0")" && pwd -P)"
cd "$BASE_DIR"

docker compose stop ihccaptain
if [[ -n "${1:-}" ]]; then
  IHCCAPTAIN_DEBUG_IMAGE="$1" docker compose --profile debug run --rm --service-ports ihccaptain-debug
else
  docker compose --profile debug run --rm --service-ports ihccaptain-debug
fi
