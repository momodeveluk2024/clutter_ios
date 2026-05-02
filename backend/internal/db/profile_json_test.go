package db

import (
	"encoding/json"
	"testing"
)

func TestMePreferencesMarshalAsJSONObject(t *testing.T) {
	me := Me{Preferences: json.RawMessage(`{"appearance":"dark"}`)}

	payload, err := json.Marshal(me)
	if err != nil {
		t.Fatalf("marshal me: %v", err)
	}

	var decoded map[string]any
	if err := json.Unmarshal(payload, &decoded); err != nil {
		t.Fatalf("unmarshal me: %v", err)
	}
	preferences, ok := decoded["preferences"].(map[string]any)
	if !ok {
		t.Fatalf("preferences = %#v, want JSON object", decoded["preferences"])
	}
	if preferences["appearance"] != "dark" {
		t.Fatalf("appearance = %#v, want dark", preferences["appearance"])
	}
}

func TestMeAvatarURLMarshal(t *testing.T) {
	avatarURL := "/uploads/avatars/user/avatar.png"
	me := Me{
		AvatarURL:   &avatarURL,
		Preferences: json.RawMessage(`{}`),
	}

	payload, err := json.Marshal(me)
	if err != nil {
		t.Fatalf("marshal me: %v", err)
	}

	var decoded map[string]any
	if err := json.Unmarshal(payload, &decoded); err != nil {
		t.Fatalf("unmarshal me: %v", err)
	}
	if decoded["avatar_url"] != avatarURL {
		t.Fatalf("avatar_url = %#v, want %q", decoded["avatar_url"], avatarURL)
	}
}
