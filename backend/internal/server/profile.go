package server

import (
	"encoding/json"
	"errors"
	"net/http"
	"strings"
	"time"

	"github.com/jackc/pgx/v5/pgconn"
	"github.com/momodeveluk2024/nutrivita-flutter/backend/internal/db"
	"github.com/momodeveluk2024/nutrivita-flutter/backend/internal/filestore"
	"github.com/momodeveluk2024/nutrivita-flutter/backend/internal/httpx"
)

const maxAvatarUploadBytes = 8 << 20

type updateProfileRequest struct {
	DisplayName     *string  `json:"display_name" validate:"omitempty,min=1,max=120"`
	Sex             *string  `json:"sex" validate:"omitempty,oneof=female male other"`
	DateOfBirth     *string  `json:"date_of_birth" validate:"omitempty"`
	HeightCM        *float64 `json:"height_cm" validate:"omitempty,gt=0,lte=300"`
	WeightKG        *float64 `json:"weight_kg" validate:"omitempty,gt=0,lte=800"`
	ActivityLevel   *string  `json:"activity_level" validate:"omitempty,oneof=sedentary light moderate active very_active"`
	PregnancyStatus *string  `json:"pregnancy_status" validate:"omitempty,oneof=none pregnant postpartum trying"`
}

type updatePreferencesRequest struct {
	Units          *string          `json:"units" validate:"omitempty,oneof=metric imperial"`
	Locale         *string          `json:"locale" validate:"omitempty,min=2,max=16"`
	Timezone       *string          `json:"timezone" validate:"omitempty,min=1,max=80"`
	DietaryPattern *string          `json:"dietary_pattern" validate:"omitempty,max=80"`
	Allergens      []string         `json:"allergens" validate:"omitempty,max=32,dive,max=80"`
	Goals          []string         `json:"goals" validate:"omitempty,max=32,dive,max=80"`
	Preferences    *json.RawMessage `json:"preferences"`
}

func (a *App) handleUpdateProfile(w http.ResponseWriter, r *http.Request) {
	claims := authFromContext(r.Context())
	var request updateProfileRequest
	if !a.readAndValidate(w, r, &request) {
		return
	}
	if request.DateOfBirth != nil {
		date := strings.TrimSpace(*request.DateOfBirth)
		if date == "" {
			request.DateOfBirth = nil
		} else if _, err := time.Parse("2006-01-02", date); err != nil {
			httpx.WriteError(w, http.StatusUnprocessableEntity, "invalid date_of_birth")
			return
		} else {
			request.DateOfBirth = &date
		}
	}

	me, err := a.store.UpdateProfile(r.Context(), db.UpdateProfileParams{
		UserID:          claims.UserID,
		DisplayName:     cleanOptionalString(request.DisplayName),
		Sex:             cleanOptionalString(request.Sex),
		DateOfBirth:     request.DateOfBirth,
		HeightCM:        request.HeightCM,
		WeightKG:        request.WeightKG,
		ActivityLevel:   cleanOptionalString(request.ActivityLevel),
		PregnancyStatus: cleanOptionalString(request.PregnancyStatus),
	})
	if err != nil {
		writeProfileUpdateError(a, w, "update profile", err)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, me)
}

func (a *App) handleUpdatePreferences(w http.ResponseWriter, r *http.Request) {
	claims := authFromContext(r.Context())
	var request updatePreferencesRequest
	if !a.readAndValidate(w, r, &request) {
		return
	}
	var preferences []byte
	if request.Preferences != nil {
		preferences = []byte(*request.Preferences)
	}

	me, err := a.store.UpdatePreferences(r.Context(), db.UpdatePreferencesParams{
		UserID:         claims.UserID,
		Units:          cleanOptionalString(request.Units),
		Locale:         cleanOptionalString(request.Locale),
		Timezone:       cleanOptionalString(request.Timezone),
		DietaryPattern: cleanOptionalString(request.DietaryPattern),
		Allergens:      cleanStringSlice(request.Allergens),
		Goals:          cleanStringSlice(request.Goals),
		Preferences:    preferences,
	})
	if err != nil {
		writeProfileUpdateError(a, w, "update preferences", err)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, me)
}

func (a *App) handleCompleteOnboarding(w http.ResponseWriter, r *http.Request) {
	claims := authFromContext(r.Context())
	me, err := a.store.CompleteOnboarding(r.Context(), claims.UserID)
	if err != nil {
		writeProfileUpdateError(a, w, "complete onboarding", err)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, me)
}

func (a *App) handleUpdateAvatar(w http.ResponseWriter, r *http.Request) {
	claims := authFromContext(r.Context())
	r.Body = http.MaxBytesReader(w, r.Body, maxAvatarUploadBytes)
	if err := r.ParseMultipartForm(maxAvatarUploadBytes); err != nil {
		httpx.WriteError(w, http.StatusBadRequest, "invalid multipart upload")
		return
	}
	file, header, err := r.FormFile("image")
	if err != nil {
		httpx.WriteError(w, http.StatusBadRequest, "image file is required")
		return
	}
	defer file.Close()

	contentType := header.Header.Get("Content-Type")
	if !strings.HasPrefix(contentType, "image/") {
		httpx.WriteError(w, http.StatusUnsupportedMediaType, "image upload must be an image")
		return
	}
	obj, err := a.storage.Put(r.Context(), filestore.AvatarKey(claims.UserID, header.Filename), contentType, file)
	if err != nil {
		a.logger.Error("upload avatar", "error", err)
		httpx.WriteError(w, http.StatusInternalServerError, "could not upload avatar")
		return
	}
	me, err := a.store.UpdateAvatar(r.Context(), db.UpdateAvatarParams{
		UserID:    claims.UserID,
		AvatarURL: obj.URL,
	})
	if err != nil {
		writeProfileUpdateError(a, w, "update avatar", err)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, me)
}

func cleanOptionalString(value *string) *string {
	if value == nil {
		return nil
	}
	trimmed := strings.TrimSpace(*value)
	if trimmed == "" {
		return nil
	}
	return &trimmed
}

func cleanStringSlice(values []string) []string {
	if values == nil {
		return nil
	}
	cleaned := make([]string, 0, len(values))
	for _, value := range values {
		trimmed := strings.TrimSpace(value)
		if trimmed != "" {
			cleaned = append(cleaned, trimmed)
		}
	}
	return cleaned
}

func writeProfileUpdateError(a *App, w http.ResponseWriter, operation string, err error) {
	var pgErr *pgconn.PgError
	if errors.As(err, &pgErr) && pgErr.Code == "23514" {
		httpx.WriteError(w, http.StatusUnprocessableEntity, "invalid profile value")
		return
	}
	a.logger.Error(operation, "error", err)
	httpx.WriteError(w, http.StatusInternalServerError, "could not update profile")
}
