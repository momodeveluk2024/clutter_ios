package db

import (
	"encoding/json"
	"testing"
)

func TestFoodSummaryIncludesImageURLInJSON(t *testing.T) {
	imageURL := "https://example.com/chicken.jpg"
	food := FoodSummary{
		Name:      "Chicken breast, cooked, roasted",
		Category:  "poultry",
		ImageURL:  &imageURL,
		Nutrients: []string{"Protein"},
	}

	payload, err := json.Marshal(food)
	if err != nil {
		t.Fatalf("marshal food: %v", err)
	}

	var decoded map[string]any
	if err := json.Unmarshal(payload, &decoded); err != nil {
		t.Fatalf("unmarshal food: %v", err)
	}
	if decoded["image_url"] != imageURL {
		t.Fatalf("image_url = %#v, want %q", decoded["image_url"], imageURL)
	}
}
