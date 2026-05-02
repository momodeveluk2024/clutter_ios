package db

import (
	"encoding/json"
	"testing"

	"github.com/google/uuid"
)

func TestMealLogItemIncludesImageURLInJSON(t *testing.T) {
	imageURL := "https://example.com/almonds.jpg"
	item := MealLogItem{
		ID:       uuid.MustParse("019dc4da-c114-7b3a-a060-3215bd064c36"),
		FoodID:   uuid.MustParse("018f0000-0000-7000-8002-000000000106"),
		FoodName: "Almonds, dry roasted",
		ImageURL: &imageURL,
		ServingG: 100,
	}

	payload, err := json.Marshal(item)
	if err != nil {
		t.Fatalf("marshal meal log item: %v", err)
	}

	var decoded map[string]any
	if err := json.Unmarshal(payload, &decoded); err != nil {
		t.Fatalf("unmarshal meal log item: %v", err)
	}
	if decoded["image_url"] != imageURL {
		t.Fatalf("image_url = %#v, want %q", decoded["image_url"], imageURL)
	}
}
