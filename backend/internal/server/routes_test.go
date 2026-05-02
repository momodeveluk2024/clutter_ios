package server

import (
	"io"
	"log/slog"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/momodeveluk2024/nutrivita-flutter/backend/internal/config"
)

func TestProfileAvatarRouteRequiresAuthInsteadOf404(t *testing.T) {
	app := New(config.Config{
		AppEnv:          "test",
		JWTSecret:       "this-is-a-test-secret-with-enough-length",
		AccessTokenTTL:  15 * time.Minute,
		RefreshTokenTTL: 30 * 24 * time.Hour,
		AllowedOrigins:  []string{"*"},
	}, nil, slog.New(slog.NewTextHandler(io.Discard, nil)))

	request := httptest.NewRequest(http.MethodPost, "/v1/me/avatar", nil)
	recorder := httptest.NewRecorder()

	app.Routes().ServeHTTP(recorder, request)

	if recorder.Code != http.StatusUnauthorized {
		t.Fatalf("POST /v1/me/avatar status = %d, want %d", recorder.Code, http.StatusUnauthorized)
	}
}

func TestNotificationRoutesRequireAuthInsteadOf404(t *testing.T) {
	app := New(config.Config{
		AppEnv:          "test",
		JWTSecret:       "this-is-a-test-secret-with-enough-length",
		AccessTokenTTL:  15 * time.Minute,
		RefreshTokenTTL: 30 * 24 * time.Hour,
		AllowedOrigins:  []string{"*"},
	}, nil, slog.New(slog.NewTextHandler(io.Discard, nil)))

	cases := []struct {
		method string
		path   string
	}{
		{method: http.MethodPost, path: "/v1/notifications/devices"},
		{method: http.MethodDelete, path: "/v1/notifications/devices/018f0000-0000-7000-8000-000000000001"},
		{method: http.MethodGet, path: "/v1/notifications/preferences"},
		{method: http.MethodPatch, path: "/v1/notifications/preferences"},
	}

	for _, tc := range cases {
		request := httptest.NewRequest(tc.method, tc.path, nil)
		recorder := httptest.NewRecorder()

		app.Routes().ServeHTTP(recorder, request)

		if recorder.Code != http.StatusUnauthorized {
			t.Fatalf("%s %s status = %d, want %d", tc.method, tc.path, recorder.Code, http.StatusUnauthorized)
		}
	}
}
