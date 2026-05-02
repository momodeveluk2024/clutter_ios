package server

import (
	"net/http"
	"time"

	"github.com/google/uuid"
	"github.com/momodeveluk2024/nutrivita-flutter/backend/internal/db"
	"github.com/momodeveluk2024/nutrivita-flutter/backend/internal/httpx"
	"github.com/momodeveluk2024/nutrivita-flutter/backend/internal/jobs"
)

type createReminderRequest struct {
	Title    string  `json:"title" validate:"required,min=1,max=160"`
	Body     *string `json:"body" validate:"omitempty,max=500"`
	RemindAt string  `json:"remind_at" validate:"required"`
	Timezone string  `json:"timezone" validate:"required,min=1,max=80"`
	Enabled  *bool   `json:"enabled"`
}

func (a *App) handleListFavorites(w http.ResponseWriter, r *http.Request) {
	claims := authFromContext(r.Context())
	foods, err := a.store.ListFavorites(r.Context(), claims.UserID)
	if err != nil {
		a.logger.Error("list favorites", "error", err)
		httpx.WriteError(w, http.StatusInternalServerError, "could not list favorites")
		return
	}
	httpx.WriteJSON(w, http.StatusOK, map[string]any{"foods": foods})
}

func (a *App) handleAddFavorite(w http.ResponseWriter, r *http.Request) {
	claims := authFromContext(r.Context())
	foodID, ok := parseUUIDURLParam(w, r, "foodID")
	if !ok {
		return
	}
	if err := a.store.AddFavorite(r.Context(), claims.UserID, foodID); err != nil {
		a.logger.Error("add favorite", "error", err)
		httpx.WriteError(w, http.StatusInternalServerError, "could not add favorite")
		return
	}
	httpx.WriteNoContent(w)
}

func (a *App) handleRemoveFavorite(w http.ResponseWriter, r *http.Request) {
	claims := authFromContext(r.Context())
	foodID, ok := parseUUIDURLParam(w, r, "foodID")
	if !ok {
		return
	}
	if err := a.store.RemoveFavorite(r.Context(), claims.UserID, foodID); err != nil {
		a.logger.Error("remove favorite", "error", err)
		httpx.WriteError(w, http.StatusInternalServerError, "could not remove favorite")
		return
	}
	httpx.WriteNoContent(w)
}

func (a *App) handleListReminders(w http.ResponseWriter, r *http.Request) {
	claims := authFromContext(r.Context())
	reminders, err := a.store.ListReminders(r.Context(), claims.UserID)
	if err != nil {
		a.logger.Error("list reminders", "error", err)
		httpx.WriteError(w, http.StatusInternalServerError, "could not list reminders")
		return
	}
	httpx.WriteJSON(w, http.StatusOK, map[string]any{"reminders": reminders})
}

func (a *App) handleCreateReminder(w http.ResponseWriter, r *http.Request) {
	claims := authFromContext(r.Context())
	var request createReminderRequest
	if !a.readAndValidate(w, r, &request) {
		return
	}

	remindAt, err := time.Parse(time.RFC3339, request.RemindAt)
	if err != nil {
		httpx.WriteError(w, http.StatusUnprocessableEntity, "invalid remind_at")
		return
	}
	reminderID, err := uuid.NewV7()
	if err != nil {
		httpx.WriteError(w, http.StatusInternalServerError, "could not create reminder")
		return
	}
	enabled := true
	if request.Enabled != nil {
		enabled = *request.Enabled
	}

	reminder, err := a.store.CreateReminder(r.Context(), db.CreateReminderParams{
		ID:       reminderID,
		UserID:   claims.UserID,
		Title:    request.Title,
		Body:     trimOptional(request.Body),
		RemindAt: remindAt,
		Timezone: request.Timezone,
		Enabled:  enabled,
	})
	if err != nil {
		a.logger.Error("create reminder", "error", err)
		httpx.WriteError(w, http.StatusInternalServerError, "could not create reminder")
		return
	}
	body := ""
	if reminder.Body != nil {
		body = *reminder.Body
	}
	if err := a.scheduler.Schedule(r.Context(), jobs.ReminderJob{
		ID:       reminder.ID,
		UserID:   reminder.UserID,
		Title:    reminder.Title,
		Body:     body,
		RemindAt: reminder.RemindAt,
		Timezone: reminder.Timezone,
	}); err != nil {
		a.logger.Error("schedule reminder", "error", err)
	}
	httpx.WriteJSON(w, http.StatusCreated, reminder)
}

func (a *App) handleDeleteReminder(w http.ResponseWriter, r *http.Request) {
	claims := authFromContext(r.Context())
	reminderID, ok := parseUUIDURLParam(w, r, "reminderID")
	if !ok {
		return
	}
	if err := a.store.DeleteReminder(r.Context(), claims.UserID, reminderID); err != nil {
		a.logger.Error("delete reminder", "error", err)
		httpx.WriteError(w, http.StatusInternalServerError, "could not delete reminder")
		return
	}
	if err := a.scheduler.Cancel(r.Context(), reminderID); err != nil {
		a.logger.Error("cancel reminder", "error", err)
	}
	httpx.WriteNoContent(w)
}

func (a *App) handleRecommendations(w http.ResponseWriter, r *http.Request) {
	claims := authFromContext(r.Context())
	date := r.URL.Query().Get("date")
	if date == "" {
		date = a.now().Format("2006-01-02")
	}
	if !validDate(date) {
		httpx.WriteError(w, http.StatusUnprocessableEntity, "invalid date")
		return
	}
	recommendations, err := a.store.GetRecommendations(r.Context(), claims.UserID, date)
	if err != nil {
		a.logger.Error("recommendations", "error", err)
		httpx.WriteError(w, http.StatusInternalServerError, "could not load recommendations")
		return
	}
	httpx.WriteJSON(w, http.StatusOK, map[string]any{"recommendations": recommendations})
}

func (a *App) handleDailyMealPlan(w http.ResponseWriter, r *http.Request) {
	claims := authFromContext(r.Context())
	date := r.URL.Query().Get("date")
	if date == "" {
		date = a.now().Format("2006-01-02")
	}
	if !validDate(date) {
		httpx.WriteError(w, http.StatusUnprocessableEntity, "invalid date")
		return
	}
	plan, err := a.store.GetDailyMealPlan(r.Context(), claims.UserID, date)
	if err != nil {
		a.logger.Error("daily meal plan", "error", err)
		httpx.WriteError(w, http.StatusInternalServerError, "could not load daily meal plan")
		return
	}
	httpx.WriteJSON(w, http.StatusOK, plan)
}
