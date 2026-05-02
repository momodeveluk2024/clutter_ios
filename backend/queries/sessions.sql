-- name: CreateSession :one
INSERT INTO sessions (id, user_id, refresh_token_hash, user_agent, ip, expires_at)
VALUES ($1, $2, $3, $4, NULLIF($5, '')::inet, $6)
RETURNING id, user_id, expires_at, created_at;

-- name: GetActiveSessionByRefreshHash :one
SELECT id, user_id, expires_at, created_at
FROM sessions
WHERE refresh_token_hash = $1
  AND revoked_at IS NULL
  AND expires_at > now();

-- name: GetActiveSessionByID :one
SELECT id, user_id, expires_at, created_at
FROM sessions
WHERE id = $1
  AND revoked_at IS NULL
  AND expires_at > now();

-- name: RotateSession :one
UPDATE sessions
SET refresh_token_hash = $2,
    expires_at = $3
WHERE id = $1
  AND revoked_at IS NULL
  AND expires_at > now()
RETURNING id, user_id, expires_at, created_at;

-- name: RevokeSession :exec
UPDATE sessions
SET revoked_at = now()
WHERE id = $1 AND revoked_at IS NULL;
