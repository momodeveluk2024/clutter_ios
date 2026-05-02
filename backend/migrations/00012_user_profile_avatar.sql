-- +goose Up
ALTER TABLE user_profiles
    ADD COLUMN avatar_url text;

-- +goose Down
ALTER TABLE user_profiles
    DROP COLUMN IF EXISTS avatar_url;
