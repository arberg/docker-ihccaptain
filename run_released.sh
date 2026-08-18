#!/usr/bin/env bash
set -e

BASE_DIR="$(cd "$(dirname "$0")" && pwd -P)"
"$BASE_DIR/run.sh" "arberg/ihccaptain:$(cat "$BASE_DIR/VERSION")"
