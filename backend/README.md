# NutriVita Backend

Go + PostgreSQL backend for the Flutter app. It currently covers the MVP backend surface for auth, food catalog, meal logging, favorites, reminders, recommendations, migrations, local Postgres, Docker, and CI.

## Local setup

```powershell
cd backend
Copy-Item .env.example .env
docker compose up -d
go run ./cmd/migrate up
go run ./cmd/api
```

The API listens on `http://localhost:8080`.

## Routes

- `GET /health`
- `GET /ready`
- `POST /v1/auth/signup`
- `POST /v1/auth/login`
- `POST /v1/auth/refresh`
- `POST /v1/auth/verify-email`
- `POST /v1/auth/forgot-password`
- `POST /v1/auth/reset-password`
- `POST /v1/auth/logout`
- `GET /v1/me`
- `PATCH /v1/me/profile`
- `POST /v1/me/avatar`
- `PATCH /v1/me/preferences`
- `PATCH /v1/me/onboarding/complete`
- `GET /v1/me/streak`
- `GET /v1/foods?q=&category=&limit=`
- `GET /v1/foods/barcode/{barcode}`
- `GET /v1/foods/{foodID}`
- `POST /v1/foods`
- `GET /v1/logs?from=&to=`
- `POST /v1/logs`
- `DELETE /v1/logs/{logID}`
- `GET /v1/logs/today/intake?date=`
- `GET /v1/logs/week?date=`
- `GET /v1/favorites`
- `PUT /v1/favorites/{foodID}`
- `DELETE /v1/favorites/{foodID}`
- `GET /v1/reminders`
- `POST /v1/reminders`
- `DELETE /v1/reminders/{reminderID}`
- `GET /v1/recommendations?date=`
- `GET /metrics`

## Production gaps

- Email verification and password reset are local/dev token flows that log tokens to stdout; no SMTP provider is wired yet.
- Food data is a small seed catalog plus an offline CSV importer scaffold in `cmd/usda-import`.
- Reminder scheduling and push notifications use local stubs until real providers are chosen.
- Dockerfile, compose API profile, backup scripts, metrics, and CI exist, but no live VPS/Fly/Railway deployment has been applied yet.
- Observability includes request logging and basic Prometheus-compatible counters; tracing and Sentry are not wired yet.

## Tests

```powershell
go test ./...
```

Integration tests that use Testcontainers are present but opt-in:

```powershell
$env:NUTRIVITA_RUN_INTEGRATION="1"
go test ./internal/server -run Integration
```
