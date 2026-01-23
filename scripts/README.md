# Скрипты и их назначение

Эти скрипты нужны для корректных прав доступа при работе с Bitrix в Docker.
Мы используем bindfs, чтобы контейнеры всегда видели файлы как `bitrix:bitrix`.

## Зачем это нужно

- Контейнеры Bitrix создают файлы от имени `bitrix`.
- Если редактировать код напрямую на хосте, права могут «плыть».
- bindfs даёт единый вид прав: владельцы и группы корректны для контейнеров.

## Скрипты

### `mount-www-bindfs.sh`

Монтирует `www/` в `www-bindfs/` через bindfs:
- проверяет `user_allow_other` в `/etc/fuse.conf`;
- создаёт каталог `www-bindfs/`, если его нет;
- монтирует с владельцем `bitrix:bitrix` и правами 664/2775.

Запуск:
```bash
sudo scripts/mount-www-bindfs.sh
```

### `umount-www-bindfs.sh`

Отмонтирует `www-bindfs/`:
```bash
sudo scripts/umount-www-bindfs.sh
```

## Где править код

Работайте **только** в `www-bindfs/`. Это та же кодовая база, но с корректными правами.
Каталог `www/` — источник данных, но если редактировать там, bindfs не влияет на права.

## Быстрый старт

```bash
cd "/home/user/Рабочий стол/bitrix-docker-env"
sudo scripts/mount-www-bindfs.sh
docker-compose up -d
```
