# Инструкция по настройке окружения

## Важно! Секретные файлы

Перед первым запуском необходимо настроить секретные файлы с паролями и ключами.

### 1. Настройка паролей баз данных (.env_sql)

Скопируйте шаблон и настройте пароли:

```bash
cp .env_sql.example .env_sql
```

**Обязательно сгенерируйте уникальные пароли!**

Для MySQL:
```bash
docker container run --rm --name mysql_password_generate alpine:3.22 sh -c "(cat /dev/urandom | tr -dc A-Za-z0-9\?\!\@\-\_\+\%\(\)\{\}\[\]\= | head -c 16) | tr -d '\' | tr -d '^' && echo ''"
```

Для PostgreSQL:
```bash
docker container run --rm --name postgresql_password_generate alpine:3.22 sh -c "(cat /dev/urandom | tr -dc A-Za-z0-9\?\!\@\-\_\+\%\(\)\{\}\[\]\= | head -c 16) | tr -d '\' | tr -d '^' && echo ''"
```

Замените в файле `.env_sql`:
- `CHANGE_MYSQL_ROOT_PASSWORD_HERE` на сгенерированный пароль MySQL
- `CHANGE_POSTGRESQL_POSTGRES_PASSWORD_HERE` на сгенерированный пароль PostgreSQL

### 2. Настройка секретного ключа Push-сервера (.env_push)

Скопируйте шаблон и настройте ключ:

```bash
cp .env_push.example .env_push
```

**Обязательно сгенерируйте уникальный секретный ключ!**

```bash
docker container run --rm --name push_server_key_generate alpine:3.22 sh -c "(cat /dev/urandom | tr -dc A-Za-z0-9 | head -c 128) && echo ''"
```

Замените в файле `.env_push`:
- `CHANGE_SECURITY_KEY_HERE` на сгенерированный ключ (128 символов)

## Запуск проекта

После настройки всех секретных файлов:

```bash
docker-compose up -d
```

## Безопасность

⚠️ **НИКОГДА не коммитьте в Git:**
- `.env_sql` - содержит пароли баз данных
- `.env_push` - содержит секретный ключ Push-сервера

Эти файлы автоматически исключены из Git через `.gitignore`.

Для других разработчиков используйте файлы `.example` как шаблоны.

