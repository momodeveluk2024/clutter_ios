package server

import (
	"errors"
	"net/http"
	"strconv"
	"strings"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/momodeveluk2024/nutrivita-flutter/backend/internal/db"
	"github.com/momodeveluk2024/nutrivita-flutter/backend/internal/httpx"
)

type createFoodRequest struct {
	Name         string                  `json:"name" validate:"required,min=1,max=180"`
	Brand        *string                 `json:"brand" validate:"omitempty,max=120"`
	Category     string                  `json:"category" validate:"required,min=1,max=80"`
	ServingSizeG float64                 `json:"serving_size_g" validate:"required,gt=0,lte=10000"`
	Barcode      *string                 `json:"barcode" validate:"omitempty,max=80"`
	ImageURL     *string                 `json:"image_url" validate:"omitempty,url,max=500"`
	Nutrients    []db.CreateFoodNutrient `json:"nutrients" validate:"max=64,dive"`
}

func (a *App) handleListFoods(w http.ResponseWriter, r *http.Request) {
	foods, err := a.store.ListFoods(
		r.Context(),
		r.URL.Query().Get("q"),
		r.URL.Query().Get("category"),
		r.URL.Query().Get("nutrient"),
		parseLimit(r, 25),
	)
	if err != nil {
		a.logger.Error("list foods", "error", err)
		httpx.WriteError(w, http.StatusInternalServerError, "could not list foods")
		return
	}
	httpx.WriteJSON(w, http.StatusOK, map[string]any{"foods": foods})
}

func (a *App) handleGetFood(w http.ResponseWriter, r *http.Request) {
	foodID, ok := parseUUIDURLParam(w, r, "foodID")
	if !ok {
		return
	}

	food, err := a.store.GetFoodDetail(r.Context(), foodID)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			httpx.WriteError(w, http.StatusNotFound, "food not found")
			return
		}
		a.logger.Error("get food", "error", err)
		httpx.WriteError(w, http.StatusInternalServerError, "could not load food")
		return
	}
	httpx.WriteJSON(w, http.StatusOK, food)
}

func (a *App) handleGetFoodByBarcode(w http.ResponseWriter, r *http.Request) {
	barcode := strings.TrimSpace(chi.URLParam(r, "barcode"))
	if barcode == "" || len(barcode) > 80 {
		httpx.WriteError(w, http.StatusBadRequest, "invalid barcode")
		return
	}

	food, err := a.store.GetFoodDetailByBarcode(r.Context(), barcode)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			httpx.WriteError(w, http.StatusNotFound, "food not found")
			return
		}
		a.logger.Error("get food by barcode", "error", err)
		httpx.WriteError(w, http.StatusInternalServerError, "could not load food")
		return
	}
	httpx.WriteJSON(w, http.StatusOK, food)
}

func (a *App) handleCreateFood(w http.ResponseWriter, r *http.Request) {
	claims := authFromContext(r.Context())
	var request createFoodRequest
	if !a.readAndValidate(w, r, &request) {
		return
	}

	foodID, err := uuid.NewV7()
	if err != nil {
		httpx.WriteError(w, http.StatusInternalServerError, "could not create food")
		return
	}

	food, err := a.store.CreateFood(r.Context(), db.CreateFoodParams{
		ID:           foodID,
		OwnerUserID:  claims.UserID,
		Name:         strings.TrimSpace(request.Name),
		Brand:        trimOptional(request.Brand),
		Category:     strings.ToLower(strings.TrimSpace(request.Category)),
		ServingSizeG: request.ServingSizeG,
		Barcode:      trimOptional(request.Barcode),
		ImageURL:     trimOptional(request.ImageURL),
		Nutrients:    request.Nutrients,
	})
	if err != nil {
		a.logger.Error("create food", "error", err)
		httpx.WriteError(w, http.StatusInternalServerError, "could not create food")
		return
	}

	httpx.WriteJSON(w, http.StatusCreated, food)
}

func parseLimit(r *http.Request, fallback int) int {
	limit := fallback
	if raw := r.URL.Query().Get("limit"); raw != "" {
		if parsed, err := strconv.Atoi(raw); err == nil {
			limit = parsed
		}
	}
	if limit <= 0 || limit > 100 {
		return fallback
	}
	return limit
}

func trimOptional(value *string) *string {
	if value == nil {
		return nil
	}
	trimmed := strings.TrimSpace(*value)
	if trimmed == "" {
		return nil
	}
	return &trimmed
}

func parseUUIDURLParam(w http.ResponseWriter, r *http.Request, name string) (uuid.UUID, bool) {
	id, err := uuid.Parse(chi.URLParam(r, name))
	if err != nil {
		httpx.WriteError(w, http.StatusBadRequest, "invalid "+name)
		return uuid.Nil, false
	}
	return id, true
}
