package ai

import (
	"strings"
	"testing"
)

func TestValidateMealImageAcceptsSupportedImages(t *testing.T) {
	tests := []struct {
		name        string
		filename    string
		contentType string
		size        int64
	}{
		{name: "jpeg", filename: "meal.jpg", contentType: "image/jpeg", size: 1024},
		{name: "png", filename: "meal.png", contentType: "image/png", size: 1024},
		{name: "webp", filename: "meal.webp", contentType: "image/webp", size: 1024},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if err := ValidateMealImage(tt.filename, tt.contentType, tt.size); err != nil {
				t.Fatalf("ValidateMealImage() error = %v", err)
			}
		})
	}
}

func TestValidateMealImageRejectsUnsupportedAndOversizedFiles(t *testing.T) {
	tests := []struct {
		name        string
		filename    string
		contentType string
		size        int64
		want        string
	}{
		{name: "text", filename: "notes.txt", contentType: "text/plain", size: 16, want: "unsupported image type"},
		{name: "oversized", filename: "meal.jpg", contentType: "image/jpeg", size: MaxMealImageBytes + 1, want: "image is too large"},
		{name: "missing", filename: "", contentType: "", size: 0, want: "image file is required"},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := ValidateMealImage(tt.filename, tt.contentType, tt.size)
			if err == nil || !strings.Contains(err.Error(), tt.want) {
				t.Fatalf("ValidateMealImage() error = %v, want containing %q", err, tt.want)
			}
		})
	}
}

func TestParseProviderEstimateRejectsMalformedJSON(t *testing.T) {
	_, err := ParseProviderEstimate([]byte(`{"items":[`))
	if err == nil {
		t.Fatal("ParseProviderEstimate() error = nil, want malformed JSON error")
	}
}

func TestParseProviderEstimateAddsLowConfidenceQuestion(t *testing.T) {
	estimate, err := ParseProviderEstimate([]byte(`{
		"confidence": 0.42,
		"items": [
			{
				"name": "rice and chicken",
				"quantity_g": 280,
				"calories_kcal": 520,
				"protein_g": 34,
				"carbs_g": 62,
				"fat_g": 12,
				"confidence": 0.46,
				"source": "ai_estimate"
			}
		],
		"questions": [],
		"warnings": []
	}`))
	if err != nil {
		t.Fatalf("ParseProviderEstimate() error = %v", err)
	}
	if estimate.Confidence != 0.42 {
		t.Fatalf("Confidence = %v, want 0.42", estimate.Confidence)
	}
	if len(estimate.Questions) == 0 {
		t.Fatal("Questions is empty, want low-confidence clarifying question")
	}
	if len(estimate.Warnings) == 0 {
		t.Fatal("Warnings is empty, want estimate warning")
	}
}
