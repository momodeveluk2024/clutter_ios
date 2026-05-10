package ai

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"time"

	"google.golang.org/genai"
)

type GeminiConfig struct {
	Project  string
	Location string
	APIKey   string
	Model    string
	Timeout  time.Duration
}

type GeminiProvider struct {
	client  *genai.Client
	model   string
	timeout time.Duration
}

func NewGeminiProvider(ctx context.Context, cfg GeminiConfig) (*GeminiProvider, error) {
	if strings.TrimSpace(cfg.Model) == "" {
		cfg.Model = "gemini-2.5-flash"
	}
	
	var clientCfg *genai.ClientConfig
	if cfg.APIKey != "" {
		clientCfg = &genai.ClientConfig{
			APIKey:  cfg.APIKey,
			Backend: genai.BackendGeminiAPI,
		}
	} else {
		if strings.TrimSpace(cfg.Project) == "" {
			return nil, errors.New("google cloud project is required")
		}
		if strings.TrimSpace(cfg.Location) == "" {
			return nil, errors.New("google cloud location is required")
		}
		clientCfg = &genai.ClientConfig{
			Project:  cfg.Project,
			Location: cfg.Location,
			Backend:  genai.BackendVertexAI,
		}
	}

	client, err := genai.NewClient(ctx, clientCfg)
	if err != nil {
		return nil, err
	}
	return &GeminiProvider{client: client, model: cfg.Model, timeout: cfg.Timeout}, nil
}

func (p *GeminiProvider) AnalyzeMealPhoto(ctx context.Context, request AnalyzeMealPhotoRequest) (MealEstimate, error) {
	ctx, cancel := WithTimeout(ctx, p.timeout)
	defer cancel()

	contents := []*genai.Content{
		genai.NewContentFromParts([]*genai.Part{
			genai.NewPartFromText(mealPhotoPrompt(request)),
			genai.NewPartFromBytes(request.ImageBytes, request.ContentType),
		}, genai.RoleUser),
	}
	temperature := float32(0.2)
	response, err := p.client.Models.GenerateContent(ctx, p.model, contents, &genai.GenerateContentConfig{
		ResponseMIMEType: "application/json",
		ResponseSchema:   mealEstimateSchema(),
		Temperature:      &temperature,
		MaxOutputTokens:  4096,
	})
	if err != nil {
		return MealEstimate{}, err
	}
	estimate, err := ParseProviderEstimate([]byte(response.Text()))
	if err != nil {
		return MealEstimate{}, err
	}
	estimate.Model = p.model
	return estimate, nil
}

func (p *GeminiProvider) Chat(ctx context.Context, request ChatRequest) (ChatResponse, error) {
	ctx, cancel := WithTimeout(ctx, p.timeout)
	defer cancel()

	prompt := nutritionChatPrompt(request)
	temperature := float32(0.3)
	response, err := p.client.Models.GenerateContent(ctx, p.model, genai.Text(prompt), &genai.GenerateContentConfig{
		Temperature:     &temperature,
		MaxOutputTokens: 1024,
	})
	if err != nil {
		return ChatResponse{}, err
	}
	text := strings.TrimSpace(response.Text())
	if text == "" {
		return ChatResponse{}, errors.New("empty model chat response")
	}
	return ChatResponse{
		Model:   p.model,
		Message: text,
		Warnings: []string{
			"Nutrition guidance is general and cannot replace a clinician or dietitian.",
		},
	}, nil
}

func mealPhotoPrompt(request AnalyzeMealPhotoRequest) string {
	return fmt.Sprintf(`You are Nutrimate's nutrition estimation assistant.
Return only JSON that matches the provided schema.
Identify visible foods in the image, estimate grams conservatively, and include uncertainty.
Never claim exact nutrition from a photo. Unknown oil, sauce, hidden ingredients, and portion size must reduce confidence.
If confidence is below 0.55, ask clarifying questions.
Do not provide medical diagnosis, eating disorder coaching, or extreme diet plans.

Context:
- meal_type: %s
- locale: %s
- unit_system: %s
- user_question: %s

Each item must include name, quantity_g, calories_kcal, protein_g, carbs_g, fat_g, confidence, and source.
Use source "ai_estimate" unless you are explicitly matching a known database item given in context.`, cleanPromptValue(request.MealType), cleanPromptValue(request.Locale), cleanPromptValue(request.UnitSystem), cleanPromptValue(request.Question))
}

func nutritionChatPrompt(request ChatRequest) string {
	estimateJSON := "{}"
	if request.Estimate != nil {
		if payload, err := jsonMarshalNoError(request.Estimate); err == nil {
			estimateJSON = payload
		}
	}
	return fmt.Sprintf(`You are Nutrimate's nutrition assistant.
Answer calmly and briefly. Use the meal estimate context when relevant.
Do not diagnose disease, prescribe treatment, encourage extreme dieting, or provide eating disorder coaching.
Make uncertainty clear when data is estimated.

Locale: %s
Meal estimate context: %s
User message: %s`, cleanPromptValue(request.Locale), estimateJSON, cleanPromptValue(request.Message))
}

func cleanPromptValue(value string) string {
	value = strings.TrimSpace(value)
	value = strings.ReplaceAll(value, "\x00", "")
	if value == "" {
		return "not provided"
	}
	return value
}

func mealEstimateSchema() *genai.Schema {
	return &genai.Schema{
		Type: genai.TypeObject,
		Required: []string{
			"confidence",
			"items",
			"questions",
			"warnings",
		},
		Properties: map[string]*genai.Schema{
			"confidence": {Type: genai.TypeNumber},
			"items": {
				Type: genai.TypeArray,
				Items: &genai.Schema{
					Type: genai.TypeObject,
					Required: []string{
						"name",
						"quantity_g",
						"calories_kcal",
						"protein_g",
						"carbs_g",
						"fat_g",
						"confidence",
						"source",
					},
					Properties: map[string]*genai.Schema{
						"name":          {Type: genai.TypeString},
						"quantity_g":    {Type: genai.TypeNumber},
						"calories_kcal": {Type: genai.TypeNumber},
						"protein_g":     {Type: genai.TypeNumber},
						"carbs_g":       {Type: genai.TypeNumber},
						"fat_g":         {Type: genai.TypeNumber},
						"confidence":    {Type: genai.TypeNumber},
						"source":        {Type: genai.TypeString},
					},
				},
			},
			"questions": {Type: genai.TypeArray, Items: &genai.Schema{Type: genai.TypeString}},
			"warnings":  {Type: genai.TypeArray, Items: &genai.Schema{Type: genai.TypeString}},
		},
	}
}
