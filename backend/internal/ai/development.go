package ai

import (
	"context"
	"strings"
)

type DevelopmentProvider struct{}

func NewDevelopmentProvider() DevelopmentProvider {
	return DevelopmentProvider{}
}

func (DevelopmentProvider) AnalyzeMealPhoto(ctx context.Context, request AnalyzeMealPhotoRequest) (MealEstimate, error) {
	if err := ctx.Err(); err != nil {
		return MealEstimate{}, err
	}
	name := "mixed meal"
	if strings.Contains(strings.ToLower(request.Question), "protein") {
		name = "protein-focused mixed meal"
	}
	estimate := MealEstimate{
		Status:     "needs_review",
		Model:      "development-local-estimator",
		Confidence: 0.58,
		Items: []MealEstimateItem{
			{
				Name:         name,
				QuantityG:    320,
				CaloriesKcal: 520,
				ProteinG:     34,
				CarbsG:       58,
				FatG:         14,
				Confidence:   0.58,
				Source:       "ai_estimate",
			},
		},
		Questions: []string{"Confirm the portion size before saving this estimate."},
		Warnings:  []string{"Development estimate only. Configure Vertex AI for production analysis."},
	}
	normalizeEstimate(&estimate)
	return estimate, nil
}

func (DevelopmentProvider) Chat(ctx context.Context, request ChatRequest) (ChatResponse, error) {
	if err := ctx.Err(); err != nil {
		return ChatResponse{}, err
	}
	message := strings.TrimSpace(request.Message)
	if message == "" {
		message = "Ask about protein, calories, swaps, or portion size."
	}
	return ChatResponse{
		Model:   "development-local-estimator",
		Message: "This is an estimate, not medical advice. Based on the saved context, review portions first, then use the protein, carbs, and fat totals as a guide.",
		Warnings: []string{
			"Nutrition guidance is general and cannot replace a clinician or dietitian.",
		},
	}, nil
}
