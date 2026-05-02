package db

import (
	"context"

	"github.com/google/uuid"
)

type UpdateProfileParams struct {
	UserID          uuid.UUID
	DisplayName     *string
	Sex             *string
	DateOfBirth     *string
	HeightCM        *float64
	WeightKG        *float64
	ActivityLevel   *string
	PregnancyStatus *string
}

type UpdatePreferencesParams struct {
	UserID         uuid.UUID
	Units          *string
	Locale         *string
	Timezone       *string
	DietaryPattern *string
	Allergens      []string
	Goals          []string
	Preferences    []byte
}

type UpdateAvatarParams struct {
	UserID    uuid.UUID
	AvatarURL string
}

func (s *Store) UpdateProfile(ctx context.Context, params UpdateProfileParams) (Me, error) {
	_, err := s.pool.Exec(ctx, `
		UPDATE user_profiles
		SET display_name = COALESCE($2, display_name),
		    sex = COALESCE($3, sex),
		    date_of_birth = COALESCE($4::date, date_of_birth),
		    height_cm = COALESCE($5, height_cm),
		    weight_kg = COALESCE($6, weight_kg),
		    activity_level = COALESCE($7, activity_level),
		    pregnancy_status = COALESCE($8, pregnancy_status),
		    updated_at = now()
		WHERE user_id = $1
	`, params.UserID, params.DisplayName, params.Sex, params.DateOfBirth, params.HeightCM, params.WeightKG, params.ActivityLevel, params.PregnancyStatus)
	if err != nil {
		return Me{}, err
	}
	return s.GetMe(ctx, params.UserID)
}

func (s *Store) UpdatePreferences(ctx context.Context, params UpdatePreferencesParams) (Me, error) {
	_, err := s.pool.Exec(ctx, `
		UPDATE user_profiles
		SET units = COALESCE($2, units),
		    locale = COALESCE($3, locale),
		    timezone = COALESCE($4, timezone),
		    dietary_pattern = COALESCE($5, dietary_pattern),
		    allergens = CASE WHEN $6::boolean THEN $7 ELSE allergens END,
		    goals = CASE WHEN $8::boolean THEN $9 ELSE goals END,
		    preferences = CASE WHEN $10::boolean THEN $11 ELSE preferences END,
		    updated_at = now()
		WHERE user_id = $1
	`, params.UserID, params.Units, params.Locale, params.Timezone, params.DietaryPattern, params.Allergens != nil, params.Allergens, params.Goals != nil, params.Goals, params.Preferences != nil, params.Preferences)
	if err != nil {
		return Me{}, err
	}
	return s.GetMe(ctx, params.UserID)
}

func (s *Store) CompleteOnboarding(ctx context.Context, userID uuid.UUID) (Me, error) {
	_, err := s.pool.Exec(ctx, `
		UPDATE user_profiles
		SET onboarding_completed_at = COALESCE(onboarding_completed_at, now()),
		    updated_at = now()
		WHERE user_id = $1
	`, userID)
	if err != nil {
		return Me{}, err
	}
	return s.GetMe(ctx, userID)
}

func (s *Store) UpdateAvatar(ctx context.Context, params UpdateAvatarParams) (Me, error) {
	_, err := s.pool.Exec(ctx, `
		UPDATE user_profiles
		SET avatar_url = $2,
		    updated_at = now()
		WHERE user_id = $1
	`, params.UserID, params.AvatarURL)
	if err != nil {
		return Me{}, err
	}
	return s.GetMe(ctx, params.UserID)
}
