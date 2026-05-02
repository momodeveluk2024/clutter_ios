-- name: CreateUser :one
INSERT INTO users (id, email, password_hash)
VALUES ($1, $2, $3)
RETURNING id, email, password_hash, email_verified_at, created_at, updated_at;

-- name: CreateUserProfile :one
INSERT INTO user_profiles (user_id, display_name)
VALUES ($1, $2)
RETURNING user_id, display_name, units, locale, timezone, preferences, created_at, updated_at;

-- name: GetUserByEmail :one
SELECT id, email, password_hash, email_verified_at, created_at, updated_at
FROM users
WHERE email = $1 AND deleted_at IS NULL;

-- name: GetUserByID :one
SELECT id, email, password_hash, email_verified_at, created_at, updated_at
FROM users
WHERE id = $1 AND deleted_at IS NULL;

-- name: GetMe :one
SELECT
    u.id,
    u.email,
    u.email_verified_at,
    u.created_at,
    p.display_name,
    p.units,
    p.locale,
    p.timezone,
    p.preferences
FROM users u
JOIN user_profiles p ON p.user_id = u.id
WHERE u.id = $1 AND u.deleted_at IS NULL;

-- name: GetUserByFirebaseUID :one
SELECT id, email, password_hash, firebase_uid, email_verified_at, created_at, updated_at
FROM users
WHERE firebase_uid = $1 AND deleted_at IS NULL;

-- name: CreateFirebaseUser :one
INSERT INTO users (id, email, firebase_uid, email_verified_at)
VALUES ($1, $2, $3, $4)
RETURNING id, email, password_hash, firebase_uid, email_verified_at, created_at, updated_at;

-- name: LinkFirebaseUser :one
UPDATE users
SET firebase_uid = $2,
    email_verified_at = COALESCE(users.email_verified_at, $3)
WHERE id = $1 AND deleted_at IS NULL
RETURNING id, email, password_hash, firebase_uid, email_verified_at, created_at, updated_at;
