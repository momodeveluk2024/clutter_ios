package server

import (
	"bytes"
	"context"
	"database/sql"
	"encoding/json"
	"io"
	"log/slog"
	"mime/multipart"
	"net/http"
	"net/http/httptest"
	"net/textproto"
	"os"
	"strings"
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

func TestIntegrationProfileAvatarUpload(t *testing.T) {
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
	}, db.NewStore(pool), slog.New(slog.NewTextHandler(io.Discard, nil)))
	app.authLimit = newRateLimiter(100, time.Minute)
	t.Setenv("TMPDIR", t.TempDir())

	server := httptest.NewServer(app.Routes())
	defer server.Close()

	signupForTest(t, server.URL, "avatar@example.com", "password123", "Avatar User")
	login := loginForTest(t, server.URL, "avatar@example.com", "password123", http.StatusOK)

	uploadProfileAvatarForTest(t, server.URL+"/v1/me/avatar", "", "face.png", "image/png", []byte("png"), http.StatusUnauthorized)
	uploadProfileAvatarForTest(t, server.URL+"/v1/me/avatar", login.Access, "notes.txt", "text/plain", []byte("nope"), http.StatusUnsupportedMediaType)
	uploadProfileAvatarForTest(t, server.URL+"/v1/me/avatar", login.Access, "", "", nil, http.StatusBadRequest)

	response := uploadProfileAvatarForTest(t, server.URL+"/v1/me/avatar", login.Access, "face.png", "image/png", []byte("png"), http.StatusOK)
	var body struct {
		AvatarURL string `json:"avatar_url"`
	}
	if err := json.NewDecoder(response.Body).Decode(&body); err != nil {
		t.Fatalf("decode upload response: %v", err)
	}
	if !strings.Contains(body.AvatarURL, "/uploads/avatars/") || !strings.HasSuffix(body.AvatarURL, "face.png") {
		t.Fatalf("avatar_url = %q, want local avatar upload URL", body.AvatarURL)
	}
}

func uploadProfileAvatarForTest(t *testing.T, url, access, filename, contentType string, content []byte, wantStatus int) *http.Response {
	t.Helper()
	var body bytes.Buffer
	writer := multipart.NewWriter(&body)
	if filename != "" {
		header := make(textproto.MIMEHeader)
		header.Set("Content-Disposition", `form-data; name="image"; filename="`+filename+`"`)
		if contentType == "" {
			contentType = "application/octet-stream"
		}
		header.Set("Content-Type", contentType)
		part, err := writer.CreatePart(header)
		if err != nil {
			t.Fatalf("create form file: %v", err)
		}
		if _, err := part.Write(content); err != nil {
			t.Fatalf("write form file: %v", err)
		}
	}
	if err := writer.Close(); err != nil {
		t.Fatalf("close multipart: %v", err)
	}

	request, err := http.NewRequest(http.MethodPost, url, &body)
	if err != nil {
		t.Fatalf("new upload request: %v", err)
	}
	request.Header.Set("Content-Type", writer.FormDataContentType())
	if access != "" {
		request.Header.Set("Authorization", "Bearer "+access)
	}
	response, err := http.DefaultClient.Do(request)
	if err != nil {
		t.Fatalf("post upload %s: %v", url, err)
	}
	t.Cleanup(func() {
		_ = response.Body.Close()
	})
	if response.StatusCode != wantStatus {
		t.Fatalf("%s status: got %d want %d", url, response.StatusCode, wantStatus)
	}
	return response
}
