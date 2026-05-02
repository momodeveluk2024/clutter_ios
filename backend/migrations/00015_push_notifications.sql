-- +goose Up
CREATE TABLE push_devices (
    id uuid PRIMARY KEY,
    user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    device_id uuid NOT NULL,
    fcm_token text NOT NULL,
    platform text NOT NULL CHECK (platform IN ('android', 'ios', 'web')),
    app_version text NOT NULL DEFAULT '',
    locale text NOT NULL DEFAULT 'en',
    timezone text NOT NULL DEFAULT 'UTC',
    enabled boolean NOT NULL DEFAULT true,
    last_seen_at timestamptz NOT NULL DEFAULT now(),
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (user_id, device_id)
);

CREATE TABLE notification_preferences (
    user_id uuid PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    recommendation_push_enabled boolean NOT NULL DEFAULT true,
    weekly_summary_push_enabled boolean NOT NULL DEFAULT true,
    ai_insights_push_enabled boolean NOT NULL DEFAULT false,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE notification_events (
    id uuid PRIMARY KEY,
    user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    device_id uuid REFERENCES push_devices(id) ON DELETE SET NULL,
    notification_type text NOT NULL,
    title text NOT NULL,
    body text NOT NULL DEFAULT '',
    data jsonb NOT NULL DEFAULT '{}'::jsonb,
    status text NOT NULL CHECK (status IN ('sent', 'failed', 'opened')),
    error text,
    sent_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX push_devices_user_enabled_idx ON push_devices(user_id) WHERE enabled;
CREATE INDEX notification_events_user_type_created_idx ON notification_events(user_id, notification_type, created_at DESC);
CREATE INDEX notification_events_device_created_idx ON notification_events(device_id, created_at DESC);

-- +goose Down
DROP TABLE IF EXISTS notification_events;
DROP TABLE IF EXISTS notification_preferences;
DROP TABLE IF EXISTS push_devices;
