package server

import (
	"bytes"
	"context"
	"database/sql"
	"encoding/json"
	"log/slog"
	"net/http"
	"net/http/httptest"
	"os"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/momodeveluk2024/nutrivita-flutter/backend/internal/auth"
	"github.com/momodeveluk2024/nutrivita-flutter/backend/internal/config"
	"github.com/momodeveluk2024/nutrivita-flutter/backend/internal/db"
	"github.com/pressly/goose/v3"
	"github.com/testcontainers/testcontainers-go"
	"github.com/testcontainers/testcontainers-go/modules/postgres"
	"github.com/testcontainers/testcontainers-go/wait"

	_ "github.com/jackc/pgx/v5/stdlib"
)

func TestIntegrationAuthLifecycle(t *testing.T) {
	if os.Getenv("NUTRIVITA_RUN_INTEGRATION") != "1" {
		t.Skip("set NUTRIVITA_RUN_INTEGRATION=1 to run testcontainers integration tests")
	}

	ctx := context.Background()
	container, err := postgres.Run(
		ctx,
		"postgres:17-alpine",
		postgres.WithDatabase("nutrivita"),
		postgres.WithUsername("nutrivita"),
		postgres.WithPassword("nutrivita"),
		testcontainers.WithAdditionalWaitStrategy(
			wait.ForLog("database system is ready to accept connections").
				WithOccurrence(2).
				WithStartupTimeout(30*time.Second),
		),
	)
	if err != nil {
		t.Fatalf("start postgres: %v", err)
	}
	defer container.Terminate(ctx)

	databaseURL, err := container.ConnectionString(ctx, "sslmode=disable")
	if err != nil {
		t.Fatalf("connection string: %v", err)
	}

	sqlDB, err := sql.Open("pgx", databaseURL)
	if err != nil {
		t.Fatalf("open sql db: %v", err)
	}
	defer sqlDB.Close()

	if err := goose.SetDialect("postgres"); err != nil {
		t.Fatalf("set goose dialect: %v", err)
	}
	if err := goose.Up(sqlDB, "../../migrations"); err != nil {
		t.Fatalf("migrate: %v", err)
	}

	pool, err := db.Open(ctx, databaseURL)
	if err != nil {
		t.Fatalf("open pool: %v", err)
	}
	defer pool.Close()

	app := New(config.Config{
		AppEnv:          "test",
		HTTPAddr:        ":0",
		DatabaseURL:     databaseURL,
		JWTSecret:       "this-is-a-test-secret-with-enough-length",
		AccessTokenTTL:  15 * time.Minute,
		RefreshTokenTTL: 30 * 24 * time.Hour,
		AllowedOrigins:  []string{"*"},
	}, db.NewStore(pool), slog.New(slog.NewTextHandler(os.Stdout, nil)))
	app.authLimit = newRateLimiter(100, time.Minute)

	server := httptest.NewServer(app.Routes())
	defer server.Close()

	userID := signupForTest(t, server.URL, "amelia@example.com", "password123", "Amelia Chen")

	var body struct {
		Access  string `json:"access"`
		Refresh string `json:"refresh"`
	}
	body = loginForTest(t, server.URL, "amelia@example.com", "password123", http.StatusOK)
	if body.Access == "" || body.Refresh == "" {
		t.Fatal("expected access and refresh tokens")
	}

	expiredEmailToken, expiredEmailHash, err := auth.NewRefreshToken()
	if err != nil {
		t.Fatalf("new expired email token: %v", err)
	}
	if err := app.store.CreateEmailVerification(ctx, userID, expiredEmailHash, time.Now().Add(-time.Minute)); err != nil {
		t.Fatalf("create expired email verification: %v", err)
	}
	postJSONForTest(t, server.URL+"/v1/auth/verify-email", map[string]string{"token": expiredEmailToken}, http.StatusUnauthorized)

	emailToken, emailHash, err := auth.NewRefreshToken()
	if err != nil {
		t.Fatalf("new email token: %v", err)
	}
	if err := app.store.CreateEmailVerification(ctx, userID, emailHash, time.Now().Add(time.Hour)); err != nil {
		t.Fatalf("create email verification: %v", err)
	}
	postJSONForTest(t, server.URL+"/v1/auth/verify-email", map[string]string{"token": emailToken}, http.StatusNoContent)
	postJSONForTest(t, server.URL+"/v1/auth/verify-email", map[string]string{"token": emailToken}, http.StatusUnauthorized)

	user, err := app.store.GetUserByID(ctx, userID)
	if err != nil {
		t.Fatalf("get verified user: %v", err)
	}
	if user.EmailVerifiedAt == nil {
		t.Fatal("expected email_verified_at after verification")
	}

	expiredResetToken, expiredResetHash, err := auth.NewRefreshToken()
	if err != nil {
		t.Fatalf("new expired reset token: %v", err)
	}
	if err := app.store.CreatePasswordReset(ctx, userID, expiredResetHash, time.Now().Add(-time.Minute)); err != nil {
		t.Fatalf("create expired password reset: %v", err)
	}
	postJSONForTest(t, server.URL+"/v1/auth/reset-password", map[string]string{
		"token":        expiredResetToken,
		"new_password": "new-password-123",
	}, http.StatusUnauthorized)

	resetToken, resetHash, err := auth.NewRefreshToken()
	if err != nil {
		t.Fatalf("new reset token: %v", err)
	}
	if err := app.store.CreatePasswordReset(ctx, userID, resetHash, time.Now().Add(time.Hour)); err != nil {
		t.Fatalf("create password reset: %v", err)
	}
	postJSONForTest(t, server.URL+"/v1/auth/reset-password", map[string]string{
		"token":        resetToken,
		"new_password": "new-password-123",
	}, http.StatusNoContent)
	postJSONForTest(t, server.URL+"/v1/auth/reset-password", map[string]string{
		"token":        resetToken,
		"new_password": "new-password-123",
	}, http.StatusUnauthorized)
	loginForTest(t, server.URL, "amelia@example.com", "password123", http.StatusUnauthorized)
	loginForTest(t, server.URL, "amelia@example.com", "new-password-123", http.StatusOK)

	signupForTest(t, server.URL, "lockout@example.com", "password123", "Locked User")
	for i := 0; i < 5; i++ {
		loginForTest(t, server.URL, "lockout@example.com", "bad-password", http.StatusUnauthorized)
	}
	loginForTest(t, server.URL, "lockout@example.com", "password123", http.StatusTooManyRequests)
}

func signupForTest(t *testing.T, baseURL, email, password, displayName string) uuid.UUID {
	t.Helper()
	response := postJSONForTest(t, baseURL+"/v1/auth/signup", map[string]string{
		"email":        email,
		"password":     password,
		"display_name": displayName,
	}, http.StatusCreated)

	var body struct {
		Access  string `json:"access"`
		Refresh string `json:"refresh"`
		User    struct {
			ID uuid.UUID `json:"id"`
		} `json:"user"`
	}
	if err := json.NewDecoder(response.Body).Decode(&body); err != nil {
		t.Fatalf("decode signup: %v", err)
	}
	if body.Access == "" || body.Refresh == "" || body.User.ID == uuid.Nil {
		t.Fatalf("expected signup tokens and user id, got %#v", body)
	}
	return body.User.ID
}

func loginForTest(t *testing.T, baseURL, email, password string, wantStatus int) struct {
	Access  string `json:"access"`
	Refresh string `json:"refresh"`
} {
	t.Helper()
	response := postJSONForTest(t, baseURL+"/v1/auth/login", map[string]string{
		"email":    email,
		"password": password,
	}, wantStatus)

	var body struct {
		Access  string `json:"access"`
		Refresh string `json:"refresh"`
	}
	if response.StatusCode == http.StatusOK {
		if err := json.NewDecoder(response.Body).Decode(&body); err != nil {
			t.Fatalf("decode login: %v", err)
		}
	}
	return body
}

func postJSONForTest(t *testing.T, url string, body any, wantStatus int) *http.Response {
	t.Helper()
	payload, err := json.Marshal(body)
	if err != nil {
		t.Fatalf("marshal request: %v", err)
	}
	response, err := http.Post(url, "application/json", bytes.NewReader(payload))
	if err != nil {
		t.Fatalf("post %s: %v", url, err)
	}
	t.Cleanup(func() {
		_ = response.Body.Close()
	})
	if response.StatusCode != wantStatus {
		t.Fatalf("%s status: got %d want %d", url, response.StatusCode, wantStatus)
	}
	return response
}
