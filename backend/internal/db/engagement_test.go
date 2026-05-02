package db

import (
	"testing"

	"github.com/google/uuid"
)

func TestBuildRecommendationsPrioritizesProfileGoals(t *testing.T) {
	foodID := uuid.MustParse("018f0000-0000-7000-8002-000000000101")
	recommendations := buildRecommendations(recommendationProfile{
		Goals: []string{"Iron support"},
	}, []recommendationCandidate{
		{Code: "Ca", Name: "Calcium", Percent: floatPtr(0), FoodID: foodID, FoodName: "Yogurt", Category: "dairy", AmountPer100G: 120},
		{Code: "Fe", Name: "Iron", Percent: floatPtr(0), FoodID: foodID, FoodName: "Lentils", Category: "legumes", AmountPer100G: 7},
	}, 5)

	if len(recommendations) < 2 {
		t.Fatalf("got %d recommendations, want at least 2", len(recommendations))
	}
	if recommendations[0].Code != "Fe" {
		t.Fatalf("first recommendation code = %q, want Fe", recommendations[0].Code)
	}
}

func TestBuildRecommendationsFiltersDietAndAllergens(t *testing.T) {
	meatID := uuid.MustParse("018f0000-0000-7000-8002-000000000103")
	dairyID := uuid.MustParse("018f0000-0000-7000-8002-000000000109")
	soyID := uuid.MustParse("018f0000-0000-7000-8002-000000000114")
	recommendations := buildRecommendations(recommendationProfile{
		DietaryPattern: "Vegan",
		Allergens:      []string{"Dairy"},
	}, []recommendationCandidate{
		{Code: "B12", Name: "Vitamin B12", Percent: floatPtr(0), FoodID: meatID, FoodName: "Beef top sirloin", Category: "meat", AmountPer100G: 5},
		{Code: "B12", Name: "Vitamin B12", Percent: floatPtr(0), FoodID: dairyID, FoodName: "Greek yogurt", Category: "dairy", AmountPer100G: 3},
		{Code: "B12", Name: "Vitamin B12", Percent: floatPtr(0), FoodID: soyID, FoodName: "Fortified tofu", Category: "soy", AmountPer100G: 1},
	}, 5)

	if len(recommendations) != 1 {
		t.Fatalf("got %d recommendations, want 1", len(recommendations))
	}
	if recommendations[0].FoodName != "Fortified tofu" {
		t.Fatalf("food = %q, want Fortified tofu", recommendations[0].FoodName)
	}
}

func TestBuildDailyMealPlanReturnsOrderedMealSlots(t *testing.T) {
	foodID := uuid.MustParse("018f0000-0000-7000-8002-000000000101")
	plan := buildDailyMealPlan("2026-05-02", []Recommendation{
		{Code: "D", Name: "Vitamin D", FoodID: foodID, FoodName: "Salmon", Message: "Try salmon."},
		{Code: "B12", Name: "Vitamin B12", FoodID: foodID, FoodName: "Greek yogurt", Message: "Try yogurt."},
		{Code: "Fe", Name: "Iron", FoodID: foodID, FoodName: "Lentils", Message: "Try lentils."},
		{Code: "Mg", Name: "Magnesium", FoodID: foodID, FoodName: "Almonds", Message: "Try almonds."},
	})

	if plan.Date != "2026-05-02" {
		t.Fatalf("date = %q, want 2026-05-02", plan.Date)
	}
	wantTypes := []string{"breakfast", "lunch", "snack", "dinner"}
	if len(plan.Meals) != len(wantTypes) {
		t.Fatalf("meal slots = %d, want %d", len(plan.Meals), len(wantTypes))
	}
	for i, mealType := range wantTypes {
		if plan.Meals[i].MealType != mealType {
			t.Fatalf("meal %d type = %q, want %q", i, plan.Meals[i].MealType, mealType)
		}
		if len(plan.Meals[i].Items) != 1 {
			t.Fatalf("meal %s item count = %d, want 1", mealType, len(plan.Meals[i].Items))
		}
		if len(plan.Meals[i].FocusNutrients) != 1 {
			t.Fatalf("meal %s focus nutrients = %d, want 1", mealType, len(plan.Meals[i].FocusNutrients))
		}
	}
	if plan.Meals[0].Items[0].FoodName != "Salmon" {
		t.Fatalf("breakfast food = %q, want Salmon", plan.Meals[0].Items[0].FoodName)
	}
	if plan.Meals[3].Items[0].Reason == "" {
		t.Fatal("dinner reason is empty")
	}
}

func floatPtr(value float64) *float64 {
	return &value
}
