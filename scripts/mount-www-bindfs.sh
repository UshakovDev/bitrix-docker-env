#!/usr/bin/env bash
set -euo pipefail

if [ "${EUID:-$(id -u)}" -ne 0 ]; then
  exec sudo "$0" "$@"
fi

if ! grep -qx "user_allow_other" /etc/fuse.conf 2>/dev/null; then
  echo "Добавьте строку 'user_allow_other' в /etc/fuse.conf и повторите запуск."
  exit 1
fi

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_DIR="$PROJECT_ROOT/www"
TARGET_DIR="$PROJECT_ROOT/www-bindfs"

if ! command -v bindfs >/dev/null 2>&1; then
  echo "bindfs не установлен. Установите пакет bindfs (sudo apt install bindfs) и повторите попытку."
  exit 1
fi

if [ ! -d "$SOURCE_DIR" ]; then
  echo "Каталог $SOURCE_DIR не найден."
  exit 1
fi

mkdir -p "$TARGET_DIR"

if mountpoint -q "$TARGET_DIR"; then
  echo "Каталог $TARGET_DIR уже смонтирован."
  exit 0
fi

echo "Монтируем $SOURCE_DIR в $TARGET_DIR через bindfs..."
bindfs \
  --force-user=bitrix \
  --force-group=bitrix \
  --create-with-perms=0664 \
  --create-for-user="$(logname)" \
  --create-for-group="$(id -gn "$(logname)")" \
  --chown-ignore \
  --chgrp-ignore \
  --chmod-ignore \
  --perms=a+X \
  -o allow_other \
  "$SOURCE_DIR" "$TARGET_DIR"

echo "Готово. Используйте docker-compose как обычно."

