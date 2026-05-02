package server

import (
	"context"
	"testing"

	"github.com/google/uuid"
	"github.com/momodeveluk2024/nutrivita-flutter/backend/internal/ai"
	"github.com/momodeveluk2024/nutrivita-flutter/backend/internal/db"
)

func TestBuildMealLogFromEstimateRejectsEmptyAcceptedEstimate(t *testing.T) {
	_, err := buildMealLogFromEstimate(uuid.New(), db.AIEstimate{
		ID:       uuid.New(),
		UserID:   uuid.New(),
		MealType: "lunch",
		LoggedOn: "2026-05-01",
		Items:    []db.AIEstimateItem{},
	})
	if err == nil {
		t.Fatal("buildMealLogFromEstimate() error = nil, want error")
	}
}

func TestDevelopmentAIProviderReturnsSafeEstimate(t *testing.T) {
	provider := ai.NewDevelopmentProvider()
	estimate, err := provider.AnalyzeMealPhoto(context.Background(), ai.AnalyzeMealPhotoRequest{
		ImageBytes:  []byte("fake-image"),
		ContentType: "image/jpeg",
		MealType:   "lunch",
	})
	if err != nil {
		t.Fatalf("AnalyzeMealPhoto() error = %v", err)
	}
	if estimate.Model == "" {
		t.Fatal("Model is empty")
	}
	if len(estimate.Items) == 0 {
		t.Fatal("Items is empty")
	}
	if len(estimate.Warnings) == 0 {
		t.Fatal("Warnings is empty")
	}
}

