package ai

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"path/filepath"
	"slices"
	"strings"
	"time"
)

const (
	MaxMealImageBytes = 7 << 20
	PromptVersion     = "meal-photo-v1"
)

var supportedMealImageTypes = map[string][]string{
	"image/jpeg": {".jpg", ".jpeg"},
	"image/png":  {".png"},
	"image/webp": {".webp"},
	"image/heic": {".heic"},
	"image/heif": {".heif"},
}

type AnalyzeMealPhotoRequest struct {
	ImageBytes  []byte
	ContentType string
	Filename    string
	Question    string
	MealType    string
	Locale      string
	UnitSystem  string
}

type ChatRequest struct {
	Message  string
	Locale   string
	Estimate *MealEstimate
}

type ChatResponse struct {
	Model    string   `json:"model"`
	Message  string   `json:"message"`
	Warnings []string `json:"warnings"`
}

type Provider interface {
	AnalyzeMealPhoto(ctx context.Context, request AnalyzeMealPhotoRequest) (MealEstimate, error)
	Chat(ctx context.Context, request ChatRequest) (ChatResponse, error)
}

type MealEstimate struct {
	EstimateID string             `json:"estimate_id,omitempty"`
	Status     string             `json:"status,omitempty"`
	Model      string             `json:"model,omitempty"`
	Confidence float64            `json:"confidence"`
	Items      []MealEstimateItem `json:"items"`
	Questions  []string           `json:"questions"`
	Warnings   []string           `json:"warnings"`
	RawJSON    json.RawMessage    `json:"-"`
}

type MealEstimateItem struct {
	ID            string  `json:"id,omitempty"`
	Name          string  `json:"name"`
	MatchedFoodID *string `json:"matched_food_id,omitempty"`
	QuantityG     float64 `json:"quantity_g"`
	CaloriesKcal  float64 `json:"calories_kcal"`
	ProteinG      float64 `json:"protein_g"`
	CarbsG        float64 `json:"carbs_g"`
	FatG          float64 `json:"fat_g"`
	Confidence    float64 `json:"confidence"`
	Source        string  `json:"source"`
}

func ValidateMealImage(filename, contentType string, size int64) error {
	if filename == "" || contentType == "" || size <= 0 {
		return errors.New("image file is required")
	}
	contentType = strings.ToLower(strings.TrimSpace(strings.Split(contentType, ";")[0]))
	ext := strings.ToLower(filepath.Ext(filename))
	allowedExts, ok := supportedMealImageTypes[contentType]
	if !ok || !slices.Contains(allowedExts, ext) {
		return fmt.Errorf("unsupported image type %q", contentType)
	}
	if size > MaxMealImageBytes {
		return fmt.Errorf("image is too large: max %d MB", MaxMealImageBytes>>20)
	}
	return nil
}

func ParseProviderEstimate(payload []byte) (MealEstimate, error) {
	payload = []byte(strings.TrimSpace(string(payload)))
	var estimate MealEstimate
	if err := json.Unmarshal(payload, &estimate); err != nil {
		return MealEstimate{}, fmt.Errorf("parse model estimate json: %w", err)
	}
	estimate.RawJSON = append(json.RawMessage(nil), payload...)
	normalizeEstimate(&estimate)
	if len(estimate.Items) == 0 {
		return MealEstimate{}, errors.New("model response did not include any meal items")
	}
	return estimate, nil
}

func normalizeEstimate(estimate *MealEstimate) {
	if estimate.Status == "" {
		estimate.Status = "needs_review"
	}
	estimate.Confidence = clamp01(estimate.Confidence)
	for i := range estimate.Items {
		item := &estimate.Items[i]
		item.Name = strings.TrimSpace(item.Name)
		if item.Name == "" {
			item.Name = "Unknown food"
		}
		item.QuantityG = clampNumber(item.QuantityG, 1, 10000)
		item.CaloriesKcal = clampNumber(item.CaloriesKcal, 0, 10000)
		item.ProteinG = clampNumber(item.ProteinG, 0, 1000)
		item.CarbsG = clampNumber(item.CarbsG, 0, 1000)
		item.FatG = clampNumber(item.FatG, 0, 1000)
		item.Confidence = clamp01(item.Confidence)
		if strings.TrimSpace(item.Source) == "" {
			item.Source = "ai_estimate"
		}
	}
	if estimate.Confidence == 0 && len(estimate.Items) > 0 {
		var total float64
		for _, item := range estimate.Items {
			total += item.Confidence
		}
		estimate.Confidence = clamp01(total / float64(len(estimate.Items)))
	}
	if estimate.Confidence < 0.55 && len(estimate.Questions) == 0 {
		estimate.Questions = append(estimate.Questions, "Can you confirm the main ingredients and approximate portion size?")
	}
	estimate.Warnings = appendUnique(estimate.Warnings, "Estimated from a photo. Edit portions before saving.")
}

func clamp01(value float64) float64 {
	return clampNumber(value, 0, 1)
}

func clampNumber(value, minValue, maxValue float64) float64 {
	if value < minValue {
		return minValue
	}
	if value > maxValue {
		return maxValue
	}
	return value
}

func appendUnique(values []string, value string) []string {
	for _, existing := range values {
		if strings.EqualFold(strings.TrimSpace(existing), value) {
			return values
		}
	}
	return append(values, value)
}

func WithTimeout(parent context.Context, timeout time.Duration) (context.Context, context.CancelFunc) {
	if timeout <= 0 {
		timeout = 30 * time.Second
	}
	return context.WithTimeout(parent, timeout)
}
