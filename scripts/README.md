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

## Переустановка Битрикс (чистая установка)

Если истёк пробный период или нужна новая установка:

1. **Отмонтировать** www-bindfs (чтобы спокойно чистить `www/`):
   ```bash
   cd "/home/user/Рабочий стол/bitrix-docker-env"
   sudo scripts/umount-www-bindfs.sh
   ```

2. **Очистить** каталог сайта (оставить только то, что нужно для установки):
   ```bash
   rm -rf www/*
   ```

3. **Положить скрипт установки** в `www/` одним из способов:
   - Скачать с хоста и скопировать:  
     `wget -O www/bitrixsetup.php https://www.1c-bitrix.ru/download/scripts/bitrixsetup.php`
   - Или смонтировать, зайти в контейнер и скачать там (см. README, раздел BitrixSetup).

4. **Снова смонтировать** и при необходимости перезапустить сервисы:
   ```bash
   sudo scripts/mount-www-bindfs.sh
   docker-compose restart php nginx cron
   ```

5. **Открыть в браузере** установщик:
   - https://localhost:8589/bitrixsetup.php (или http://localhost:8588/bitrixsetup.php)

6. В мастере установки при создании БД указать:
   - **MySQL:** хост `mysql`, пользователь `root`, пароль — из файла `.env_sql` (`MYSQL_ROOT_PASSWORD`).
   - **PostgreSQL:** хост `postgres`, пользователь `postgres`, пароль — из `.env_sql` (`POSTGRES_PASSWORD`).

### Удаление старой базы данных (перед переустановкой)

Базы MySQL и PostgreSQL в этом проекте работают **внутри Docker-контейнеров** (`dev_mysql`, `dev_postgres`). Удалять старую базу нужно именно из контейнера — с хоста к портам БД по умолчанию не проброшено. Ниже по шагам: как зайти в контейнер и удалить базу.

---

#### Как узнать имя базы, которую удалять

Имя базы, к которой привязан сайт, записано в конфиге Битрикс. Посмотреть его можно из контейнера `php`:

```bash
cd "/home/user/Рабочий стол/bitrix-docker-env"
docker-compose exec php cat /opt/www/bitrix/.settings.php
```

В выводе найдите блок `connections` → `value` → `default` → там будут `host`, `database`, `login`, `password`. Поле **`database`** — это имя базы (например `sitemanager`, `bitrix`). Его и нужно удалить в соответствующей СУБД.

---

#### MySQL: удаление базы из контейнера

Все команды выполняйте из каталога проекта. Пароль root для MySQL хранится в `.env_sql` в переменной `MYSQL_ROOT_PASSWORD`.

**Вариант 1 — интерактивно (зайти в контейнер и в консоль MySQL):**

1. Запустить оболочку внутри контейнера MySQL и открыть клиент `mysql` под пользователем `root`:

   ```bash
   docker-compose exec mysql bash -c "mysql -u root -p"
   ```

2. Когда контейнер запросит пароль — ввести пароль из `.env_sql` (значение `MYSQL_ROOT_PASSWORD`) и нажать Enter.

3. В приглашении MySQL (`mysql>`) выполнить по очереди:

   ```sql
   SHOW DATABASES;
   ```

   В списке найти базу Битрикс (например `sitemanager`, `bitrix`). **Не удалять** служебные: `information_schema`, `mysql`, `performance_schema`, `sys`.

4. Удалить выбранную базу (подставьте своё имя вместо `sitemanager`):

   ```sql
   DROP DATABASE sitemanager;
   ```

5. Выйти из клиента MySQL:

   ```sql
   exit
   ```

После этого вы окажетесь снова в своей обычной оболочке на хосте (контейнер завершит работу).

**Вариант 2 — одной командой с хоста (если имя базы уже известно):**

Подставьте вместо `ИМЯ_БАЗЫ` реальное имя и вместо `ВАШ_ПАРОЛЬ` — пароль из `.env_sql` (`MYSQL_ROOT_PASSWORD`). В кавычках пароль с спецсимволами указывайте как есть.

```bash
docker-compose exec -T mysql mysql -u root -p'ВАШ_ПАРОЛЬ' -e "DROP DATABASE ИМЯ_БАЗЫ;"
```

Пример (подставьте свой пароль из `.env_sql` и имя базы):

```bash
docker-compose exec -T mysql mysql -u root -p'ПАРОЛЬ_ИЗ_ENV_SQL' -e "DROP DATABASE sitemanager;"
```

Проверить, что база удалена:

```bash
docker-compose exec -T mysql mysql -u root -p'ВАШ_ПАРОЛЬ' -e "SHOW DATABASES;"
```

---

#### PostgreSQL: удаление базы из контейнера

Пароль пользователя `postgres` хранится в `.env_sql` в переменной `POSTGRES_PASSWORD`.

**Вариант 1 — интерактивно (зайти в контейнер и в консоль psql):**

1. Запустить клиент `psql` внутри контейнера от имени пользователя `postgres`:

   ```bash
   docker-compose exec --user=postgres postgres bash -c "psql"
   ```

   Если при первом запуске запросит пароль — ввести значение `POSTGRES_PASSWORD` из `.env_sql`.

2. В приглашении `psql` вывести список баз:

   ```sql
   \l
   ```

   Найти в списке базу Битрикс (по имени или по владельцу).

3. Удалить базу (подставьте своё имя вместо `имя_базы`):

   ```sql
   DROP DATABASE имя_базы;
   ```

   Если к базе есть подключения, сначала можно завершить их:  
   `SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = 'имя_базы';`  
   затем снова `DROP DATABASE имя_базы;`

4. Выйти из psql:

   ```sql
   \q
   ```

**Вариант 2 — одной командой с хоста:**

```bash
docker-compose exec -T --user=postgres postgres psql -c "DROP DATABASE ИМЯ_БАЗЫ;"
```

Подставьте реальное имя базы вместо `ИМЯ_БАЗЫ`. Пароль может запроситься (зависит от настройки `POSTGRES_HOST_AUTH_METHOD` в `.env_sql`).

---

После удаления базы в мастере bitrixsetup.php можно создать новую базу с тем же или другим именем — установщик создаст в ней таблицы заново.
