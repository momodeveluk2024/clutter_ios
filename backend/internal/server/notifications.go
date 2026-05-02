package server

import (
	"context"
	"net/http"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/momodeveluk2024/nutrivita-flutter/backend/internal/db"
	"github.com/momodeveluk2024/nutrivita-flutter/backend/internal/httpx"
	"github.com/momodeveluk2024/nutrivita-flutter/backend/internal/notifications"
)

type registerPushDeviceRequest struct {
	DeviceID   uuid.UUID `json:"device_id" validate:"required"`
	FCMToken   string    `json:"fcm_token" validate:"required,min=20,max=4096"`
	Platform   string    `json:"platform" validate:"required,oneof=android ios web"`
	AppVersion string    `json:"app_version" validate:"omitempty,max=80"`
	Locale     string    `json:"locale" validate:"omitempty,max=40"`
	Timezone   string    `json:"timezone" validate:"omitempty,max=80"`
}

type updateNotificationPreferencesRequest struct {
	RecommendationPushEnabled *bool `json:"recommendation_push_enabled"`
	WeeklySummaryPushEnabled  *bool `json:"weekly_summary_push_enabled"`
	AIInsightsPushEnabled     *bool `json:"ai_insights_push_enabled"`
}

func (a *App) handleRegisterPushDevice(w http.ResponseWriter, r *http.Request) {
	claims := authFromContext(r.Context())
	var request registerPushDeviceRequest
	if !a.readAndValidate(w, r, &request) {
		return
	}
	id, err := uuid.NewV7()
	if err != nil {
		httpx.WriteError(w, http.StatusInternalServerError, "could not register device")
		return
	}
	device, err := a.store.RegisterPushDevice(r.Context(), db.RegisterPushDeviceParams{
		ID:         id,
		UserID:     claims.UserID,
		DeviceID:   request.DeviceID,
		FCMToken:   strings.TrimSpace(request.FCMToken),
		Platform:   request.Platform,
		AppVersion: strings.TrimSpace(request.AppVersion),
		Locale:     strings.TrimSpace(request.Locale),
		Timezone:   strings.TrimSpace(request.Timezone),
	})
	if err != nil {
		a.logger.Error("register push device", "error", err)
		httpx.WriteError(w, http.StatusInternalServerError, "could not register device")
		return
	}
	httpx.WriteJSON(w, http.StatusOK, device)
}

func (a *App) handleDisablePushDevice(w http.ResponseWriter, r *http.Request) {
	claims := authFromContext(r.Context())
	deviceID, ok := parseUUIDURLParam(w, r, "deviceID")
	if !ok {
		return
	}
	if err := a.store.DisablePushDevice(r.Context(), claims.UserID, deviceID); err != nil {
		a.logger.Error("disable push device", "error", err)
		httpx.WriteError(w, http.StatusInternalServerError, "could not disable device")
		return
	}
	httpx.WriteNoContent(w)
}

func (a *App) handleGetNotificationPreferences(w http.ResponseWriter, r *http.Request) {
	claims := authFromContext(r.Context())
	prefs, err := a.store.GetNotificationPreferences(r.Context(), claims.UserID)
	if err != nil {
		a.logger.Error("get notification preferences", "error", err)
		httpx.WriteError(w, http.StatusInternalServerError, "could not load notification preferences")
		return
	}
	httpx.WriteJSON(w, http.StatusOK, prefs)
}

func (a *App) handleUpdateNotificationPreferences(w http.ResponseWriter, r *http.Request) {
	claims := authFromContext(r.Context())
	var request updateNotificationPreferencesRequest
	if !a.readAndValidate(w, r, &request) {
		return
	}
	prefs, err := a.store.UpdateNotificationPreferences(r.Context(), db.UpdateNotificationPreferencesParams{
		UserID:                    claims.UserID,
		RecommendationPushEnabled: request.RecommendationPushEnabled,
		WeeklySummaryPushEnabled:  request.WeeklySummaryPushEnabled,
		AIInsightsPushEnabled:     request.AIInsightsPushEnabled,
	})
	if err != nil {
		a.logger.Error("update notification preferences", "error", err)
		httpx.WriteError(w, http.StatusInternalServerError, "could not update notification preferences")
		return
	}
	httpx.WriteJSON(w, http.StatusOK, prefs)
}

func (a *App) StartBackgroundJobs(ctxDone <-chan struct{}) {
	if a.store == nil || !a.cfg.PushSchedulerEnabled {
		return
	}
	interval := a.cfg.NotificationJobInterval
	if interval <= 0 {
		interval = time.Hour
	}
	go func() {
		ticker := time.NewTicker(interval)
		defer ticker.Stop()
		for {
			select {
			case <-ctxDone:
				return
			case <-ticker.C:
				a.sendRecommendationPushes()
				a.sendWeeklySummaryPushes()
				a.sendAIInsightPushes()
			}
		}
	}()
}

func (a *App) sendRecommendationPushes() {
	ctx := contextWithTimeout()
	defer ctx.cancel()

	userIDs, err := a.store.ListRecommendationPushUsers(ctx.ctx, 100)
	if err != nil {
		a.logger.Error("list recommendation push users", "error", err)
		return
	}

	date := a.now().Format("2006-01-02")
	for _, userID := range userIDs {
		recommendations, err := a.store.GetRecommendations(ctx.ctx, userID, date)
		if err != nil || len(recommendations) == 0 {
			if err != nil {
				a.logger.Error("load push recommendation", "user_id", userID, "error", err)
			}
			continue
		}
		devices, err := a.store.ListActivePushDevices(ctx.ctx, userID)
		if err != nil {
			a.logger.Error("list push devices", "user_id", userID, "error", err)
			continue
		}
		rec := recommendations[0]
		imageURL := ""
		if rec.FoodImageURL != nil {
			imageURL = *rec.FoodImageURL
		}
		message := notifications.BuildRecommendationPushMessage(notifications.RecommendationPushContent{
			UserID:       userID,
			NutrientName: rec.Name,
			FoodID:       rec.FoodID,
			FoodName:     rec.FoodName,
			FoodImageURL: imageURL,
		})
		for _, device := range devices {
			a.sendAndRecordPush(ctx.ctx, db.PushDevice(device), "recommendation", message)
		}
	}
}

func (a *App) sendWeeklySummaryPushes() {
	now := a.now()
	if now.Weekday() != time.Sunday || now.Hour() < 19 {
		return
	}
	a.sendSimplePushes("weekly_summary", notifications.BuildWeeklySummaryPushMessage, a.store.ListWeeklySummaryPushUsers)
}

func (a *App) sendAIInsightPushes() {
	now := a.now()
	if now.Hour() < 10 || now.Hour() > 13 {
		return
	}
	a.sendSimplePushes("ai_insight", notifications.BuildAIInsightPushMessage, a.store.ListAIInsightPushUsers)
}

func (a *App) sendSimplePushes(notificationType string, build func(uuid.UUID) notifications.PushMessage, listUsers func(context.Context, int) ([]uuid.UUID, error)) {
	ctx := contextWithTimeout()
	defer ctx.cancel()

	userIDs, err := listUsers(ctx.ctx, 100)
	if err != nil {
		a.logger.Error("list push users", "notification_type", notificationType, "error", err)
		return
	}
	for _, userID := range userIDs {
		devices, err := a.store.ListActivePushDevices(ctx.ctx, userID)
		if err != nil {
			a.logger.Error("list push devices", "user_id", userID, "error", err)
			continue
		}
		message := build(userID)
		for _, device := range devices {
			a.sendAndRecordPush(ctx.ctx, device, notificationType, message)
		}
	}
}

func (a *App) sendAndRecordPush(ctx context.Context, device db.PushDevice, notificationType string, message notifications.PushMessage) {
	recipient := notifications.PushRecipient{
		DeviceID: device.ID,
		Token:    device.FCMToken,
		Platform: device.Platform,
	}
	status := "sent"
	var errorMessage *string
	sentAt := a.now()
	if err := a.push.Send(ctx, recipient, message); err != nil {
		status = "failed"
		value := err.Error()
		errorMessage = &value
		a.logger.Error("send push notification", "user_id", message.UserID, "device_id", device.ID, "error", err)
	}
	eventID, err := uuid.NewV7()
	if err != nil {
		a.logger.Error("create notification event id", "error", err)
		return
	}
	if err := a.store.RecordNotificationEvent(ctx, db.NotificationEventParams{
		ID:               eventID,
		UserID:           message.UserID,
		DeviceID:         &device.ID,
		NotificationType: notificationType,
		Title:            message.Title,
		Body:             message.Body,
		Data:             message.Data,
		Status:           status,
		Error:            errorMessage,
		SentAt:           &sentAt,
	}); err != nil {
		a.logger.Error("record notification event", "error", err)
	}
}

type timeoutContext struct {
	ctx    context.Context
	cancel context.CancelFunc
}

func contextWithTimeout() timeoutContext {
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	return timeoutContext{ctx: ctx, cancel: cancel}
}
