-- +goose Up
ALTER TABLE users ADD COLUMN firebase_uid text UNIQUE;
ALTER TABLE users ALTER COLUMN password_hash DROP NOT NULL;

-- +goose Down
ALTER TABLE users DROP COLUMN firebase_uid;
ALTER TABLE users ALTER COLUMN password_hash SET NOT NULL;
