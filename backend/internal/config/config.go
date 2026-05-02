package config

import (
	"errors"
	"os"
	"strings"
	"time"

	"github.com/joho/godotenv"
)

type Config struct {
	AppEnv                  string
	HTTPAddr                string
	DatabaseURL             string
	JWTSecret               string
	AccessTokenTTL          time.Duration
	RefreshTokenTTL         time.Duration
	AllowedOrigins          []string
	AIEnabled               bool
	AIProvider              string
	GoogleProject           string
	GoogleLocation          string
	GeminiModelFast         string
	GeminiModelLite         string
	GeminiModelPro          string
	GeminiModelPreview      string
	ClaudeEnabled           bool
	ClaudeModelFallback     string
	ClaudeModelCheap        string
	ClaudeModelPremium      string
	USDAAPIKey              string
	OpenFoodFactsUserAgent  string
	FirebaseCredentialsFile string
	PushSchedulerEnabled    bool
	NotificationJobInterval time.Duration
}

func Load() (Config, error) {
	_ = godotenv.Load()

	cfg := Config{
		AppEnv:                  getEnv("APP_ENV", "development"),
		HTTPAddr:                getEnv("HTTP_ADDR", ":8080"),
		DatabaseURL:             os.Getenv("DATABASE_URL"),
		JWTSecret:               os.Getenv("JWT_SECRET"),
		AccessTokenTTL:          getDurationEnv("ACCESS_TOKEN_TTL", 15*time.Minute),
		RefreshTokenTTL:         getDurationEnv("REFRESH_TOKEN_TTL", 30*24*time.Hour),
		AllowedOrigins:          splitCSV(getEnv("ALLOWED_ORIGINS", "http://localhost:3000,http://localhost:3002,http://localhost:5173")),
		AIEnabled:               getBoolEnv("AI_ENABLED", true),
		AIProvider:              getEnv("AI_PROVIDER", "development"),
		GoogleProject:           getEnv("GOOGLE_CLOUD_PROJECT", ""),
		GoogleLocation:          getEnv("GOOGLE_CLOUD_LOCATION", "global"),
		GeminiModelFast:         getEnv("GEMINI_MODEL_FAST", "gemini-2.5-flash"),
		GeminiModelLite:         getEnv("GEMINI_MODEL_LITE", "gemini-2.5-flash-lite"),
		GeminiModelPro:          getEnv("GEMINI_MODEL_PRO", "gemini-2.5-pro"),
		GeminiModelPreview:      getEnv("GEMINI_MODEL_PREVIEW", "gemini-3.1-pro-preview"),
		ClaudeEnabled:           getBoolEnv("CLAUDE_ENABLED", false),
		ClaudeModelFallback:     getEnv("CLAUDE_MODEL_FALLBACK", "claude-sonnet-4-6"),
		ClaudeModelCheap:        getEnv("CLAUDE_MODEL_CHEAP", "claude-haiku-4-5"),
		ClaudeModelPremium:      getEnv("CLAUDE_MODEL_PREMIUM", "claude-opus-4-7"),
		USDAAPIKey:              getEnv("USDA_API_KEY", ""),
		OpenFoodFactsUserAgent:  getEnv("OPEN_FOOD_FACTS_USER_AGENT", "Nutrimate/1.0 contact@example.com"),
		FirebaseCredentialsFile: getEnv("FIREBASE_CREDENTIALS_FILE", ""),
		PushSchedulerEnabled:    getBoolEnv("PUSH_SCHEDULER_ENABLED", true),
		NotificationJobInterval: getDurationEnv("NOTIFICATION_JOB_INTERVAL", time.Hour),
	}

	if cfg.DatabaseURL == "" {
		return Config{}, errors.New("DATABASE_URL is required")
	}
	if len(cfg.JWTSecret) < 32 {
		return Config{}, errors.New("JWT_SECRET must be at least 32 characters")
	}

	return cfg, nil
}

func getEnv(key, fallback string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return fallback
}

func getDurationEnv(key string, fallback time.Duration) time.Duration {
	value := os.Getenv(key)
	if value == "" {
		return fallback
	}
	parsed, err := time.ParseDuration(value)
	if err != nil {
		return fallback
	}
	return parsed
}

func getBoolEnv(key string, fallback bool) bool {
	value := strings.ToLower(strings.TrimSpace(os.Getenv(key)))
	if value == "" {
		return fallback
	}
	return value == "1" || value == "true" || value == "yes" || value == "on"
}

func splitCSV(value string) []string {
	parts := strings.Split(value, ",")
	out := make([]string, 0, len(parts))
	for _, part := range parts {
		part = strings.TrimSpace(part)
		if part != "" {
			out = append(out, part)
		}
	}
	return out
}
