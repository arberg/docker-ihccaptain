#!/usr/bin/env bash
set -e

BASE_DIR="$(cd "$(dirname "$0")" && pwd -P)"
cd "$BASE_DIR"

if [[ -n "${1:-}" ]]; then
  IHCCAPTAIN_IMAGE="$1" docker compose up -d ihccaptain
else
  docker compose up -d ihccaptain
fi
