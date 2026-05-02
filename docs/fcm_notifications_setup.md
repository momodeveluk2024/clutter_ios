# FCM Notifications Setup

The app uses Firebase Cloud Messaging only as the push delivery pipe. Auth, users, preferences, recommendations, and notification history stay in the Go backend and PostgreSQL.

## Android

1. In Firebase, add an Android app with package ID `com.nutrimate.app`.
2. Download `google-services.json`.
3. Put it at `android/app/google-services.json`.
4. Rebuild the app. The Google Services Gradle plugin is applied only when this file exists, so local tests can still run before setup.

## Backend

1. Create/download a Firebase service-account JSON with permission to send FCM messages.
2. Put it somewhere outside git, for example `backend/firebase-service-account.local.json`.
3. Set:

```env
FIREBASE_CREDENTIALS_FILE=backend/firebase-service-account.local.json
PUSH_SCHEDULER_ENABLED=true
NOTIFICATION_JOB_INTERVAL=1h
```

If `FIREBASE_CREDENTIALS_FILE` is empty, the backend keeps using the development logger sender instead of real FCM.

## Database

Run migrations after deploying:

```powershell
cd backend
go run ./cmd/migrate up
```

The new migration creates `push_devices`, `notification_preferences`, and `notification_events`.
