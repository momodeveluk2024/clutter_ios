-- +goose Up
ALTER TABLE users ADD COLUMN IF NOT EXISTS suspended_at timestamptz;

CREATE TABLE IF NOT EXISTS reminder_templates (
    id uuid PRIMARY KEY,
    title text NOT NULL,
    body text NOT NULL DEFAULT '',
    trigger text NOT NULL,
    audience text NOT NULL DEFAULT 'all',
    sent_7d integer NOT NULL DEFAULT 0 CHECK (sent_7d >= 0),
    active boolean NOT NULL DEFAULT true,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS users_suspended_idx ON users(suspended_at) WHERE suspended_at IS NOT NULL;
CREATE INDEX IF NOT EXISTS reminder_templates_active_idx ON reminder_templates(active);

INSERT INTO reminder_templates (id, title, body, trigger, audience, sent_7d, active) VALUES
('018f0000-0000-7000-8004-000000000001', 'Log breakfast', 'Time to log breakfast.', 'Daily 09:00 local', 'all', 0, true),
('018f0000-0000-7000-8004-000000000002', 'Vitamin D gap', 'You have had low Vitamin D today.', 'If D < 25% by 18:00', 'all', 0, true)
ON CONFLICT (id) DO NOTHING;

-- +goose Down
DROP TABLE IF EXISTS reminder_templates;
ALTER TABLE users DROP COLUMN IF EXISTS suspended_at;
