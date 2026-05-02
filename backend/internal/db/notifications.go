package db

import (
	"context"
	"encoding/json"
	"time"

	"github.com/google/uuid"
)

type PushDevice struct {
	ID         uuid.UUID `json:"id"`
	UserID     uuid.UUID `json:"user_id"`
	DeviceID   uuid.UUID `json:"device_id"`
	FCMToken   string    `json:"fcm_token"`
	Platform   string    `json:"platform"`
	AppVersion string    `json:"app_version"`
	Locale     string    `json:"locale"`
	Timezone   string    `json:"timezone"`
	Enabled    bool      `json:"enabled"`
	LastSeenAt time.Time `json:"last_seen_at"`
	CreatedAt  time.Time `json:"created_at"`
	UpdatedAt  time.Time `json:"updated_at"`
}

type RegisterPushDeviceParams struct {
	ID         uuid.UUID
	UserID     uuid.UUID
	DeviceID   uuid.UUID
	FCMToken   string
	Platform   string
	AppVersion string
	Locale     string
	Timezone   string
}

type NotificationPreferences struct {
	UserID                    uuid.UUID `json:"user_id"`
	RecommendationPushEnabled bool      `json:"recommendation_push_enabled"`
	WeeklySummaryPushEnabled  bool      `json:"weekly_summary_push_enabled"`
	AIInsightsPushEnabled     bool      `json:"ai_insights_push_enabled"`
	CreatedAt                 time.Time `json:"created_at"`
	UpdatedAt                 time.Time `json:"updated_at"`
}

type UpdateNotificationPreferencesParams struct {
	UserID                    uuid.UUID
	RecommendationPushEnabled *bool
	WeeklySummaryPushEnabled  *bool
	AIInsightsPushEnabled     *bool
}

type NotificationEventParams struct {
	ID               uuid.UUID
	UserID           uuid.UUID
	DeviceID         *uuid.UUID
	NotificationType string
	Title            string
	Body             string
	Data             map[string]string
	Status           string
	Error            *string
	SentAt           *time.Time
}

func (s *Store) RegisterPushDevice(ctx context.Context, params RegisterPushDeviceParams) (PushDevice, error) {
	var device PushDevice
	if _, err := s.pool.Exec(ctx, `
		INSERT INTO notification_preferences (user_id)
		VALUES ($1)
		ON CONFLICT (user_id) DO NOTHING
	`, params.UserID); err != nil {
		return PushDevice{}, err
	}
	err := s.pool.QueryRow(ctx, `
		INSERT INTO push_devices (id, user_id, device_id, fcm_token, platform, app_version, locale, timezone, enabled, last_seen_at)
		VALUES ($1, $2, $3, $4, $5, COALESCE(NULLIF($6, ''), ''), COALESCE(NULLIF($7, ''), 'en'), COALESCE(NULLIF($8, ''), 'UTC'), true, now())
		ON CONFLICT (user_id, device_id)
		DO UPDATE SET
		    fcm_token = EXCLUDED.fcm_token,
		    platform = EXCLUDED.platform,
		    app_version = EXCLUDED.app_version,
		    locale = EXCLUDED.locale,
		    timezone = EXCLUDED.timezone,
		    enabled = true,
		    last_seen_at = now(),
		    updated_at = now()
		RETURNING id, user_id, device_id, fcm_token, platform, app_version, locale, timezone, enabled, last_seen_at, created_at, updated_at
	`, params.ID, params.UserID, params.DeviceID, params.FCMToken, params.Platform, params.AppVersion, params.Locale, params.Timezone).Scan(
		&device.ID,
		&device.UserID,
		&device.DeviceID,
		&device.FCMToken,
		&device.Platform,
		&device.AppVersion,
		&device.Locale,
		&device.Timezone,
		&device.Enabled,
		&device.LastSeenAt,
		&device.CreatedAt,
		&device.UpdatedAt,
	)
	return device, err
}

func (s *Store) DisablePushDevice(ctx context.Context, userID, deviceID uuid.UUID) error {
	_, err := s.pool.Exec(ctx, `
		UPDATE push_devices
		SET enabled = false, updated_at = now()
		WHERE user_id = $1 AND device_id = $2
	`, userID, deviceID)
	return err
}

func (s *Store) ListActivePushDevices(ctx context.Context, userID uuid.UUID) ([]PushDevice, error) {
	rows, err := s.pool.Query(ctx, `
		SELECT id, user_id, device_id, fcm_token, platform, app_version, locale, timezone, enabled, last_seen_at, created_at, updated_at
		FROM push_devices
		WHERE user_id = $1 AND enabled
		ORDER BY last_seen_at DESC
	`, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	devices := []PushDevice{}
	for rows.Next() {
		var device PushDevice
		if err := rows.Scan(&device.ID, &device.UserID, &device.DeviceID, &device.FCMToken, &device.Platform, &device.AppVersion, &device.Locale, &device.Timezone, &device.Enabled, &device.LastSeenAt, &device.CreatedAt, &device.UpdatedAt); err != nil {
			return nil, err
		}
		devices = append(devices, device)
	}
	return devices, rows.Err()
}

func (s *Store) GetNotificationPreferences(ctx context.Context, userID uuid.UUID) (NotificationPreferences, error) {
	var prefs NotificationPreferences
	_, err := s.pool.Exec(ctx, `
		INSERT INTO notification_preferences (user_id)
		VALUES ($1)
		ON CONFLICT (user_id) DO NOTHING
	`, userID)
	if err != nil {
		return NotificationPreferences{}, err
	}
	err = s.pool.QueryRow(ctx, `
		SELECT user_id, recommendation_push_enabled, weekly_summary_push_enabled, ai_insights_push_enabled, created_at, updated_at
		FROM notification_preferences
		WHERE user_id = $1
	`, userID).Scan(&prefs.UserID, &prefs.RecommendationPushEnabled, &prefs.WeeklySummaryPushEnabled, &prefs.AIInsightsPushEnabled, &prefs.CreatedAt, &prefs.UpdatedAt)
	return prefs, err
}

func (s *Store) UpdateNotificationPreferences(ctx context.Context, params UpdateNotificationPreferencesParams) (NotificationPreferences, error) {
	if _, err := s.GetNotificationPreferences(ctx, params.UserID); err != nil {
		return NotificationPreferences{}, err
	}
	var prefs NotificationPreferences
	err := s.pool.QueryRow(ctx, `
		UPDATE notification_preferences
		SET recommendation_push_enabled = CASE WHEN $2::boolean THEN $3 ELSE recommendation_push_enabled END,
		    weekly_summary_push_enabled = CASE WHEN $4::boolean THEN $5 ELSE weekly_summary_push_enabled END,
		    ai_insights_push_enabled = CASE WHEN $6::boolean THEN $7 ELSE ai_insights_push_enabled END,
		    updated_at = now()
		WHERE user_id = $1
		RETURNING user_id, recommendation_push_enabled, weekly_summary_push_enabled, ai_insights_push_enabled, created_at, updated_at
	`, params.UserID, params.RecommendationPushEnabled != nil, boolValue(params.RecommendationPushEnabled), params.WeeklySummaryPushEnabled != nil, boolValue(params.WeeklySummaryPushEnabled), params.AIInsightsPushEnabled != nil, boolValue(params.AIInsightsPushEnabled)).Scan(
		&prefs.UserID,
		&prefs.RecommendationPushEnabled,
		&prefs.WeeklySummaryPushEnabled,
		&prefs.AIInsightsPushEnabled,
		&prefs.CreatedAt,
		&prefs.UpdatedAt,
	)
	return prefs, err
}

func (s *Store) ListRecommendationPushUsers(ctx context.Context, limit int) ([]uuid.UUID, error) {
	return s.listPushUsers(ctx, "recommendation", "recommendation_push_enabled", "20 hours", limit)
}

func (s *Store) ListWeeklySummaryPushUsers(ctx context.Context, limit int) ([]uuid.UUID, error) {
	return s.listPushUsers(ctx, "weekly_summary", "weekly_summary_push_enabled", "6 days", limit)
}

func (s *Store) ListAIInsightPushUsers(ctx context.Context, limit int) ([]uuid.UUID, error) {
	return s.listPushUsers(ctx, "ai_insight", "ai_insights_push_enabled", "20 hours", limit)
}

func (s *Store) listPushUsers(ctx context.Context, notificationType, preferenceColumn, throttleWindow string, limit int) ([]uuid.UUID, error) {
	query := `
		SELECT DISTINCT d.user_id
		FROM push_devices d
		JOIN notification_preferences p ON p.user_id = d.user_id
		WHERE d.enabled
		  AND p.` + preferenceColumn + `
		  AND NOT EXISTS (
		      SELECT 1
		      FROM notification_events e
		      WHERE e.user_id = d.user_id
		        AND e.notification_type = $1
		        AND e.status = 'sent'
		        AND e.created_at > now() - $2::interval
		  )
		ORDER BY d.user_id
		LIMIT $3
	`
	rows, err := s.pool.Query(ctx, query, notificationType, throttleWindow, limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	userIDs := []uuid.UUID{}
	for rows.Next() {
		var userID uuid.UUID
		if err := rows.Scan(&userID); err != nil {
			return nil, err
		}
		userIDs = append(userIDs, userID)
	}
	return userIDs, rows.Err()
}

func (s *Store) RecordNotificationEvent(ctx context.Context, params NotificationEventParams) error {
	data, err := json.Marshal(params.Data)
	if err != nil {
		return err
	}
	_, err = s.pool.Exec(ctx, `
		INSERT INTO notification_events (id, user_id, device_id, notification_type, title, body, data, status, error, sent_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7::jsonb, $8, $9, $10)
	`, params.ID, params.UserID, params.DeviceID, params.NotificationType, params.Title, params.Body, data, params.Status, params.Error, params.SentAt)
	return err
}

func boolValue(value *bool) bool {
	return value != nil && *value
}
