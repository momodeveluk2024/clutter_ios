package db

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestNamedFoodImageMigrationReplacesRepeatedVegetableImages(t *testing.T) {
	path := filepath.Join("..", "..", "migrations", "00010_named_vitaminfinder_food_images.sql")
	content, err := os.ReadFile(path)
	if err != nil {
		t.Fatalf("read named food image migration: %v", err)
	}

	sql := string(content)
	genericVegetableImage := "https://images.unsplash.com/photo-1540420773420-3366772f4999?auto=format&fit=crop&w=900&q=80"
	for name, id := range map[string]string{
		"Potatoes": "018f0000-0000-7000-8003-000000000051",
		"Onions":   "018f0000-0000-7000-8003-000000000058",
		"Pumpkin":  "018f0000-0000-7000-8003-000000000061",
		"Radishes": "018f0000-0000-7000-8003-000000000073",
		"Parsnips": "018f0000-0000-7000-8003-000000000081",
	} {
		if !strings.Contains(sql, "'"+id+"'::uuid THEN 'https://") {
			t.Fatalf("migration does not include a named image update for %s", name)
		}
	}
	if strings.Contains(sql, genericVegetableImage) {
		t.Fatalf("migration still contains repeated generic vegetable image")
	}
}
