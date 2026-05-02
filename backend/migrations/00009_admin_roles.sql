-- +goose Up
ALTER TABLE users
    ADD COLUMN role text NOT NULL DEFAULT 'user'
    CHECK (role IN ('user', 'admin'));

CREATE INDEX users_role_idx ON users(role);

UPDATE users
SET role = 'admin'
WHERE lower(email::text) IN ('admin@nv.app', 'jane@nv.app');

-- +goose Down
DROP INDEX IF EXISTS users_role_idx;
ALTER TABLE users
    DROP COLUMN IF EXISTS role;
