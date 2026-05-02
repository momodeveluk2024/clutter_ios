-- +goose Up
ALTER TABLE user_profiles
    ADD COLUMN onboarding_completed_at timestamptz;

UPDATE user_profiles
SET onboarding_completed_at = now()
WHERE onboarding_completed_at IS NULL;

-- +goose Down
ALTER TABLE user_profiles
    DROP COLUMN IF EXISTS onboarding_completed_at;
