package auth

import (
	"testing"
	"time"

	"github.com/google/uuid"
)

func TestAccessTokenRoundTrip(t *testing.T) {
	manager := NewTokenManager("this-is-a-test-secret-with-enough-length", 15*time.Minute)
	userID := uuid.Must(uuid.NewV7())
	sessionID := uuid.Must(uuid.NewV7())

	token, err := manager.IssueAccessToken(userID, sessionID, time.Now())
	if err != nil {
		t.Fatalf("issue token: %v", err)
	}

	gotUserID, gotSessionID, err := manager.ParseAccessToken(token)
	if err != nil {
		t.Fatalf("parse token: %v", err)
	}
	if gotUserID != userID {
		t.Fatalf("user id mismatch: got %s want %s", gotUserID, userID)
	}
	if gotSessionID != sessionID {
		t.Fatalf("session id mismatch: got %s want %s", gotSessionID, sessionID)
	}
}

func TestRefreshTokenHashIsStable(t *testing.T) {
	token, hash, err := NewRefreshToken()
	if err != nil {
		t.Fatalf("new refresh token: %v", err)
	}
	if token == "" {
		t.Fatal("expected refresh token")
	}
	gotHash := HashRefreshToken(token)
	if string(gotHash) != string(hash) {
		t.Fatal("expected stable refresh hash")
	}
}
