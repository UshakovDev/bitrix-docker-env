#!/usr/bin/env bash
set -euo pipefail

if [ "${EUID:-$(id -u)}" -ne 0 ]; then
  exec sudo "$0" "$@"
fi

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET_DIR="$PROJECT_ROOT/www-bindfs"

if mountpoint -q "$TARGET_DIR"; then
  echo "Отмонтируем $TARGET_DIR..."
  umount "$TARGET_DIR"
else
  echo "$TARGET_DIR не смонтирован."
fi
