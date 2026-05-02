package server

import (
	"net/http"
	"time"

	"github.com/google/uuid"
	"github.com/momodeveluk2024/nutrivita-flutter/backend/internal/db"
	"github.com/momodeveluk2024/nutrivita-flutter/backend/internal/httpx"
)

type createLogRequest struct {
	LoggedOn string                 `json:"logged_on" validate:"required"`
	MealType string                 `json:"meal_type" validate:"required,oneof=breakfast lunch snack dinner other"`
	Notes    *string                `json:"notes" validate:"omitempty,max=500"`
	Items    []createLogItemRequest `json:"items" validate:"required,min=1,dive"`
}

type createLogItemRequest struct {
	FoodID   uuid.UUID `json:"food_id" validate:"required"`
	ServingG float64   `json:"serving_g" validate:"required,gt=0,lte=10000"`
}

func (a *App) handleCreateLog(w http.ResponseWriter, r *http.Request) {
	claims := authFromContext(r.Context())
	var request createLogRequest
	if !a.readAndValidate(w, r, &request) {
		return
	}
	if !validDate(request.LoggedOn) {
		httpx.WriteError(w, http.StatusUnprocessableEntity, "invalid logged_on date")
		return
	}

	logID, err := uuid.NewV7()
	if err != nil {
		httpx.WriteError(w, http.StatusInternalServerError, "could not create log")
		return
	}

	items := make([]db.CreateMealLogItem, 0, len(request.Items))
	for _, item := range request.Items {
		itemID, err := uuid.NewV7()
		if err != nil {
			httpx.WriteError(w, http.StatusInternalServerError, "could not create log")
			return
		}
		items = append(items, db.CreateMealLogItem{ID: itemID, FoodID: item.FoodID, ServingG: item.ServingG})
	}

	log, err := a.store.CreateMealLog(r.Context(), db.CreateMealLogParams{
		ID:       logID,
		UserID:   claims.UserID,
		LoggedOn: request.LoggedOn,
		MealType: request.MealType,
		Notes:    trimOptional(request.Notes),
		Items:    items,
	})
	if err != nil {
		a.logger.Error("create meal log", "error", err)
		httpx.WriteError(w, http.StatusInternalServerError, "could not create log")
		return
	}

	httpx.WriteJSON(w, http.StatusCreated, log)
}

func (a *App) handleListLogs(w http.ResponseWriter, r *http.Request) {
	claims := authFromContext(r.Context())
	logs, err := a.store.ListMealLogs(r.Context(), claims.UserID, r.URL.Query().Get("from"), r.URL.Query().Get("to"))
	if err != nil {
		a.logger.Error("list logs", "error", err)
		httpx.WriteError(w, http.StatusInternalServerError, "could not list logs")
		return
	}
	httpx.WriteJSON(w, http.StatusOK, map[string]any{"logs": logs})
}

func (a *App) handleDeleteLog(w http.ResponseWriter, r *http.Request) {
	claims := authFromContext(r.Context())
	logID, ok := parseUUIDURLParam(w, r, "logID")
	if !ok {
		return
	}
	if err := a.store.DeleteMealLog(r.Context(), claims.UserID, logID); err != nil {
		a.logger.Error("delete log", "error", err)
		httpx.WriteError(w, http.StatusInternalServerError, "could not delete log")
		return
	}
	httpx.WriteNoContent(w)
}

func (a *App) handleTodayIntake(w http.ResponseWriter, r *http.Request) {
	claims := authFromContext(r.Context())
	date := r.URL.Query().Get("date")
	if date == "" {
		date = a.now().Format("2006-01-02")
	}
	if !validDate(date) {
		httpx.WriteError(w, http.StatusUnprocessableEntity, "invalid date")
		return
	}
	totals, err := a.store.GetDailyNutrientTotals(r.Context(), claims.UserID, date)
	if err != nil {
		a.logger.Error("daily intake", "error", err)
		httpx.WriteError(w, http.StatusInternalServerError, "could not load intake")
		return
	}
	httpx.WriteJSON(w, http.StatusOK, totals)
}

func (a *App) handleWeekIntake(w http.ResponseWriter, r *http.Request) {
	claims := authFromContext(r.Context())
	date := r.URL.Query().Get("date")
	if date == "" {
		date = a.now().Format("2006-01-02")
	}
	if !validDate(date) {
		httpx.WriteError(w, http.StatusUnprocessableEntity, "invalid date")
		return
	}
	days, err := a.store.GetWeekNutrientTotals(r.Context(), claims.UserID, date)
	if err != nil {
		a.logger.Error("week intake", "error", err)
		httpx.WriteError(w, http.StatusInternalServerError, "could not load week intake")
		return
	}
	httpx.WriteJSON(w, http.StatusOK, map[string]any{"days": days})
}

func (a *App) handleStreak(w http.ResponseWriter, r *http.Request) {
	claims := authFromContext(r.Context())
	today := a.now().Format("2006-01-02")
	streak, err := a.store.GetStreak(r.Context(), claims.UserID, today)
	if err != nil {
		a.logger.Error("streak", "error", err)
		httpx.WriteError(w, http.StatusInternalServerError, "could not load streak")
		return
	}
	httpx.WriteJSON(w, http.StatusOK, map[string]any{"streak": streak})
}

func validDate(value string) bool {
	_, err := time.Parse("2006-01-02", value)
	return err == nil
}
