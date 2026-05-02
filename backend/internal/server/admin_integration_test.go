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

	"github.com/momodeveluk2024/nutrivita-flutter/backend/internal/config"
	"github.com/momodeveluk2024/nutrivita-flutter/backend/internal/db"
	"github.com/pressly/goose/v3"
	"github.com/testcontainers/testcontainers-go"
	"github.com/testcontainers/testcontainers-go/modules/postgres"
	"github.com/testcontainers/testcontainers-go/wait"

	_ "github.com/jackc/pgx/v5/stdlib"
)

func TestIntegrationAdminAPI(t *testing.T) {
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

	store := db.NewStore(pool)
	app := New(config.Config{
		AppEnv:          "test",
		HTTPAddr:        ":0",
		DatabaseURL:     databaseURL,
		JWTSecret:       "this-is-a-test-secret-with-enough-length",
		AccessTokenTTL:  15 * time.Minute,
		RefreshTokenTTL: 30 * 24 * time.Hour,
		AllowedOrigins:  []string{"*"},
	}, store, slog.New(slog.NewTextHandler(os.Stdout, nil)))
	app.authLimit = newRateLimiter(100, time.Minute)

	server := httptest.NewServer(app.Routes())
	defer server.Close()

	regularID := signupForTest(t, server.URL, "regular@example.com", "password123", "Regular User")
	adminID := signupForTest(t, server.URL, "admin@example.com", "password123", "Ada Admin")
	if err := store.SetUserRole(ctx, adminID, "admin"); err != nil {
		t.Fatalf("promote admin: %v", err)
	}

	postJSONForTest(t, server.URL+"/v1/admin/auth/login", map[string]string{
		"email":    "regular@example.com",
		"password": "password123",
	}, http.StatusForbidden)

	loginResponse := postJSONForTest(t, server.URL+"/v1/admin/auth/login", map[string]string{
		"email":    "admin@example.com",
		"password": "password123",
	}, http.StatusOK)
	var loginBody struct {
		Access string `json:"access"`
		User   struct {
			ID    string `json:"id"`
			Role  string `json:"role"`
			Email string `json:"email"`
		} `json:"user"`
	}
	if err := json.NewDecoder(loginResponse.Body).Decode(&loginBody); err != nil {
		t.Fatalf("decode admin login: %v", err)
	}
	if loginBody.Access == "" || loginBody.User.Role != "admin" || loginBody.User.Email != "admin@example.com" {
		t.Fatalf("unexpected admin login response: %#v", loginBody)
	}

	authedGetForTest(t, server.URL+"/v1/admin/me", "", http.StatusUnauthorized)
	authedGetForTest(t, server.URL+"/v1/admin/me", loginBody.Access, http.StatusOK)

	usersResponse := authedGetForTest(t, server.URL+"/v1/admin/users?limit=10", loginBody.Access, http.StatusOK)
	var usersBody struct {
		Users []struct {
			ID    string `json:"id"`
			Email string `json:"email"`
			Role  string `json:"role"`
		} `json:"users"`
	}
	if err := json.NewDecoder(usersResponse.Body).Decode(&usersBody); err != nil {
		t.Fatalf("decode users: %v", err)
	}
	if len(usersBody.Users) < 2 {
		t.Fatalf("expected users list to include seeded signups, got %#v", usersBody)
	}

	authedGetForTest(t, server.URL+"/v1/admin/users/"+regularID.String(), loginBody.Access, http.StatusOK)
	authedGetForTest(t, server.URL+"/v1/admin/overview", loginBody.Access, http.StatusOK)
	authedGetForTest(t, server.URL+"/v1/admin/logs?limit=10", loginBody.Access, http.StatusOK)
	authedGetForTest(t, server.URL+"/v1/admin/nutrients", loginBody.Access, http.StatusOK)
	authedGetForTest(t, server.URL+"/v1/admin/foods?limit=10", loginBody.Access, http.StatusOK)
	patchJSONForTest(t, server.URL+"/v1/admin/nutrients/D/dri", loginBody.Access, map[string]float64{"amount": 21}, http.StatusOK)
	patchJSONForTest(t, server.URL+"/v1/admin/foods/018f0000-0000-7000-8002-000000000004", loginBody.Access, map[string]any{
		"category":     "nuts",
		"servingSizeG": 30,
	}, http.StatusOK)
	postJSONAuthedForTest(t, server.URL+"/v1/admin/foods/018f0000-0000-7000-8002-000000000004/verify", loginBody.Access, map[string]string{}, http.StatusOK)
	deleteAuthedForTest(t, server.URL+"/v1/admin/foods/018f0000-0000-7000-8002-000000000006", loginBody.Access, http.StatusNoContent)
	authedGetForTest(t, server.URL+"/v1/admin/reminders", loginBody.Access, http.StatusOK)
	authedGetForTest(t, server.URL+"/v1/admin/audit-log", loginBody.Access, http.StatusOK)
}

func authedGetForTest(t *testing.T, url, access string, wantStatus int) *http.Response {
	t.Helper()
	request, err := http.NewRequest(http.MethodGet, url, nil)
	if err != nil {
		t.Fatalf("new request: %v", err)
	}
	if access != "" {
		request.Header.Set("Authorization", "Bearer "+access)
	}
	response, err := http.DefaultClient.Do(request)
	if err != nil {
		t.Fatalf("get %s: %v", url, err)
	}
	t.Cleanup(func() {
		_ = response.Body.Close()
	})
	if response.StatusCode != wantStatus {
		t.Fatalf("%s status: got %d want %d", url, response.StatusCode, wantStatus)
	}
	return response
}

func patchJSONForTest(t *testing.T, url, access string, body any, wantStatus int) *http.Response {
	t.Helper()
	payload, err := json.Marshal(body)
	if err != nil {
		t.Fatalf("marshal request: %v", err)
	}
	request, err := http.NewRequest(http.MethodPatch, url, bytes.NewReader(payload))
	if err != nil {
		t.Fatalf("new patch request: %v", err)
	}
	request.Header.Set("Content-Type", "application/json")
	if access != "" {
		request.Header.Set("Authorization", "Bearer "+access)
	}
	response, err := http.DefaultClient.Do(request)
	if err != nil {
		t.Fatalf("patch %s: %v", url, err)
	}
	t.Cleanup(func() {
		_ = response.Body.Close()
	})
	if response.StatusCode != wantStatus {
		t.Fatalf("%s status: got %d want %d", url, response.StatusCode, wantStatus)
	}
	return response
}

func postJSONAuthedForTest(t *testing.T, url, access string, body any, wantStatus int) *http.Response {
	t.Helper()
	payload, err := json.Marshal(body)
	if err != nil {
		t.Fatalf("marshal request: %v", err)
	}
	request, err := http.NewRequest(http.MethodPost, url, bytes.NewReader(payload))
	if err != nil {
		t.Fatalf("new post request: %v", err)
	}
	request.Header.Set("Content-Type", "application/json")
	if access != "" {
		request.Header.Set("Authorization", "Bearer "+access)
	}
	response, err := http.DefaultClient.Do(request)
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

func deleteAuthedForTest(t *testing.T, url, access string, wantStatus int) *http.Response {
	t.Helper()
	request, err := http.NewRequest(http.MethodDelete, url, nil)
	if err != nil {
		t.Fatalf("new delete request: %v", err)
	}
	if access != "" {
		request.Header.Set("Authorization", "Bearer "+access)
	}
	response, err := http.DefaultClient.Do(request)
	if err != nil {
		t.Fatalf("delete %s: %v", url, err)
	}
	t.Cleanup(func() {
		_ = response.Body.Close()
	})
	if response.StatusCode != wantStatus {
		t.Fatalf("%s status: got %d want %d", url, response.StatusCode, wantStatus)
	}
	return response
}
