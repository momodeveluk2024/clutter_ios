package notifications

import (
	"testing"

	"github.com/google/uuid"
)

func TestBuildRecommendationPushMessageIncludesImageAndRoute(t *testing.T) {
	userID := uuid.MustParse("018f0000-0000-7000-8000-000000000001")
	foodID := uuid.MustParse("018f0000-0000-7000-8002-000000000001")

	message := BuildRecommendationPushMessage(RecommendationPushContent{
		UserID:       userID,
		NutrientName: "Vitamin D",
		FoodID:       foodID,
		FoodName:     "Salmon, Atlantic",
		FoodImageURL: "https://example.com/salmon.jpg",
	})

	if message.UserID != userID {
		t.Fatalf("UserID = %s, want %s", message.UserID, userID)
	}
	if message.Title != "Try Salmon, Atlantic today" {
		t.Fatalf("Title = %q", message.Title)
	}
	if message.Body != "You are below target for Vitamin D. Salmon, Atlantic can help close the gap." {
		t.Fatalf("Body = %q", message.Body)
	}
	if message.ImageURL == nil || *message.ImageURL != "https://example.com/salmon.jpg" {
		t.Fatalf("ImageURL = %v", message.ImageURL)
	}
	if message.Data["type"] != "recommendation" {
		t.Fatalf("type = %q", message.Data["type"])
	}
	if message.Data["route"] != "/app/food/018f0000-0000-7000-8002-000000000001" {
		t.Fatalf("route = %q", message.Data["route"])
	}
}
