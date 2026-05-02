package db

import (
	"context"
	"encoding/json"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

type Store struct {
	pool *pgxpool.Pool
}

func Open(ctx context.Context, databaseURL string) (*pgxpool.Pool, error) {
	pool, err := pgxpool.New(ctx, databaseURL)
	if err != nil {
		return nil, err
	}
	if err := pool.Ping(ctx); err != nil {
		pool.Close()
		return nil, err
	}
	return pool, nil
}

func NewStore(pool *pgxpool.Pool) *Store {
	return &Store{pool: pool}
}

func (s *Store) Ping(ctx context.Context) error {
	return s.pool.Ping(ctx)
}

type User struct {
	ID              uuid.UUID  `json:"id"`
	Email           string     `json:"email"`
	Role            string     `json:"role"`
	PasswordHash    string     `json:"-"`
	EmailVerifiedAt *time.Time `json:"email_verified_at,omitempty"`
	CreatedAt       time.Time  `json:"created_at"`
	UpdatedAt       time.Time  `json:"updated_at"`
	SuspendedAt     *time.Time `json:"suspended_at,omitempty"`
	DeletedAt       *time.Time `json:"deleted_at,omitempty"`
}

type Profile struct {
	UserID                uuid.UUID       `json:"user_id"`
	DisplayName           string          `json:"display_name"`
	AvatarURL             *string         `json:"avatar_url,omitempty"`
	Sex                   *string         `json:"sex,omitempty"`
	DateOfBirth           *string         `json:"date_of_birth,omitempty"`
	HeightCM              *float64        `json:"height_cm,omitempty"`
	WeightKG              *float64        `json:"weight_kg,omitempty"`
	ActivityLevel         *string         `json:"activity_level,omitempty"`
	PregnancyStatus       *string         `json:"pregnancy_status,omitempty"`
	DietaryPattern        *string         `json:"dietary_pattern,omitempty"`
	Allergens             []string        `json:"allergens"`
	Goals                 []string        `json:"goals"`
	Units                 string          `json:"units"`
	Locale                string          `json:"locale"`
	Timezone              string          `json:"timezone"`
	Preferences           json.RawMessage `json:"preferences"`
	OnboardingCompletedAt *time.Time      `json:"onboarding_completed_at,omitempty"`
	NeedsOnboarding       bool            `json:"needs_onboarding"`
	CreatedAt             time.Time       `json:"created_at"`
	UpdatedAt             time.Time       `json:"updated_at"`
}

type Session struct {
	ID        uuid.UUID `json:"id"`
	UserID    uuid.UUID `json:"user_id"`
	ExpiresAt time.Time `json:"expires_at"`
	CreatedAt time.Time `json:"created_at"`
}

type Me struct {
	ID                    uuid.UUID       `json:"id"`
	Email                 string          `json:"email"`
	Role                  string          `json:"role"`
	EmailVerifiedAt       *time.Time      `json:"email_verified_at,omitempty"`
	CreatedAt             time.Time       `json:"created_at"`
	DisplayName           string          `json:"display_name"`
	AvatarURL             *string         `json:"avatar_url,omitempty"`
	Sex                   *string         `json:"sex,omitempty"`
	DateOfBirth           *string         `json:"date_of_birth,omitempty"`
	HeightCM              *float64        `json:"height_cm,omitempty"`
	WeightKG              *float64        `json:"weight_kg,omitempty"`
	ActivityLevel         *string         `json:"activity_level,omitempty"`
	PregnancyStatus       *string         `json:"pregnancy_status,omitempty"`
	DietaryPattern        *string         `json:"dietary_pattern,omitempty"`
	Allergens             []string        `json:"allergens"`
	Goals                 []string        `json:"goals"`
	Units                 string          `json:"units"`
	Locale                string          `json:"locale"`
	Timezone              string          `json:"timezone"`
	Preferences           json.RawMessage `json:"preferences"`
	OnboardingCompletedAt *time.Time      `json:"onboarding_completed_at,omitempty"`
	NeedsOnboarding       bool            `json:"needs_onboarding"`
}

type CreateUserParams struct {
	ID           uuid.UUID
	Email        string
	PasswordHash string
	DisplayName  string
}

func (s *Store) CreateUserWithProfile(ctx context.Context, params CreateUserParams) (User, Profile, error) {
	tx, err := s.pool.BeginTx(ctx, pgx.TxOptions{})
	if err != nil {
		return User{}, Profile{}, err
	}
	defer tx.Rollback(ctx)

	var user User
	err = tx.QueryRow(ctx, `
		INSERT INTO users (id, email, password_hash)
		VALUES ($1, $2, $3)
		RETURNING id, email, role, password_hash, email_verified_at, created_at, updated_at
	`, params.ID, params.Email, params.PasswordHash).Scan(
		&user.ID,
		&user.Email,
		&user.Role,
		&user.PasswordHash,
		&user.EmailVerifiedAt,
		&user.CreatedAt,
		&user.UpdatedAt,
	)
	if err != nil {
		return User{}, Profile{}, err
	}

	var profile Profile
	err = tx.QueryRow(ctx, `
		INSERT INTO user_profiles (user_id, display_name)
		VALUES ($1, $2)
		RETURNING user_id, display_name, units, locale, timezone, preferences, created_at, updated_at
	`, params.ID, params.DisplayName).Scan(
		&profile.UserID,
		&profile.DisplayName,
		&profile.Units,
		&profile.Locale,
		&profile.Timezone,
		&profile.Preferences,
		&profile.CreatedAt,
		&profile.UpdatedAt,
	)
	if err != nil {
		return User{}, Profile{}, err
	}

	if err := tx.Commit(ctx); err != nil {
		return User{}, Profile{}, err
	}

	return user, profile, nil
}

func (s *Store) GetUserByEmail(ctx context.Context, email string) (User, error) {
	var user User
	err := s.pool.QueryRow(ctx, `
		SELECT id, email, role, password_hash, email_verified_at, created_at, updated_at, suspended_at, deleted_at
		FROM users
		WHERE email = $1 AND deleted_at IS NULL AND suspended_at IS NULL
	`, email).Scan(
		&user.ID,
		&user.Email,
		&user.Role,
		&user.PasswordHash,
		&user.EmailVerifiedAt,
		&user.CreatedAt,
		&user.UpdatedAt,
		&user.SuspendedAt,
		&user.DeletedAt,
	)
	return user, err
}

func (s *Store) GetUserByID(ctx context.Context, id uuid.UUID) (User, error) {
	var user User
	err := s.pool.QueryRow(ctx, `
		SELECT id, email, role, password_hash, email_verified_at, created_at, updated_at, suspended_at, deleted_at
		FROM users
		WHERE id = $1 AND deleted_at IS NULL AND suspended_at IS NULL
	`, id).Scan(
		&user.ID,
		&user.Email,
		&user.Role,
		&user.PasswordHash,
		&user.EmailVerifiedAt,
		&user.CreatedAt,
		&user.UpdatedAt,
		&user.SuspendedAt,
		&user.DeletedAt,
	)
	return user, err
}

func (s *Store) GetUserByFirebaseUID(ctx context.Context, firebaseUID string) (User, error) {
	var user User
	err := s.pool.QueryRow(ctx, `
		SELECT id, email, role, password_hash, email_verified_at, created_at, updated_at, suspended_at, deleted_at
		FROM users
		WHERE firebase_uid = $1 AND deleted_at IS NULL AND suspended_at IS NULL
	`, firebaseUID).Scan(
		&user.ID,
		&user.Email,
		&user.Role,
		&user.PasswordHash,
		&user.EmailVerifiedAt,
		&user.CreatedAt,
		&user.UpdatedAt,
		&user.SuspendedAt,
		&user.DeletedAt,
	)
	return user, err
}

type CreateFirebaseUserParams struct {
	ID              uuid.UUID
	Email           string
	FirebaseUID     string
	EmailVerifiedAt *time.Time
}

func (s *Store) CreateFirebaseUser(ctx context.Context, params CreateFirebaseUserParams) (User, error) {
	var user User
	err := s.pool.QueryRow(ctx, `
		INSERT INTO users (id, email, firebase_uid, email_verified_at)
		VALUES ($1, $2, $3, $4)
		RETURNING id, email, role, password_hash, email_verified_at, created_at, updated_at
	`, params.ID, params.Email, params.FirebaseUID, params.EmailVerifiedAt).Scan(
		&user.ID,
		&user.Email,
		&user.Role,
		&user.PasswordHash,
		&user.EmailVerifiedAt,
		&user.CreatedAt,
		&user.UpdatedAt,
	)
	return user, err
}

type LinkFirebaseUserParams struct {
	ID              uuid.UUID
	FirebaseUID     string
	EmailVerifiedAt *time.Time
}

func (s *Store) LinkFirebaseUser(ctx context.Context, params LinkFirebaseUserParams) (User, error) {
	var user User
	err := s.pool.QueryRow(ctx, `
		UPDATE users
		SET firebase_uid = $2,
		    email_verified_at = COALESCE(users.email_verified_at, $3),
		    updated_at = now()
		WHERE id = $1 AND deleted_at IS NULL
		RETURNING id, email, role, password_hash, email_verified_at, created_at, updated_at
	`, params.ID, params.FirebaseUID, params.EmailVerifiedAt).Scan(
		&user.ID,
		&user.Email,
		&user.Role,
		&user.PasswordHash,
		&user.EmailVerifiedAt,
		&user.CreatedAt,
		&user.UpdatedAt,
	)
	return user, err
}

type CreateUserProfileParams struct {
	UserID      uuid.UUID
	DisplayName string
}

func (s *Store) CreateUserProfile(ctx context.Context, params CreateUserProfileParams) (Profile, error) {
	var profile Profile
	err := s.pool.QueryRow(ctx, `
		INSERT INTO user_profiles (user_id, display_name)
		VALUES ($1, $2)
		RETURNING user_id, display_name, units, locale, timezone, preferences, created_at, updated_at
	`, params.UserID, params.DisplayName).Scan(
		&profile.UserID,
		&profile.DisplayName,
		&profile.Units,
		&profile.Locale,
		&profile.Timezone,
		&profile.Preferences,
		&profile.CreatedAt,
		&profile.UpdatedAt,
	)
	return profile, err
}

func (s *Store) CreateSession(ctx context.Context, sessionID, userID uuid.UUID, refreshHash []byte, userAgent, ip string, expiresAt time.Time) (Session, error) {
	var session Session
	err := s.pool.QueryRow(ctx, `
		INSERT INTO sessions (id, user_id, refresh_token_hash, user_agent, ip, expires_at)
		VALUES ($1, $2, $3, $4, NULLIF($5, '')::inet, $6)
		RETURNING id, user_id, expires_at, created_at
	`, sessionID, userID, refreshHash, userAgent, ip, expiresAt).Scan(
		&session.ID,
		&session.UserID,
		&session.ExpiresAt,
		&session.CreatedAt,
	)
	return session, err
}

func (s *Store) GetActiveSessionByRefreshHash(ctx context.Context, refreshHash []byte) (Session, error) {
	var session Session
	err := s.pool.QueryRow(ctx, `
		SELECT id, user_id, expires_at, created_at
		FROM sessions
		WHERE refresh_token_hash = $1
		  AND revoked_at IS NULL
		  AND expires_at > now()
	`, refreshHash).Scan(&session.ID, &session.UserID, &session.ExpiresAt, &session.CreatedAt)
	return session, err
}

func (s *Store) GetActiveSessionByID(ctx context.Context, sessionID uuid.UUID) (Session, error) {
	var session Session
	err := s.pool.QueryRow(ctx, `
		SELECT id, user_id, expires_at, created_at
		FROM sessions
		WHERE id = $1
		  AND revoked_at IS NULL
		  AND expires_at > now()
	`, sessionID).Scan(&session.ID, &session.UserID, &session.ExpiresAt, &session.CreatedAt)
	return session, err
}

func (s *Store) RotateSession(ctx context.Context, sessionID uuid.UUID, refreshHash []byte, expiresAt time.Time) (Session, error) {
	var session Session
	err := s.pool.QueryRow(ctx, `
		UPDATE sessions
		SET refresh_token_hash = $2,
		    expires_at = $3
		WHERE id = $1
		  AND revoked_at IS NULL
		  AND expires_at > now()
		RETURNING id, user_id, expires_at, created_at
	`, sessionID, refreshHash, expiresAt).Scan(&session.ID, &session.UserID, &session.ExpiresAt, &session.CreatedAt)
	return session, err
}

func (s *Store) RevokeSession(ctx context.Context, sessionID uuid.UUID) error {
	_, err := s.pool.Exec(ctx, `
		UPDATE sessions
		SET revoked_at = now()
		WHERE id = $1 AND revoked_at IS NULL
	`, sessionID)
	return err
}

func (s *Store) SetUserRole(ctx context.Context, userID uuid.UUID, role string) error {
	_, err := s.pool.Exec(ctx, `
		UPDATE users
		SET role = $2,
		    updated_at = now()
		WHERE id = $1 AND deleted_at IS NULL
	`, userID, role)
	return err
}

func (s *Store) CreateEmailVerification(ctx context.Context, userID uuid.UUID, tokenHash []byte, expiresAt time.Time) error {
	_, err := s.pool.Exec(ctx, `
		INSERT INTO email_verifications (user_id, token_hash, expires_at)
		VALUES ($1, $2, $3)
	`, userID, tokenHash, expiresAt)
	return err
}

func (s *Store) VerifyEmailToken(ctx context.Context, tokenHash []byte) (uuid.UUID, error) {
	tx, err := s.pool.BeginTx(ctx, pgx.TxOptions{})
	if err != nil {
		return uuid.Nil, err
	}
	defer tx.Rollback(ctx)

	var userID uuid.UUID
	err = tx.QueryRow(ctx, `
		UPDATE email_verifications
		SET used_at = now()
		WHERE token_hash = $1
		  AND used_at IS NULL
		  AND expires_at > now()
		RETURNING user_id
	`, tokenHash).Scan(&userID)
	if err != nil {
		return uuid.Nil, err
	}

	_, err = tx.Exec(ctx, `
		UPDATE users
		SET email_verified_at = COALESCE(email_verified_at, now()),
		    updated_at = now()
		WHERE id = $1
	`, userID)
	if err != nil {
		return uuid.Nil, err
	}

	if err := tx.Commit(ctx); err != nil {
		return uuid.Nil, err
	}
	return userID, nil
}

func (s *Store) CreatePasswordReset(ctx context.Context, userID uuid.UUID, tokenHash []byte, expiresAt time.Time) error {
	_, err := s.pool.Exec(ctx, `
		INSERT INTO password_resets (user_id, token_hash, expires_at)
		VALUES ($1, $2, $3)
	`, userID, tokenHash, expiresAt)
	return err
}

func (s *Store) ResetPassword(ctx context.Context, tokenHash []byte, passwordHash string) (uuid.UUID, error) {
	tx, err := s.pool.BeginTx(ctx, pgx.TxOptions{})
	if err != nil {
		return uuid.Nil, err
	}
	defer tx.Rollback(ctx)

	var userID uuid.UUID
	err = tx.QueryRow(ctx, `
		UPDATE password_resets
		SET used_at = now()
		WHERE token_hash = $1
		  AND used_at IS NULL
		  AND expires_at > now()
		RETURNING user_id
	`, tokenHash).Scan(&userID)
	if err != nil {
		return uuid.Nil, err
	}

	_, err = tx.Exec(ctx, `
		UPDATE users
		SET password_hash = $2,
		    updated_at = now()
		WHERE id = $1
	`, userID, passwordHash)
	if err != nil {
		return uuid.Nil, err
	}

	_, err = tx.Exec(ctx, `UPDATE sessions SET revoked_at = now() WHERE user_id = $1 AND revoked_at IS NULL`, userID)
	if err != nil {
		return uuid.Nil, err
	}

	if err := tx.Commit(ctx); err != nil {
		return uuid.Nil, err
	}
	return userID, nil
}

func (s *Store) GetMe(ctx context.Context, userID uuid.UUID) (Me, error) {
	var me Me
	err := s.pool.QueryRow(ctx, `
		SELECT
		    u.id,
		    u.email,
		    u.role,
		    u.email_verified_at,
		    u.created_at,
		    p.display_name,
		    p.avatar_url,
		    p.sex,
		    to_char(p.date_of_birth, 'YYYY-MM-DD'),
		    p.height_cm::float8,
		    p.weight_kg::float8,
		    p.activity_level,
		    p.pregnancy_status,
		    p.dietary_pattern,
		    p.allergens,
		    p.goals,
		    p.units,
		    p.locale,
		    p.timezone,
		    p.preferences,
		    p.onboarding_completed_at,
		    p.onboarding_completed_at IS NULL
		FROM users u
		JOIN user_profiles p ON p.user_id = u.id
		WHERE u.id = $1 AND u.deleted_at IS NULL AND u.suspended_at IS NULL
	`, userID).Scan(
		&me.ID,
		&me.Email,
		&me.Role,
		&me.EmailVerifiedAt,
		&me.CreatedAt,
		&me.DisplayName,
		&me.AvatarURL,
		&me.Sex,
		&me.DateOfBirth,
		&me.HeightCM,
		&me.WeightKG,
		&me.ActivityLevel,
		&me.PregnancyStatus,
		&me.DietaryPattern,
		&me.Allergens,
		&me.Goals,
		&me.Units,
		&me.Locale,
		&me.Timezone,
		&me.Preferences,
		&me.OnboardingCompletedAt,
		&me.NeedsOnboarding,
	)
	return me, err
}
