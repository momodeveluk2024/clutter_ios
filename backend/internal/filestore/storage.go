package filestore

import (
	"context"
	"fmt"
	"io"
	"mime"
	"os"
	"path/filepath"
	"strings"

	"github.com/google/uuid"
)

type Object struct {
	Key         string `json:"key"`
	URL         string `json:"url"`
	ContentType string `json:"content_type"`
	Size        int64  `json:"size"`
}

type ObjectStore interface {
	Put(ctx context.Context, key string, contentType string, reader io.Reader) (Object, error)
	Delete(ctx context.Context, key string) error
	PublicURL(key string) string
}

type LocalStore struct {
	rootDir string
	baseURL string
}

func NewLocalStore(rootDir, baseURL string) *LocalStore {
	return &LocalStore{
		rootDir: rootDir,
		baseURL: strings.TrimRight(baseURL, "/"),
	}
}

func AvatarKey(userID uuid.UUID, filename string) string {
	return filepath.ToSlash(filepath.Join("avatars", userID.String(), safeFilename(filename)))
}

func FoodImageKey(foodID uuid.UUID, filename string) string {
	return filepath.ToSlash(filepath.Join("foods", foodID.String(), safeFilename(filename)))
}

func MealPhotoKey(userID, estimateID uuid.UUID, filename string) string {
	return filepath.ToSlash(filepath.Join("meal-photos", userID.String(), estimateID.String(), safeFilename(filename)))
}

func (s *LocalStore) Put(ctx context.Context, key string, contentType string, reader io.Reader) (Object, error) {
	if err := ctx.Err(); err != nil {
		return Object{}, err
	}
	cleanKey, err := cleanObjectKey(key)
	if err != nil {
		return Object{}, err
	}
	target := filepath.Join(s.rootDir, filepath.FromSlash(cleanKey))
	if err := os.MkdirAll(filepath.Dir(target), 0o755); err != nil {
		return Object{}, err
	}

	file, err := os.Create(target)
	if err != nil {
		return Object{}, err
	}
	defer file.Close()

	size, err := io.Copy(file, reader)
	if err != nil {
		return Object{}, err
	}
	if contentType == "" {
		contentType = mime.TypeByExtension(filepath.Ext(cleanKey))
	}
	return Object{Key: cleanKey, URL: s.PublicURL(cleanKey), ContentType: contentType, Size: size}, nil
}

func (s *LocalStore) Delete(ctx context.Context, key string) error {
	if err := ctx.Err(); err != nil {
		return err
	}
	cleanKey, err := cleanObjectKey(key)
	if err != nil {
		return err
	}
	if err := os.Remove(filepath.Join(s.rootDir, filepath.FromSlash(cleanKey))); err != nil && !os.IsNotExist(err) {
		return err
	}
	return nil
}

func (s *LocalStore) PublicURL(key string) string {
	if s.baseURL == "" {
		return "/" + strings.TrimLeft(key, "/")
	}
	return s.baseURL + "/" + strings.TrimLeft(key, "/")
}

func cleanObjectKey(key string) (string, error) {
	cleaned := filepath.ToSlash(filepath.Clean(strings.TrimSpace(key)))
	cleaned = strings.TrimLeft(cleaned, "/")
	if cleaned == "." || cleaned == "" || strings.HasPrefix(cleaned, "../") || strings.Contains(cleaned, "/../") {
		return "", fmt.Errorf("invalid object key")
	}
	return cleaned, nil
}

func safeFilename(filename string) string {
	filename = filepath.Base(strings.TrimSpace(filename))
	if filename == "." || filename == string(filepath.Separator) || filename == "" {
		return "upload.bin"
	}
	return strings.NewReplacer(" ", "-", "\\", "-", "/", "-").Replace(filename)
}
