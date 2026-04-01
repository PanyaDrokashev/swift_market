# Alfa ITMO Echo API

Публичная инструкция по использованию Echo API.

Базовый URL:
- `https://alfaitmo.ru`

Базовый маршрут:
- `/server/echo/*path`

`*path` — произвольный путь-ключ, например:
- `/server/echo/demo`
- `/server/echo/users/42/profile`

## Что делает API

- Сохраняет JSON по указанному пути (`POST` / `PUT` / `PATCH`).
- Возвращает последнюю сохранённую версию JSON по пути (`GET`).

## Методы

### `GET /server/echo/*path`
Возвращает последнюю версию JSON для пути.

Успех:
- `200 OK`
- Body: сохранённый JSON

Если путь не найден:
- `404 Not Found`
- Body:

```json
{
  "code": 404,
  "message": "echo record not found"
}
```

### `POST /server/echo/*path`
### `PUT /server/echo/*path`
### `PATCH /server/echo/*path`
Сохраняют новую версию JSON по пути.

Успех:
- `201 Created`
- Body: тот же JSON, который был отправлен

## Примеры

Сохранить JSON:

```bash
curl -X POST 'https://alfaitmo.ru/server/echo/demo' \
  -H 'Content-Type: application/json' \
  -d '{"hello":"world"}'
```

Получить JSON:

```bash
curl 'https://alfaitmo.ru/server/echo/demo'
```

Обновить JSON:

```bash
curl -X PUT 'https://alfaitmo.ru/server/echo/demo' \
  -H 'Content-Type: application/json' \
  -d '{"hello":"updated"}'
```

Использовать вложенный путь:

```bash
curl -X PATCH 'https://alfaitmo.ru/server/echo/users/42/profile' \
  -H 'Content-Type: application/json' \
  -d '{"name":"Alice"}'
```

## Ограничения и особенности

- API не требует авторизации.
- При каждом сохранении создаётся новая версия записи.
- Возвращается только текущая (последняя) версия.
- История хранится на стороне сервера и может быть ограничена настройками.

## OpenAPI

Спецификация:
- `openapi.yaml`
