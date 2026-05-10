package db

import (
	"context"
	"encoding/json"
	"errors"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
)

type AIEstimate struct {
	ID             uuid.UUID        `json:"estimate_id"`
	UserID         uuid.UUID        `json:"user_id,omitempty"`
	UserEmail      *string          `json:"user_email,omitempty"`
	ImageURL       *string          `json:"image_url,omitempty"`
	ImageKey       *string          `json:"image_key,omitempty"`
	PromptVersion  string           `json:"prompt_version"`
	Provider       string           `json:"provider"`
	Model          string           `json:"model"`
	Status         string           `json:"status"`
	Confidence     float64          `json:"confidence"`
	MealType       string           `json:"meal_type"`
	LoggedOn       string           `json:"logged_on"`
	Locale         string           `json:"locale"`
	UnitSystem     string           `json:"unit_system"`
	Question       *string          `json:"question,omitempty"`
	Questions      []string         `json:"questions"`
	Warnings       []string         `json:"warnings"`
	RawModelJSON   json.RawMessage  `json:"raw_model_json,omitempty"`
	NormalizedJSON json.RawMessage  `json:"normalized_json,omitempty"`
	AcceptedLogID  *uuid.UUID       `json:"accepted_log_id,omitempty"`
	ReviewedBy     *uuid.UUID       `json:"reviewed_by,omitempty"`
	ReviewedStatus *string          `json:"reviewed_status,omitempty"`
	ReviewNotes    *string          `json:"review_notes,omitempty"`
	Items          []AIEstimateItem `json:"items"`
	CreatedAt      time.Time        `json:"created_at"`
	UpdatedAt      time.Time        `json:"updated_at"`
}

type AIEstimateItem struct {
	ID            uuid.UUID  `json:"id"`
	EstimateID    uuid.UUID  `json:"estimate_id,omitempty"`
	UserID        uuid.UUID  `json:"user_id,omitempty"`
	Name          string     `json:"name"`
	MatchedFoodID *uuid.UUID `json:"matched_food_id,omitempty"`
	QuantityG     float64    `json:"quantity_g"`
	CaloriesKcal  float64    `json:"calories_kcal"`
	ProteinG      float64    `json:"protein_g"`
	CarbsG        float64    `json:"carbs_g"`
	FatG          float64    `json:"fat_g"`
	Confidence    float64    `json:"confidence"`
	Source        string     `json:"source"`
	Position      int        `json:"position"`
	CreatedAt     time.Time  `json:"created_at"`
}

type CreateAIEstimateParams struct {
	ID            uuid.UUID
	UserID        uuid.UUID
	ImageURL      *string
	ImageKey      *string
	PromptVersion string
	Provider      string
	Model         string
	MealType      string
	LoggedOn      string
	Locale        string
	UnitSystem    string
	Question      *string
}

type UpdateAIEstimateResultParams struct {
	ID             uuid.UUID
	UserID         uuid.UUID
	Status         string
	Confidence     float64
	Questions      []string
	Warnings       []string
	RawModelJSON   json.RawMessage
	NormalizedJSON json.RawMessage
	Items          []AIEstimateItem
}

type UpdateAIEstimateItemsParams struct {
	ID     uuid.UUID
	UserID uuid.UUID
	Items  []AIEstimateItem
}

type CreateAIUsageEventParams struct {
	ID             uuid.UUID
	UserID         *uuid.UUID
	EstimateID     *uuid.UUID
	ConversationID *uuid.UUID
	Provider       string
	Model          string
	Operation      string
	Status         string
	LatencyMS      int
	InputTokens    int
	OutputTokens   int
	ErrorClass     *string
}

type AIUsageSummary struct {
	Requests       int                 `json:"requests"`
	Failures       int                 `json:"failures"`
	AverageLatency float64             `json:"average_latency_ms"`
	InputTokens    int                 `json:"input_tokens"`
	OutputTokens   int                 `json:"output_tokens"`
	Models         []AIUsageModelTotal `json:"models"`
}

type AIUsageModelTotal struct {
	Model    string `json:"model"`
	Provider string `json:"provider"`
	Requests int    `json:"requests"`
	Failures int    `json:"failures"`
}

func (s *Store) CreateAIEstimate(ctx context.Context, params CreateAIEstimateParams) (AIEstimate, error) {
	if params.ID == uuid.Nil {
		return AIEstimate{}, errors.New("estimate id is required")
	}
	_, err := s.pool.Exec(ctx, `
		INSERT INTO ai_estimates (
			id, user_id, image_url, image_key, prompt_version, provider, model,
			status, meal_type, logged_on, locale, unit_system, question
		)
		VALUES ($1, $2, $3, $4, $5, $6, $7, 'pending', $8, $9::date, $10, $11, $12)
	`, params.ID, params.UserID, params.ImageURL, params.ImageKey, params.PromptVersion, params.Provider, params.Model, params.MealType, params.LoggedOn, params.Locale, params.UnitSystem, params.Question)
	if err != nil {
		return AIEstimate{}, err
	}
	return s.GetAIEstimate(ctx, params.UserID, params.ID)
}

func (s *Store) UpdateAIEstimateResult(ctx context.Context, params UpdateAIEstimateResultParams) (AIEstimate, error) {
	tx, err := s.pool.BeginTx(ctx, pgx.TxOptions{})
	if err != nil {
		return AIEstimate{}, err
	}
	defer tx.Rollback(ctx)

	questions, err := json.Marshal(params.Questions)
	if err != nil {
		return AIEstimate{}, err
	}
	warnings, err := json.Marshal(params.Warnings)
	if err != nil {
		return AIEstimate{}, err
	}
	if len(params.RawModelJSON) == 0 {
		params.RawModelJSON = json.RawMessage(`{}`)
	}
	if len(params.NormalizedJSON) == 0 {
		params.NormalizedJSON = json.RawMessage(`{}`)
	}

	_, err = tx.Exec(ctx, `
		UPDATE ai_estimates
		SET status = $3,
		    confidence = $4,
		    questions = $5,
		    warnings = $6,
		    raw_model_json = $7,
		    normalized_json = $8,
		    updated_at = now()
		WHERE id = $1 AND user_id = $2
	`, params.ID, params.UserID, params.Status, params.Confidence, questions, warnings, params.RawModelJSON, params.NormalizedJSON)
	if err != nil {
		return AIEstimate{}, err
	}
	if _, err := tx.Exec(ctx, `DELETE FROM ai_estimate_items WHERE estimate_id = $1 AND user_id = $2`, params.ID, params.UserID); err != nil {
		return AIEstimate{}, err
	}
	for i, item := range params.Items {
		if item.ID == uuid.Nil {
			item.ID = uuid.New()
		}
		_, err := tx.Exec(ctx, `
			INSERT INTO ai_estimate_items (
				id, estimate_id, user_id, name, matched_food_id, quantity_g,
				calories_kcal, protein_g, carbs_g, fat_g, confidence, source, position
			)
			VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13)
		`, item.ID, params.ID, params.UserID, item.Name, item.MatchedFoodID, item.QuantityG, item.CaloriesKcal, item.ProteinG, item.CarbsG, item.FatG, item.Confidence, item.Source, i)
		if err != nil {
			return AIEstimate{}, err
		}
	}
	if err := tx.Commit(ctx); err != nil {
		return AIEstimate{}, err
	}
	return s.GetAIEstimate(ctx, params.UserID, params.ID)
}

func (s *Store) UpdateAIEstimateItems(ctx context.Context, params UpdateAIEstimateItemsParams) (AIEstimate, error) {
	estimate, err := s.GetAIEstimate(ctx, params.UserID, params.ID)
	if err != nil {
		return AIEstimate{}, err
	}
	if estimate.Status == "accepted" {
		return AIEstimate{}, errors.New("accepted estimates cannot be edited")
	}
	estimate.Items = params.Items
	normalized, _ := json.Marshal(estimate)
	return s.UpdateAIEstimateResult(ctx, UpdateAIEstimateResultParams{
		ID:             params.ID,
		UserID:         params.UserID,
		Status:         "needs_review",
		Confidence:     estimate.Confidence,
		Questions:      estimate.Questions,
		Warnings:       estimate.Warnings,
		RawModelJSON:   estimate.RawModelJSON,
		NormalizedJSON: normalized,
		Items:          params.Items,
	})
}

func (s *Store) MarkAIEstimateAccepted(ctx context.Context, userID, estimateID, logID uuid.UUID) error {
	_, err := s.pool.Exec(ctx, `
		UPDATE ai_estimates
		SET status = 'accepted', accepted_log_id = $3, updated_at = now()
		WHERE id = $1 AND user_id = $2
	`, estimateID, userID, logID)
	return err
}

func (s *Store) GetAIEstimate(ctx context.Context, userID, estimateID uuid.UUID) (AIEstimate, error) {
	estimate, err := s.getAIEstimateBase(ctx, `
		SELECT ae.id, ae.user_id, NULL::text AS user_email, ae.image_url, ae.image_key,
		       ae.prompt_version, ae.provider, ae.model, ae.status,
		       ae.confidence::float8, ae.meal_type, ae.logged_on::text, ae.locale,
		       ae.unit_system, ae.question, ae.questions, ae.warnings,
		       ae.raw_model_json, ae.normalized_json, ae.accepted_log_id,
		       ae.reviewed_by, ae.reviewed_status, ae.review_notes, ae.created_at, ae.updated_at
		FROM ai_estimates ae
		WHERE ae.id = $1 AND ae.user_id = $2
	`, estimateID, userID)
	if err != nil {
		return AIEstimate{}, err
	}
	estimate.Items, err = s.listAIEstimateItems(ctx, estimate.ID)
	return estimate, err
}

func (s *Store) ListAdminAIEstimates(ctx context.Context, status string, limit int) ([]AIEstimate, error) {
	if limit <= 0 || limit > 100 {
		limit = 50
	}
	rows, err := s.pool.Query(ctx, `
		SELECT ae.id, ae.user_id, u.email AS user_email, ae.image_url, ae.image_key,
		       ae.prompt_version, ae.provider, ae.model, ae.status,
		       ae.confidence::float8, ae.meal_type, ae.logged_on::text, ae.locale,
		       ae.unit_system, ae.question, ae.questions, ae.warnings,
		       ae.raw_model_json, ae.normalized_json, ae.accepted_log_id,
		       ae.reviewed_by, ae.reviewed_status, ae.review_notes, ae.created_at, ae.updated_at
		FROM ai_estimates ae
		JOIN users u ON u.id = ae.user_id
		WHERE ($1 = '' OR ae.status = $1)
		ORDER BY ae.created_at DESC
		LIMIT $2
	`, status, limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	estimates := []AIEstimate{}
	for rows.Next() {
		estimate, err := scanAIEstimate(rows)
		if err != nil {
			return nil, err
		}
		estimate.Items, err = s.listAIEstimateItems(ctx, estimate.ID)
		if err != nil {
			return nil, err
		}
		estimates = append(estimates, estimate)
	}
	return estimates, rows.Err()
}

func (s *Store) ReviewAIEstimate(ctx context.Context, adminID, estimateID uuid.UUID, status, notes string) (AIEstimate, error) {
	_, err := s.pool.Exec(ctx, `
		UPDATE ai_estimates
		SET reviewed_by = $2,
		    reviewed_status = $3,
		    review_notes = $4,
		    status = CASE WHEN status = 'accepted' THEN status ELSE 'reviewed' END,
		    updated_at = now()
		WHERE id = $1
	`, estimateID, adminID, status, notes)
	if err != nil {
		return AIEstimate{}, err
	}
	estimate, err := s.getAIEstimateBase(ctx, `
		SELECT ae.id, ae.user_id, u.email AS user_email, ae.image_url, ae.image_key,
		       ae.prompt_version, ae.provider, ae.model, ae.status,
		       ae.confidence::float8, ae.meal_type, ae.logged_on::text, ae.locale,
		       ae.unit_system, ae.question, ae.questions, ae.warnings,
		       ae.raw_model_json, ae.normalized_json, ae.accepted_log_id,
		       ae.reviewed_by, ae.reviewed_status, ae.review_notes, ae.created_at, ae.updated_at
		FROM ai_estimates ae
		JOIN users u ON u.id = ae.user_id
		WHERE ae.id = $1
	`, estimateID)
	if err != nil {
		return AIEstimate{}, err
	}
	estimate.Items, err = s.listAIEstimateItems(ctx, estimate.ID)
	return estimate, err
}

func (s *Store) FindBestFoodMatch(ctx context.Context, name string) (FoodDetail, bool, error) {
	var foodID uuid.UUID
	err := s.pool.QueryRow(ctx, `
		SELECT id
		FROM foods
		WHERE deleted_at IS NULL
		  AND ($1 <> '' AND (name ILIKE '%' || $1 || '%' OR similarity(name, $1) > 0.18))
		ORDER BY similarity(name, $1) DESC, verified DESC, name ASC
		LIMIT 1
	`, name).Scan(&foodID)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return FoodDetail{}, false, nil
		}
		return FoodDetail{}, false, err
	}
	food, err := s.GetFoodDetail(ctx, foodID)
	return food, err == nil, err
}

func (s *Store) CreateAIUsageEvent(ctx context.Context, params CreateAIUsageEventParams) error {
	_, err := s.pool.Exec(ctx, `
		INSERT INTO ai_usage_events (
			id, user_id, estimate_id, conversation_id, provider, model, operation,
			status, latency_ms, input_tokens, output_tokens, error_class
		)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
	`, params.ID, params.UserID, params.EstimateID, params.ConversationID, params.Provider, params.Model, params.Operation, params.Status, params.LatencyMS, params.InputTokens, params.OutputTokens, params.ErrorClass)
	return err
}

func (s *Store) AIUsageSummary(ctx context.Context) (AIUsageSummary, error) {
	var summary AIUsageSummary
	err := s.pool.QueryRow(ctx, `
		SELECT COUNT(*)::int,
		       COUNT(*) FILTER (WHERE status <> 'ok')::int,
		       COALESCE(AVG(latency_ms), 0)::float8,
		       COALESCE(SUM(input_tokens), 0)::int,
		       COALESCE(SUM(output_tokens), 0)::int
		FROM ai_usage_events
		WHERE created_at >= now() - interval '30 days'
	`).Scan(&summary.Requests, &summary.Failures, &summary.AverageLatency, &summary.InputTokens, &summary.OutputTokens)
	if err != nil {
		return AIUsageSummary{}, err
	}
	rows, err := s.pool.Query(ctx, `
		SELECT provider, model, COUNT(*)::int, COUNT(*) FILTER (WHERE status <> 'ok')::int
		FROM ai_usage_events
		WHERE created_at >= now() - interval '30 days'
		GROUP BY provider, model
		ORDER BY COUNT(*) DESC, model ASC
	`)
	if err != nil {
		return AIUsageSummary{}, err
	}
	defer rows.Close()
	for rows.Next() {
		var total AIUsageModelTotal
		if err := rows.Scan(&total.Provider, &total.Model, &total.Requests, &total.Failures); err != nil {
			return AIUsageSummary{}, err
		}
		summary.Models = append(summary.Models, total)
	}
	return summary, rows.Err()
}

func (s *Store) CreateAIConversation(ctx context.Context, userID uuid.UUID, estimateID *uuid.UUID) (uuid.UUID, error) {
	conversationID, err := uuid.NewV7()
	if err != nil {
		return uuid.Nil, err
	}
	_, err = s.pool.Exec(ctx, `
		INSERT INTO ai_conversations (id, user_id, estimate_id)
		VALUES ($1, $2, $3)
	`, conversationID, userID, estimateID)
	return conversationID, err
}

func (s *Store) AddAIConversationMessage(ctx context.Context, conversationID, userID uuid.UUID, role, content, model string) error {
	messageID, err := uuid.NewV7()
	if err != nil {
		return err
	}
	_, err = s.pool.Exec(ctx, `
		INSERT INTO ai_conversation_messages (id, conversation_id, user_id, role, content, model)
		VALUES ($1, $2, $3, $4, $5, $6)
	`, messageID, conversationID, userID, role, content, model)
	return err
}

func (s *Store) getAIEstimateBase(ctx context.Context, query string, args ...any) (AIEstimate, error) {
	row := s.pool.QueryRow(ctx, query, args...)
	return scanAIEstimate(row)
}

type aiEstimateScanner interface {
	Scan(dest ...any) error
}

func scanAIEstimate(row aiEstimateScanner) (AIEstimate, error) {
	var estimate AIEstimate
	var questions []byte
	var warnings []byte
	var raw []byte
	var normalized []byte
	err := row.Scan(
		&estimate.ID,
		&estimate.UserID,
		&estimate.UserEmail,
		&estimate.ImageURL,
		&estimate.ImageKey,
		&estimate.PromptVersion,
		&estimate.Provider,
		&estimate.Model,
		&estimate.Status,
		&estimate.Confidence,
		&estimate.MealType,
		&estimate.LoggedOn,
		&estimate.Locale,
		&estimate.UnitSystem,
		&estimate.Question,
		&questions,
		&warnings,
		&raw,
		&normalized,
		&estimate.AcceptedLogID,
		&estimate.ReviewedBy,
		&estimate.ReviewedStatus,
		&estimate.ReviewNotes,
		&estimate.CreatedAt,
		&estimate.UpdatedAt,
	)
	if err != nil {
		return AIEstimate{}, err
	}
	_ = json.Unmarshal(questions, &estimate.Questions)
	_ = json.Unmarshal(warnings, &estimate.Warnings)
	estimate.RawModelJSON = append(json.RawMessage(nil), raw...)
	estimate.NormalizedJSON = append(json.RawMessage(nil), normalized...)
	estimate.Items = []AIEstimateItem{}
	return estimate, nil
}

func (s *Store) listAIEstimateItems(ctx context.Context, estimateID uuid.UUID) ([]AIEstimateItem, error) {
	rows, err := s.pool.Query(ctx, `
		SELECT id, estimate_id, user_id, name, matched_food_id, quantity_g::float8,
		       calories_kcal::float8, protein_g::float8, carbs_g::float8, fat_g::float8,
		       confidence::float8, source, position, created_at
		FROM ai_estimate_items
		WHERE estimate_id = $1
		ORDER BY position ASC, created_at ASC
	`, estimateID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	items := []AIEstimateItem{}
	for rows.Next() {
		var item AIEstimateItem
		if err := rows.Scan(&item.ID, &item.EstimateID, &item.UserID, &item.Name, &item.MatchedFoodID, &item.QuantityG, &item.CaloriesKcal, &item.ProteinG, &item.CarbsG, &item.FatG, &item.Confidence, &item.Source, &item.Position, &item.CreatedAt); err != nil {
			return nil, err
		}
		items = append(items, item)
	}
	return items, rows.Err()
}

func (s *Store) CountUserAIEstimatesToday(ctx context.Context, userID uuid.UUID) (int, error) {
	var count int
	err := s.pool.QueryRow(ctx, `
		SELECT COUNT(*)::int
		FROM ai_estimates
		WHERE user_id = $1 AND created_at >= CURRENT_DATE
	`, userID).Scan(&count)
	return count, err
}
