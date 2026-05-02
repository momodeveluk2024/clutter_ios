package server

import (
	"errors"
	"net/http"
	"strings"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/momodeveluk2024/nutrivita-flutter/backend/internal/db"
	"github.com/momodeveluk2024/nutrivita-flutter/backend/internal/filestore"
	"github.com/momodeveluk2024/nutrivita-flutter/backend/internal/httpx"
)



type updateAdminNutrientDRIRequest struct {
	Amount float64 `json:"amount" validate:"required,gt=0,lte=100000"`
}

type upsertAdminNutrientRequest struct {
	Code     string  `json:"code" validate:"required,min=1,max=40"`
	Name     string  `json:"name" validate:"required,min=1,max=120"`
	Unit     string  `json:"unit" validate:"required,min=1,max=40"`
	Group    string  `json:"group" validate:"required,min=1,max=60"`
	DRIAdult float64 `json:"driAdult" validate:"omitempty,gte=0,lte=100000"`
}

type updateAdminFoodRequest struct {
	Name         *string                 `json:"name" validate:"omitempty,min=1,max=180"`
	Brand        *string                 `json:"brand" validate:"omitempty,max=120"`
	Category     *string                 `json:"category" validate:"omitempty,min=1,max=80"`
	ServingSizeG *float64                `json:"servingSizeG" validate:"omitempty,gt=0,lte=10000"`
	ImageURL     *string                 `json:"imageUrl" validate:"omitempty,url,max=500"`
	Barcode      *string                 `json:"barcode" validate:"omitempty,max=80"`
	Source       *string                 `json:"source" validate:"omitempty,max=120"`
	Verified     *bool                   `json:"verified"`
	Nutrients    []db.CreateFoodNutrient `json:"nutrients" validate:"omitempty,max=64,dive"`
}

type createAdminFoodRequest struct {
	Name         string                  `json:"name" validate:"required,min=1,max=180"`
	Brand        *string                 `json:"brand" validate:"omitempty,max=120"`
	Category     string                  `json:"category" validate:"required,min=1,max=80"`
	ServingSizeG float64                 `json:"servingSizeG" validate:"required,gt=0,lte=10000"`
	ImageURL     *string                 `json:"imageUrl" validate:"omitempty,url,max=500"`
	Barcode      *string                 `json:"barcode" validate:"omitempty,max=80"`
	Source       string                  `json:"source" validate:"omitempty,max=120"`
	Verified     bool                    `json:"verified"`
	Nutrients    []db.CreateFoodNutrient `json:"nutrients" validate:"omitempty,max=64,dive"`
}

type updateAdminUserProfileRequest struct {
	DisplayName *string `json:"displayName" validate:"omitempty,min=1,max=120"`
	Sex         *string `json:"sex" validate:"omitempty,max=20"`
	Activity    *string `json:"activity" validate:"omitempty,max=40"`
	Timezone    *string `json:"timezone" validate:"omitempty,max=80"`
	Units       *string `json:"units" validate:"omitempty,max=20"`
}

type upsertAdminReminderTemplateRequest struct {
	Title    string `json:"title" validate:"required,min=1,max=160"`
	Body     string `json:"body" validate:"max=500"`
	Trigger  string `json:"trigger" validate:"required,min=1,max=160"`
	Audience string `json:"audience" validate:"required,min=1,max=160"`
	Active   bool   `json:"active"`
}



func (a *App) requireAdmin(next http.Handler) http.Handler {
	return a.requireAuth(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		claims := authFromContext(r.Context())
		if claims == nil {
			httpx.WriteError(w, http.StatusUnauthorized, "unauthorized")
			return
		}
		user, err := a.store.GetUserByID(r.Context(), claims.UserID)
		if err != nil {
			httpx.WriteError(w, http.StatusUnauthorized, "unauthorized")
			return
		}
		if user.Role != "admin" {
			httpx.WriteError(w, http.StatusForbidden, "admin access required")
			return
		}
		next.ServeHTTP(w, r)
	}))
}

func (a *App) handleAdminMe(w http.ResponseWriter, r *http.Request) {
	claims := authFromContext(r.Context())
	me, err := a.store.GetMe(r.Context(), claims.UserID)
	if err != nil {
		httpx.WriteError(w, http.StatusUnauthorized, "unauthorized")
		return
	}
	httpx.WriteJSON(w, http.StatusOK, me)
}

func (a *App) handleAdminOverview(w http.ResponseWriter, r *http.Request) {
	overview, err := a.store.GetAdminOverview(r.Context(), a.now(), r.URL.Query().Get("range"))
	if err != nil {
		a.logger.Error("admin overview", "error", err)
		httpx.WriteError(w, http.StatusInternalServerError, "could not load overview")
		return
	}
	httpx.WriteJSON(w, http.StatusOK, overview)
}

func (a *App) handleAdminUsers(w http.ResponseWriter, r *http.Request) {
	users, err := a.store.ListAdminUsers(r.Context(), r.URL.Query().Get("status"), parseLimit(r, 50))
	if err != nil {
		a.logger.Error("admin users", "error", err)
		httpx.WriteError(w, http.StatusInternalServerError, "could not list users")
		return
	}
	httpx.WriteJSON(w, http.StatusOK, map[string]any{"users": users})
}

func (a *App) handleAdminUser(w http.ResponseWriter, r *http.Request) {
	userID, ok := parseUUIDURLParam(w, r, "userID")
	if !ok {
		return
	}
	user, err := a.store.GetAdminUser(r.Context(), userID)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			httpx.WriteError(w, http.StatusNotFound, "user not found")
			return
		}
		a.logger.Error("admin user", "error", err)
		httpx.WriteError(w, http.StatusInternalServerError, "could not load user")
		return
	}
	httpx.WriteJSON(w, http.StatusOK, user)
}

func (a *App) handleAdminUpdateUserProfile(w http.ResponseWriter, r *http.Request) {
	userID, ok := parseUUIDURLParam(w, r, "userID")
	if !ok {
		return
	}
	var request updateAdminUserProfileRequest
	if !a.readAndValidate(w, r, &request) {
		return
	}
	user, err := a.store.UpdateAdminUserProfile(r.Context(), db.UpdateAdminUserProfileParams{
		UserID:      userID,
		DisplayName: request.DisplayName,
		Sex:         request.Sex,
		Activity:    request.Activity,
		Timezone:    request.Timezone,
		Units:       request.Units,
	})
	if err != nil {
		a.logger.Error("admin update user profile", "error", err)
		httpx.WriteError(w, http.StatusInternalServerError, "could not update user")
		return
	}
	httpx.WriteJSON(w, http.StatusOK, user)
}

func (a *App) handleAdminVerifyUser(w http.ResponseWriter, r *http.Request) {
	userID, ok := parseUUIDURLParam(w, r, "userID")
	if !ok {
		return
	}
	user, err := a.store.VerifyAdminUser(r.Context(), userID)
	if err != nil {
		httpx.WriteError(w, http.StatusInternalServerError, "could not verify user")
		return
	}
	httpx.WriteJSON(w, http.StatusOK, user)
}

func (a *App) handleAdminSuspendUser(w http.ResponseWriter, r *http.Request) {
	userID, ok := parseUUIDURLParam(w, r, "userID")
	if !ok {
		return
	}
	if claims := authFromContext(r.Context()); claims != nil && claims.UserID == userID {
		httpx.WriteError(w, http.StatusBadRequest, "admins cannot suspend themselves")
		return
	}
	user, err := a.store.SuspendAdminUser(r.Context(), userID, true)
	if err != nil {
		httpx.WriteError(w, http.StatusInternalServerError, "could not suspend user")
		return
	}
	httpx.WriteJSON(w, http.StatusOK, user)
}

func (a *App) handleAdminUnsuspendUser(w http.ResponseWriter, r *http.Request) {
	userID, ok := parseUUIDURLParam(w, r, "userID")
	if !ok {
		return
	}
	user, err := a.store.SuspendAdminUser(r.Context(), userID, false)
	if err != nil {
		httpx.WriteError(w, http.StatusInternalServerError, "could not unsuspend user")
		return
	}
	httpx.WriteJSON(w, http.StatusOK, user)
}

func (a *App) handleAdminDeleteUser(w http.ResponseWriter, r *http.Request) {
	userID, ok := parseUUIDURLParam(w, r, "userID")
	if !ok {
		return
	}
	if claims := authFromContext(r.Context()); claims != nil && claims.UserID == userID {
		httpx.WriteError(w, http.StatusBadRequest, "admins cannot delete themselves")
		return
	}
	if err := a.store.DeleteAdminUser(r.Context(), userID); err != nil {
		httpx.WriteError(w, http.StatusInternalServerError, "could not delete user")
		return
	}
	httpx.WriteNoContent(w)
}

func (a *App) handleAdminRevokeUserSession(w http.ResponseWriter, r *http.Request) {
	userID, ok := parseUUIDURLParam(w, r, "userID")
	if !ok {
		return
	}
	sessionID, ok := parseUUIDURLParam(w, r, "sessionID")
	if !ok {
		return
	}
	if err := a.store.RevokeAdminUserSession(r.Context(), userID, sessionID); err != nil {
		httpx.WriteError(w, http.StatusInternalServerError, "could not revoke session")
		return
	}
	httpx.WriteNoContent(w)
}

func (a *App) handleAdminLogs(w http.ResponseWriter, r *http.Request) {
	var userID uuid.UUID
	if raw := strings.TrimSpace(r.URL.Query().Get("user_id")); raw != "" {
		parsed, err := uuid.Parse(raw)
		if err != nil {
			httpx.WriteError(w, http.StatusBadRequest, "invalid user_id")
			return
		}
		userID = parsed
	}
	logs, err := a.store.ListAdminMealLogs(r.Context(), userID, r.URL.Query().Get("from"), r.URL.Query().Get("to"), parseLimit(r, 50))
	if err != nil {
		a.logger.Error("admin logs", "error", err)
		httpx.WriteError(w, http.StatusInternalServerError, "could not list logs")
		return
	}
	httpx.WriteJSON(w, http.StatusOK, map[string]any{"logs": logs})
}

func (a *App) handleAdminNutrients(w http.ResponseWriter, r *http.Request) {
	nutrients, err := a.store.ListAdminNutrients(r.Context())
	if err != nil {
		a.logger.Error("admin nutrients", "error", err)
		httpx.WriteError(w, http.StatusInternalServerError, "could not list nutrients")
		return
	}
	httpx.WriteJSON(w, http.StatusOK, map[string]any{"nutrients": nutrients})
}

func (a *App) handleAdminCreateNutrient(w http.ResponseWriter, r *http.Request) {
	var request upsertAdminNutrientRequest
	if !a.readAndValidate(w, r, &request) {
		return
	}
	nutrient, err := a.store.UpsertAdminNutrient(r.Context(), db.UpsertAdminNutrientParams{
		Code:     request.Code,
		Name:     request.Name,
		Unit:     request.Unit,
		Group:    request.Group,
		DRIAdult: request.DRIAdult,
	})
	if err != nil {
		a.logger.Error("admin create nutrient", "error", err)
		httpx.WriteError(w, http.StatusInternalServerError, "could not create nutrient")
		return
	}
	httpx.WriteJSON(w, http.StatusCreated, nutrient)
}

func (a *App) handleAdminUpdateNutrient(w http.ResponseWriter, r *http.Request) {
	var request upsertAdminNutrientRequest
	if !a.readAndValidate(w, r, &request) {
		return
	}
	if strings.TrimSpace(request.Code) == "" {
		request.Code = chi.URLParam(r, "code")
	}
	nutrient, err := a.store.UpsertAdminNutrient(r.Context(), db.UpsertAdminNutrientParams{
		Code:     chi.URLParam(r, "code"),
		Name:     request.Name,
		Unit:     request.Unit,
		Group:    request.Group,
		DRIAdult: request.DRIAdult,
	})
	if err != nil {
		a.logger.Error("admin update nutrient", "error", err)
		httpx.WriteError(w, http.StatusInternalServerError, "could not update nutrient")
		return
	}
	httpx.WriteJSON(w, http.StatusOK, nutrient)
}

func (a *App) handleAdminUpdateNutrientDRI(w http.ResponseWriter, r *http.Request) {
	var request updateAdminNutrientDRIRequest
	if !a.readAndValidate(w, r, &request) {
		return
	}
	nutrient, err := a.store.UpdateAdminNutrientDRI(r.Context(), chi.URLParam(r, "code"), request.Amount)
	if err != nil {
		a.logger.Error("admin update nutrient dri", "error", err)
		httpx.WriteError(w, http.StatusInternalServerError, "could not update nutrient")
		return
	}
	httpx.WriteJSON(w, http.StatusOK, nutrient)
}

func (a *App) handleAdminFoods(w http.ResponseWriter, r *http.Request) {
	foods, err := a.store.ListAdminFoods(
		r.Context(),
		r.URL.Query().Get("q"),
		r.URL.Query().Get("category"),
		r.URL.Query().Get("verified"),
		parseLimit(r, 50),
	)
	if err != nil {
		a.logger.Error("admin foods", "error", err)
		httpx.WriteError(w, http.StatusInternalServerError, "could not list foods")
		return
	}
	httpx.WriteJSON(w, http.StatusOK, map[string]any{"foods": foods})
}

func (a *App) handleAdminCreateFood(w http.ResponseWriter, r *http.Request) {
	var request createAdminFoodRequest
	if !a.readAndValidate(w, r, &request) {
		return
	}
	source := strings.TrimSpace(request.Source)
	if source == "" {
		source = "manual"
	}
	food, err := a.store.CreateAdminFood(r.Context(), db.CreateAdminFoodParams{
		Name:         request.Name,
		Brand:        request.Brand,
		Category:     request.Category,
		ServingSizeG: request.ServingSizeG,
		ImageURL:     request.ImageURL,
		Barcode:      request.Barcode,
		Source:       source,
		Verified:     request.Verified,
		Nutrients:    request.Nutrients,
	})
	if err != nil {
		a.logger.Error("admin create food", "error", err)
		httpx.WriteError(w, http.StatusInternalServerError, "could not create food")
		return
	}
	httpx.WriteJSON(w, http.StatusCreated, food)
}

func (a *App) handleAdminUpdateFood(w http.ResponseWriter, r *http.Request) {
	foodID, ok := parseUUIDURLParam(w, r, "foodID")
	if !ok {
		return
	}
	var request updateAdminFoodRequest
	if !a.readAndValidate(w, r, &request) {
		return
	}
	food, err := a.store.UpdateAdminFood(r.Context(), db.UpdateAdminFoodParams{
		ID:               foodID,
		Name:             request.Name,
		Brand:            request.Brand,
		Category:         request.Category,
		ServingSizeG:     request.ServingSizeG,
		ImageURL:         request.ImageURL,
		Barcode:          request.Barcode,
		Source:           request.Source,
		Verified:         request.Verified,
		Nutrients:        request.Nutrients,
		ReplaceNutrients: request.Nutrients != nil,
	})
	if err != nil {
		a.logger.Error("admin update food", "error", err)
		httpx.WriteError(w, http.StatusInternalServerError, "could not update food")
		return
	}
	httpx.WriteJSON(w, http.StatusOK, food)
}

func (a *App) handleAdminUploadFoodImage(w http.ResponseWriter, r *http.Request) {
	foodID, ok := parseUUIDURLParam(w, r, "foodID")
	if !ok {
		return
	}
	if err := r.ParseMultipartForm(8 << 20); err != nil {
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
	obj, err := a.storage.Put(r.Context(), filestore.FoodImageKey(foodID, header.Filename), contentType, file)
	if err != nil {
		a.logger.Error("admin upload food image", "error", err)
		httpx.WriteError(w, http.StatusInternalServerError, "could not upload image")
		return
	}
	food, err := a.store.UpdateAdminFood(r.Context(), db.UpdateAdminFoodParams{ID: foodID, ImageURL: &obj.URL})
	if err != nil {
		httpx.WriteError(w, http.StatusInternalServerError, "could not attach image")
		return
	}
	httpx.WriteJSON(w, http.StatusOK, food)
}

func (a *App) handleAdminVerifyFood(w http.ResponseWriter, r *http.Request) {
	foodID, ok := parseUUIDURLParam(w, r, "foodID")
	if !ok {
		return
	}
	food, err := a.store.VerifyAdminFood(r.Context(), foodID)
	if err != nil {
		a.logger.Error("admin verify food", "error", err)
		httpx.WriteError(w, http.StatusInternalServerError, "could not verify food")
		return
	}
	httpx.WriteJSON(w, http.StatusOK, food)
}

func (a *App) handleAdminDeleteFood(w http.ResponseWriter, r *http.Request) {
	foodID, ok := parseUUIDURLParam(w, r, "foodID")
	if !ok {
		return
	}
	if err := a.store.DeleteAdminFood(r.Context(), foodID); err != nil {
		a.logger.Error("admin delete food", "error", err)
		httpx.WriteError(w, http.StatusInternalServerError, "could not delete food")
		return
	}
	httpx.WriteNoContent(w)
}

func (a *App) handleAdminReminders(w http.ResponseWriter, r *http.Request) {
	reminders, err := a.store.ListAdminReminders(r.Context(), parseLimit(r, 50))
	if err != nil {
		a.logger.Error("admin reminders", "error", err)
		httpx.WriteError(w, http.StatusInternalServerError, "could not list reminders")
		return
	}
	httpx.WriteJSON(w, http.StatusOK, map[string]any{"reminders": reminders})
}

func (a *App) handleAdminReminderTemplates(w http.ResponseWriter, r *http.Request) {
	templates, err := a.store.ListAdminReminderTemplates(r.Context())
	if err != nil {
		a.logger.Error("admin reminder templates", "error", err)
		httpx.WriteError(w, http.StatusInternalServerError, "could not list reminder templates")
		return
	}
	httpx.WriteJSON(w, http.StatusOK, map[string]any{"templates": templates})
}

func (a *App) handleAdminCreateReminderTemplate(w http.ResponseWriter, r *http.Request) {
	var request upsertAdminReminderTemplateRequest
	if !a.readAndValidate(w, r, &request) {
		return
	}
	template, err := a.store.UpsertAdminReminderTemplate(r.Context(), db.UpsertAdminReminderTemplateParams{
		Title:    request.Title,
		Body:     request.Body,
		Trigger:  request.Trigger,
		Audience: request.Audience,
		Active:   request.Active,
	})
	if err != nil {
		httpx.WriteError(w, http.StatusInternalServerError, "could not create reminder template")
		return
	}
	httpx.WriteJSON(w, http.StatusCreated, template)
}

func (a *App) handleAdminUpdateReminderTemplate(w http.ResponseWriter, r *http.Request) {
	templateID, ok := parseUUIDURLParam(w, r, "templateID")
	if !ok {
		return
	}
	var request upsertAdminReminderTemplateRequest
	if !a.readAndValidate(w, r, &request) {
		return
	}
	template, err := a.store.UpsertAdminReminderTemplate(r.Context(), db.UpsertAdminReminderTemplateParams{
		ID:       templateID,
		Title:    request.Title,
		Body:     request.Body,
		Trigger:  request.Trigger,
		Audience: request.Audience,
		Active:   request.Active,
	})
	if err != nil {
		httpx.WriteError(w, http.StatusInternalServerError, "could not update reminder template")
		return
	}
	httpx.WriteJSON(w, http.StatusOK, template)
}

func (a *App) handleAdminAuditLog(w http.ResponseWriter, r *http.Request) {
	entries, err := a.store.ListAdminAuditEntries(r.Context())
	if err != nil {
		httpx.WriteError(w, http.StatusInternalServerError, "could not list audit log")
		return
	}
	httpx.WriteJSON(w, http.StatusOK, map[string]any{"entries": entries})
}
