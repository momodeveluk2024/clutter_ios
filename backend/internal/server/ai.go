package server

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"io"
	"net/http"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	aipkg "github.com/momodeveluk2024/nutrivita-flutter/backend/internal/ai"
	"github.com/momodeveluk2024/nutrivita-flutter/backend/internal/db"
	"github.com/momodeveluk2024/nutrivita-flutter/backend/internal/filestore"
	"github.com/momodeveluk2024/nutrivita-flutter/backend/internal/httpx"
)

type updateAIEstimateRequest struct {
	Items []db.AIEstimateItem `json:"items" validate:"required,min=1,dive"`
}

type aiChatRequest struct {
	Message        string     `json:"message" validate:"required,min=1,max=2000"`
	ConversationID *uuid.UUID `json:"conversation_id"`
	EstimateID     *uuid.UUID `json:"estimate_id"`
	ImageID        *uuid.UUID `json:"image_id"`
}

type reviewAIEstimateRequest struct {
	Status string `json:"status" validate:"required,min=1,max=40"`
	Notes  string `json:"notes" validate:"max=1000"`
}

func (a *App) handleAnalyzeMealPhoto(w http.ResponseWriter, r *http.Request) {
	claims := authFromContext(r.Context())
	if a.ai == nil {
		httpx.WriteError(w, http.StatusServiceUnavailable, "AI assistant is not configured")
		return
	}

	count, err := a.store.CountUserAIEstimatesToday(r.Context(), claims.UserID)
	if err != nil {
		a.logger.Error("count ai estimates today", "error", err)
		httpx.WriteError(w, http.StatusInternalServerError, "could not verify rate limits")
		return
	}
	if count >= 20 {
		httpx.WriteError(w, http.StatusTooManyRequests, "You have reached your daily limit of 20 AI estimates. Please try again tomorrow.")
		return
	}

	r.Body = http.MaxBytesReader(w, r.Body, aipkg.MaxMealImageBytes+(1<<20))
	if err := r.ParseMultipartForm(aipkg.MaxMealImageBytes); err != nil {
		httpx.WriteError(w, http.StatusBadRequest, "invalid multipart upload")
		return
	}
	file, header, err := r.FormFile("image")
	if err != nil {
		httpx.WriteError(w, http.StatusBadRequest, "image file is required")
		return
	}
	defer file.Close()

	imageBytes, err := io.ReadAll(io.LimitReader(file, aipkg.MaxMealImageBytes+1))
	if err != nil {
		httpx.WriteError(w, http.StatusBadRequest, "could not read image")
		return
	}
	contentType := header.Header.Get("Content-Type")
	if contentType == "" {
		contentType = http.DetectContentType(imageBytes)
	}
	if err := aipkg.ValidateMealImage(header.Filename, contentType, int64(len(imageBytes))); err != nil {
		httpx.WriteError(w, http.StatusUnsupportedMediaType, err.Error())
		return
	}

	estimateID, err := uuid.NewV7()
	if err != nil {
		httpx.WriteError(w, http.StatusInternalServerError, "could not create estimate")
		return
	}
	mealType := normalizeMealType(r.FormValue("meal_type"))
	loggedOn := normalizeLoggedOn(a.now(), r.FormValue("logged_on"))
	if !validDate(loggedOn) {
		httpx.WriteError(w, http.StatusUnprocessableEntity, "invalid logged_on date")
		return
	}
	locale := defaultString(r.FormValue("locale"), "en")
	unitSystem := defaultString(r.FormValue("unit_system"), "metric")
	question := trimOptionalString(r.FormValue("question"))

	obj, err := a.storage.Put(r.Context(), filestore.MealPhotoKey(claims.UserID, estimateID, header.Filename), contentType, bytes.NewReader(imageBytes))
	if err != nil {
		a.logger.Error("store meal photo", "error", err)
		httpx.WriteError(w, http.StatusInternalServerError, "could not store meal photo")
		return
	}
	estimate, err := a.store.CreateAIEstimate(r.Context(), db.CreateAIEstimateParams{
		ID:            estimateID,
		UserID:        claims.UserID,
		ImageURL:      &obj.URL,
		ImageKey:      &obj.Key,
		PromptVersion: aipkg.PromptVersion,
		Provider:      a.aiProviderName,
		Model:         a.cfg.GeminiModelFast,
		MealType:      mealType,
		LoggedOn:      loggedOn,
		Locale:        locale,
		UnitSystem:    unitSystem,
		Question:      question,
	})
	if err != nil {
		a.logger.Error("create ai estimate", "error", err)
		httpx.WriteError(w, http.StatusInternalServerError, "could not create estimate")
		return
	}

	start := time.Now()
	modelEstimate, providerErr := a.ai.AnalyzeMealPhoto(r.Context(), aipkg.AnalyzeMealPhotoRequest{
		ImageBytes:  imageBytes,
		ContentType: strings.Split(contentType, ";")[0],
		Filename:    header.Filename,
		Question:    derefString(question),
		MealType:    mealType,
		Locale:      locale,
		UnitSystem:  unitSystem,
	})
	latency := int(time.Since(start).Milliseconds())
	if providerErr != nil {
		a.logger.Error("analyze meal photo", "error", providerErr)
		_ = a.writeAIUsage(r.Context(), &claims.UserID, &estimateID, nil, "analyze_photo", "error", estimate.Model, latency, providerErr)
		_, _ = a.store.UpdateAIEstimateResult(r.Context(), db.UpdateAIEstimateResultParams{
			ID:             estimateID,
			UserID:         claims.UserID,
			Status:         "failed",
			Confidence:     0,
			Questions:      []string{"Try another angle or enter the meal manually."},
			Warnings:       []string{"I could not analyze this image."},
			RawModelJSON:   json.RawMessage(`{}`),
			NormalizedJSON: json.RawMessage(`{}`),
			Items:          nil,
		})
		httpx.WriteError(w, http.StatusBadGateway, "I could not analyze this image. Try another angle or enter the meal manually.")
		return
	}
	a.enrichEstimateItems(r.Context(), &modelEstimate)
	raw := modelEstimate.RawJSON
	if len(raw) == 0 {
		raw, _ = json.Marshal(modelEstimate)
	}
	normalized, _ := json.Marshal(modelEstimate)
	items := aiItemsToDB(estimateID, claims.UserID, modelEstimate.Items)
	saved, err := a.store.UpdateAIEstimateResult(r.Context(), db.UpdateAIEstimateResultParams{
		ID:             estimateID,
		UserID:         claims.UserID,
		Status:         "needs_review",
		Confidence:     modelEstimate.Confidence,
		Questions:      modelEstimate.Questions,
		Warnings:       modelEstimate.Warnings,
		RawModelJSON:   raw,
		NormalizedJSON: normalized,
		Items:          items,
	})
	if err != nil {
		a.logger.Error("save ai estimate result", "error", err)
		httpx.WriteError(w, http.StatusInternalServerError, "could not save estimate")
		return
	}
	_ = a.writeAIUsage(r.Context(), &claims.UserID, &estimateID, nil, "analyze_photo", "ok", saved.Model, latency, nil)
	httpx.WriteJSON(w, http.StatusCreated, saved)
}

func (a *App) handleUpdateAIEstimate(w http.ResponseWriter, r *http.Request) {
	claims := authFromContext(r.Context())
	estimateID, ok := parseUUIDURLParam(w, r, "estimateID")
	if !ok {
		return
	}
	var request updateAIEstimateRequest
	if !a.readAndValidate(w, r, &request) {
		return
	}
	for i := range request.Items {
		request.Items[i].EstimateID = estimateID
		request.Items[i].UserID = claims.UserID
		request.Items[i].Position = i
		if strings.TrimSpace(request.Items[i].Source) == "" {
			request.Items[i].Source = "user_edit"
		}
	}
	estimate, err := a.store.UpdateAIEstimateItems(r.Context(), db.UpdateAIEstimateItemsParams{
		ID:     estimateID,
		UserID: claims.UserID,
		Items:  request.Items,
	})
	if err != nil {
		a.logger.Error("update ai estimate", "error", err)
		httpx.WriteError(w, http.StatusInternalServerError, "could not update estimate")
		return
	}
	httpx.WriteJSON(w, http.StatusOK, estimate)
}

func (a *App) handleAcceptAIEstimate(w http.ResponseWriter, r *http.Request) {
	claims := authFromContext(r.Context())
	estimateID, ok := parseUUIDURLParam(w, r, "estimateID")
	if !ok {
		return
	}
	estimate, err := a.store.GetAIEstimate(r.Context(), claims.UserID, estimateID)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			httpx.WriteError(w, http.StatusNotFound, "estimate not found")
			return
		}
		a.logger.Error("load ai estimate", "error", err)
		httpx.WriteError(w, http.StatusInternalServerError, "could not load estimate")
		return
	}
	if err := a.ensureAIEstimateFoods(r.Context(), claims.UserID, &estimate); err != nil {
		a.logger.Error("create ai foods", "error", err)
		httpx.WriteError(w, http.StatusInternalServerError, "could not prepare estimate foods")
		return
	}
	logID, err := uuid.NewV7()
	if err != nil {
		httpx.WriteError(w, http.StatusInternalServerError, "could not save estimate")
		return
	}
	params, err := buildMealLogFromEstimate(logID, estimate)
	if err != nil {
		httpx.WriteError(w, http.StatusUnprocessableEntity, err.Error())
		return
	}
	log, err := a.store.CreateMealLog(r.Context(), params)
	if err != nil {
		a.logger.Error("accept ai estimate", "error", err)
		httpx.WriteError(w, http.StatusInternalServerError, "could not save meal log")
		return
	}
	if err := a.store.MarkAIEstimateAccepted(r.Context(), claims.UserID, estimate.ID, log.ID); err != nil {
		a.logger.Error("mark ai estimate accepted", "error", err)
		httpx.WriteError(w, http.StatusInternalServerError, "could not mark estimate accepted")
		return
	}
	accepted, _ := a.store.GetAIEstimate(r.Context(), claims.UserID, estimate.ID)
	httpx.WriteJSON(w, http.StatusCreated, map[string]any{"estimate": accepted, "log": log})
}

func (a *App) handleAIChat(w http.ResponseWriter, r *http.Request) {
	claims := authFromContext(r.Context())
	if a.ai == nil {
		httpx.WriteError(w, http.StatusServiceUnavailable, "AI assistant is not configured")
		return
	}
	var request aiChatRequest
	if !a.readAndValidate(w, r, &request) {
		return
	}
	conversationID := request.ConversationID
	if conversationID == nil {
		created, err := a.store.CreateAIConversation(r.Context(), claims.UserID, request.EstimateID)
		if err != nil {
			a.logger.Error("create ai conversation", "error", err)
			httpx.WriteError(w, http.StatusInternalServerError, "could not create conversation")
			return
		}
		conversationID = &created
	}
	var estimateForPrompt *aipkg.MealEstimate
	if request.EstimateID != nil {
		estimate, err := a.store.GetAIEstimate(r.Context(), claims.UserID, *request.EstimateID)
		if err == nil {
			converted := dbEstimateToAI(estimate)
			estimateForPrompt = &converted
		}
	}
	start := time.Now()
	response, err := a.ai.Chat(r.Context(), aipkg.ChatRequest{
		Message:  request.Message,
		Locale:   "en",
		Estimate: estimateForPrompt,
	})
	latency := int(time.Since(start).Milliseconds())
	if err != nil {
		a.logger.Error("ai chat", "error", err)
		_ = a.writeAIUsage(r.Context(), &claims.UserID, nil, conversationID, "chat", "error", a.cfg.GeminiModelFast, latency, err)
		httpx.WriteError(w, http.StatusBadGateway, "I could not answer right now. Try again in a moment.")
		return
	}
	_ = a.store.AddAIConversationMessage(r.Context(), *conversationID, claims.UserID, "user", request.Message, "")
	_ = a.store.AddAIConversationMessage(r.Context(), *conversationID, claims.UserID, "assistant", response.Message, response.Model)
	_ = a.writeAIUsage(r.Context(), &claims.UserID, nil, conversationID, "chat", "ok", response.Model, latency, nil)
	httpx.WriteJSON(w, http.StatusOK, map[string]any{
		"conversation_id": conversationID,
		"model":           response.Model,
		"message":         response.Message,
		"warnings":        response.Warnings,
	})
}

func (a *App) handleAdminAIEstimates(w http.ResponseWriter, r *http.Request) {
	estimates, err := a.store.ListAdminAIEstimates(r.Context(), r.URL.Query().Get("status"), parseLimit(r, 50))
	if err != nil {
		a.logger.Error("admin ai estimates", "error", err)
		httpx.WriteError(w, http.StatusInternalServerError, "could not list AI estimates")
		return
	}
	httpx.WriteJSON(w, http.StatusOK, map[string]any{"estimates": estimates})
}

func (a *App) handleAdminAIUsage(w http.ResponseWriter, r *http.Request) {
	usage, err := a.store.AIUsageSummary(r.Context())
	if err != nil {
		a.logger.Error("admin ai usage", "error", err)
		httpx.WriteError(w, http.StatusInternalServerError, "could not load AI usage")
		return
	}
	httpx.WriteJSON(w, http.StatusOK, usage)
}

func (a *App) handleAdminReviewAIEstimate(w http.ResponseWriter, r *http.Request) {
	claims := authFromContext(r.Context())
	estimateID, ok := parseUUIDURLParam(w, r, "estimateID")
	if !ok {
		return
	}
	var request reviewAIEstimateRequest
	if !a.readAndValidate(w, r, &request) {
		return
	}
	estimate, err := a.store.ReviewAIEstimate(r.Context(), claims.UserID, estimateID, strings.TrimSpace(request.Status), strings.TrimSpace(request.Notes))
	if err != nil {
		a.logger.Error("admin review ai estimate", "error", err)
		httpx.WriteError(w, http.StatusInternalServerError, "could not review AI estimate")
		return
	}
	httpx.WriteJSON(w, http.StatusOK, estimate)
}

func (a *App) enrichEstimateItems(ctx context.Context, estimate *aipkg.MealEstimate) {
	for i := range estimate.Items {
		food, ok, err := a.store.FindBestFoodMatch(ctx, estimate.Items[i].Name)
		if err != nil || !ok {
			continue
		}
		id := food.ID.String()
		estimate.Items[i].MatchedFoodID = &id
		estimate.Items[i].Source = "matched_catalog"
		applyFoodNutrition(&estimate.Items[i], food)
	}
}

func applyFoodNutrition(item *aipkg.MealEstimateItem, food db.FoodDetail) {
	factor := item.QuantityG / 100
	for _, nutrient := range food.Nutrients {
		amount := nutrient.AmountPer100G * factor
		switch strings.ToLower(nutrient.Code) {
		case "calories":
			if amount > 0 {
				item.CaloriesKcal = amount
			}
		case "protein":
			if amount > 0 {
				item.ProteinG = amount
			}
		case "carbs":
			if amount > 0 {
				item.CarbsG = amount
			}
		case "fat":
			if amount > 0 {
				item.FatG = amount
			}
		}
	}
}

func aiItemsToDB(estimateID, userID uuid.UUID, items []aipkg.MealEstimateItem) []db.AIEstimateItem {
	out := make([]db.AIEstimateItem, 0, len(items))
	for i, item := range items {
		itemID, _ := uuid.NewV7()
		var matchedFoodID *uuid.UUID
		if item.MatchedFoodID != nil {
			if parsed, err := uuid.Parse(*item.MatchedFoodID); err == nil {
				matchedFoodID = &parsed
			}
		}
		out = append(out, db.AIEstimateItem{
			ID:            itemID,
			EstimateID:    estimateID,
			UserID:        userID,
			Name:          strings.TrimSpace(item.Name),
			MatchedFoodID: matchedFoodID,
			QuantityG:     item.QuantityG,
			CaloriesKcal:  item.CaloriesKcal,
			ProteinG:      item.ProteinG,
			CarbsG:        item.CarbsG,
			FatG:          item.FatG,
			Confidence:    item.Confidence,
			Source:        defaultString(item.Source, "ai_estimate"),
			Position:      i,
		})
	}
	return out
}

func dbEstimateToAI(estimate db.AIEstimate) aipkg.MealEstimate {
	items := make([]aipkg.MealEstimateItem, 0, len(estimate.Items))
	for _, item := range estimate.Items {
		var matched *string
		if item.MatchedFoodID != nil {
			value := item.MatchedFoodID.String()
			matched = &value
		}
		items = append(items, aipkg.MealEstimateItem{
			ID:            item.ID.String(),
			Name:          item.Name,
			MatchedFoodID: matched,
			QuantityG:     item.QuantityG,
			CaloriesKcal:  item.CaloriesKcal,
			ProteinG:      item.ProteinG,
			CarbsG:        item.CarbsG,
			FatG:          item.FatG,
			Confidence:    item.Confidence,
			Source:        item.Source,
		})
	}
	return aipkg.MealEstimate{
		EstimateID: estimate.ID.String(),
		Status:     estimate.Status,
		Model:      estimate.Model,
		Confidence: estimate.Confidence,
		Items:      items,
		Questions:  estimate.Questions,
		Warnings:   estimate.Warnings,
	}
}

func (a *App) ensureAIEstimateFoods(ctx context.Context, userID uuid.UUID, estimate *db.AIEstimate) error {
	changed := false
	for i := range estimate.Items {
		if estimate.Items[i].MatchedFoodID != nil {
			continue
		}
		foodID, err := uuid.NewV7()
		if err != nil {
			return err
		}
		item := estimate.Items[i]
		nutrients := nutrientsFromEstimateItem(item)
		food, err := a.store.CreateFood(ctx, db.CreateFoodParams{
			ID:           foodID,
			OwnerUserID:  userID,
			Name:         item.Name,
			Category:     "ai_estimate",
			ServingSizeG: item.QuantityG,
			Source:       "ai_estimate",
			Nutrients:    nutrients,
		})
		if err != nil {
			return err
		}
		estimate.Items[i].MatchedFoodID = &food.ID
		estimate.Items[i].Source = "ai_estimate"
		changed = true
	}
	if changed {
		updated, err := a.store.UpdateAIEstimateItems(ctx, db.UpdateAIEstimateItemsParams{
			ID:     estimate.ID,
			UserID: userID,
			Items:  estimate.Items,
		})
		if err != nil {
			return err
		}
		*estimate = updated
	}
	return nil
}

func nutrientsFromEstimateItem(item db.AIEstimateItem) []db.CreateFoodNutrient {
	if item.QuantityG <= 0 {
		item.QuantityG = 100
	}
	scale := 100 / item.QuantityG
	nutrients := []db.CreateFoodNutrient{}
	add := func(code string, amount float64) {
		if amount > 0 {
			nutrients = append(nutrients, db.CreateFoodNutrient{Code: code, AmountPer100G: amount * scale})
		}
	}
	add("Calories", item.CaloriesKcal)
	add("Protein", item.ProteinG)
	add("Carbs", item.CarbsG)
	add("Fat", item.FatG)
	return nutrients
}

func buildMealLogFromEstimate(logID uuid.UUID, estimate db.AIEstimate) (db.CreateMealLogParams, error) {
	if len(estimate.Items) == 0 {
		return db.CreateMealLogParams{}, errors.New("estimate has no items to save")
	}
	items := make([]db.CreateMealLogItem, 0, len(estimate.Items))
	for _, item := range estimate.Items {
		if item.MatchedFoodID == nil {
			return db.CreateMealLogParams{}, errors.New("estimate item is not linked to a food")
		}
		itemID, err := uuid.NewV7()
		if err != nil {
			return db.CreateMealLogParams{}, err
		}
		items = append(items, db.CreateMealLogItem{
			ID:       itemID,
			FoodID:   *item.MatchedFoodID,
			ServingG: item.QuantityG,
		})
	}
	return db.CreateMealLogParams{
		ID:       logID,
		UserID:   estimate.UserID,
		LoggedOn: estimate.LoggedOn,
		MealType: estimate.MealType,
		Notes:    stringPtr("Saved from AI meal photo estimate."),
		Items:    items,
	}, nil
}

func (a *App) writeAIUsage(ctx context.Context, userID, estimateID, conversationID *uuid.UUID, operation, status, model string, latencyMS int, err error) error {
	id, idErr := uuid.NewV7()
	if idErr != nil {
		return idErr
	}
	var errorClass *string
	if err != nil {
		value := err.Error()
		if len(value) > 120 {
			value = value[:120]
		}
		errorClass = &value
	}
	return a.store.CreateAIUsageEvent(ctx, db.CreateAIUsageEventParams{
		ID:             id,
		UserID:         userID,
		EstimateID:     estimateID,
		ConversationID: conversationID,
		Provider:       defaultString(a.aiProviderName, "development"),
		Model:          defaultString(model, "development-local-estimator"),
		Operation:      operation,
		Status:         status,
		LatencyMS:      latencyMS,
		ErrorClass:     errorClass,
	})
}

func normalizeMealType(value string) string {
	switch strings.ToLower(strings.TrimSpace(value)) {
	case "breakfast", "lunch", "snack", "dinner", "other":
		return strings.ToLower(strings.TrimSpace(value))
	default:
		return "other"
	}
}

func normalizeLoggedOn(now time.Time, value string) string {
	value = strings.TrimSpace(value)
	if value == "" {
		return now.Format("2006-01-02")
	}
	return value
}

func defaultString(value, fallback string) string {
	value = strings.TrimSpace(value)
	if value == "" {
		return fallback
	}
	return value
}

func trimOptionalString(value string) *string {
	value = strings.TrimSpace(value)
	if value == "" {
		return nil
	}
	return &value
}

func derefString(value *string) string {
	if value == nil {
		return ""
	}
	return *value
}

func stringPtr(value string) *string {
	return &value
}
