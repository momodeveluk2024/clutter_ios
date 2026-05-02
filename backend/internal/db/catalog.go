package db

import (
	"context"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
)

type FoodSummary struct {
	ID           uuid.UUID `json:"id"`
	Name         string    `json:"name"`
	Brand        *string   `json:"brand,omitempty"`
	Category     string    `json:"category"`
	ServingSizeG float64   `json:"serving_size_g"`
	Verified     bool      `json:"verified"`
	ImageURL     *string   `json:"image_url,omitempty"`
	Nutrients    []string  `json:"nutrients"`
	DRIPercent   *float64  `json:"dri_percent,omitempty"`
}

type FoodNutrient struct {
	Code          string   `json:"code"`
	Name          string   `json:"name"`
	Unit          string   `json:"unit"`
	AmountPer100G float64  `json:"amount_per_100g"`
	DRIAmount     *float64 `json:"dri_amount,omitempty"`
	DRIPercent    *float64 `json:"dri_percent,omitempty"`
}

type FoodDetail struct {
	FoodSummary
	Barcode   *string        `json:"barcode,omitempty"`
	Source    string         `json:"source"`
	CreatedAt time.Time      `json:"created_at"`
	Nutrients []FoodNutrient `json:"nutrients"`
}

type CreateFoodParams struct {
	ID           uuid.UUID
	OwnerUserID  uuid.UUID
	Name         string
	Brand        *string
	Category     string
	ServingSizeG float64
	Source       string
	Barcode      *string
	ImageURL     *string
	Nutrients    []CreateFoodNutrient
}

type CreateFoodNutrient struct {
	Code          string  `json:"code"`
	AmountPer100G float64 `json:"amount_per_100g"`
}

func (s *Store) ListFoods(ctx context.Context, q, category, nutrient string, limit int) ([]FoodSummary, error) {
	if limit <= 0 || limit > 100 {
		limit = 25
	}
	q = strings.TrimSpace(q)
	category = strings.TrimSpace(category)
	nutrient = strings.TrimSpace(nutrient)

	rows, err := s.pool.Query(ctx, `
		SELECT
			f.id,
			f.name,
			f.brand,
			f.category,
			f.serving_size_g::float8,
			f.verified,
			f.image_url,
			COALESCE(ARRAY(
				SELECT code
				FROM (
					SELECT DISTINCT n.code
					FROM food_nutrients fn
					JOIN nutrients n ON n.id = fn.nutrient_id
					WHERE fn.food_id = f.id
					UNION
					SELECT DISTINCT n.code
					FROM food_nutrient_daily_values fdv
					JOIN nutrients n ON n.id = fdv.nutrient_id
					WHERE fdv.food_id = f.id
				) nutrient_codes
				ORDER BY code
			), '{}')::text[] AS nutrient_codes,
			CASE WHEN $3 = '' THEN NULL ELSE COALESCE((
				SELECT fdv.daily_value_percent::float8
				FROM food_nutrient_daily_values fdv
				JOIN nutrients n ON n.id = fdv.nutrient_id
				WHERE fdv.food_id = f.id AND lower(n.code) = lower($3)
				ORDER BY fdv.daily_value_percent DESC
				LIMIT 1
			), (
				SELECT ROUND((fn.amount_per_100g / d.amount) * 100, 1)::float8
				FROM food_nutrients fn
				JOIN nutrients n ON n.id = fn.nutrient_id
				JOIN dri_values d ON d.nutrient_id = n.id AND d.life_stage = 'adult' AND d.sex IS NULL
				WHERE fn.food_id = f.id AND lower(n.code) = lower($3)
				ORDER BY fn.amount_per_100g DESC
				LIMIT 1
			)) END AS selected_dri_percent
		FROM foods f
		WHERE f.deleted_at IS NULL
		  AND ($1 = '' OR f.name ILIKE '%' || $1 || '%' OR similarity(f.name, $1) > 0.18)
		  AND ($2 = '' OR f.category = $2)
		  AND ($3 = '' OR EXISTS (
			SELECT 1
			FROM food_nutrient_daily_values fdv
			JOIN nutrients n ON n.id = fdv.nutrient_id
			WHERE fdv.food_id = f.id AND lower(n.code) = lower($3)
		  ) OR EXISTS (
			SELECT 1
			FROM food_nutrients fn
			JOIN nutrients n ON n.id = fn.nutrient_id
			WHERE fn.food_id = f.id AND lower(n.code) = lower($3)
		  ))
		ORDER BY
			CASE WHEN $3 = '' THEN 0 ELSE COALESCE((
				SELECT fdv.daily_value_percent::float8
				FROM food_nutrient_daily_values fdv
				JOIN nutrients n ON n.id = fdv.nutrient_id
				WHERE fdv.food_id = f.id AND lower(n.code) = lower($3)
				ORDER BY fdv.daily_value_percent DESC
				LIMIT 1
			), 0) END DESC,
			CASE WHEN $1 = '' THEN 0 ELSE similarity(f.name, $1) END DESC,
			f.verified DESC,
			f.name ASC
		LIMIT $4
	`, q, category, nutrient, limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	foods := []FoodSummary{}
	for rows.Next() {
		var food FoodSummary
		if err := rows.Scan(&food.ID, &food.Name, &food.Brand, &food.Category, &food.ServingSizeG, &food.Verified, &food.ImageURL, &food.Nutrients, &food.DRIPercent); err != nil {
			return nil, err
		}
		foods = append(foods, food)
	}
	return foods, rows.Err()
}

func (s *Store) GetFoodDetail(ctx context.Context, foodID uuid.UUID) (FoodDetail, error) {
	var detail FoodDetail
	err := s.pool.QueryRow(ctx, `
		SELECT id, name, brand, category, serving_size_g::float8, verified, image_url, barcode, source, created_at
		FROM foods
		WHERE id = $1 AND deleted_at IS NULL
	`, foodID).Scan(
		&detail.ID,
		&detail.Name,
		&detail.Brand,
		&detail.Category,
		&detail.ServingSizeG,
		&detail.Verified,
		&detail.ImageURL,
		&detail.Barcode,
		&detail.Source,
		&detail.CreatedAt,
	)
	if err != nil {
		return FoodDetail{}, err
	}

	rows, err := s.pool.Query(ctx, `
		WITH nutrient_ids AS (
			SELECT nutrient_id
			FROM food_nutrients
			WHERE food_id = $1
			UNION
			SELECT nutrient_id
			FROM food_nutrient_daily_values
			WHERE food_id = $1
		)
		SELECT
			n.code,
			n.name,
			n.unit,
			COALESCE(fn.amount_per_100g, 0)::float8,
			d.amount::float8,
			COALESCE(
				fdv.daily_value_percent::float8,
				CASE WHEN d.amount IS NULL OR fn.amount_per_100g IS NULL THEN NULL ELSE ROUND((fn.amount_per_100g / d.amount) * 100, 1)::float8 END
			)
		FROM nutrient_ids ni
		JOIN nutrients n ON n.id = ni.nutrient_id
		LEFT JOIN food_nutrients fn ON fn.food_id = $1 AND fn.nutrient_id = n.id
		LEFT JOIN food_nutrient_daily_values fdv ON fdv.food_id = $1 AND fdv.nutrient_id = n.id
		LEFT JOIN LATERAL (
			SELECT amount
			FROM dri_values
			WHERE nutrient_id = n.id AND life_stage = 'adult' AND sex IS NULL
			ORDER BY created_at DESC, id DESC
			LIMIT 1
		) d ON true
		ORDER BY
			COALESCE(
				fdv.daily_value_percent::float8,
				CASE WHEN d.amount IS NULL OR fn.amount_per_100g IS NULL THEN NULL ELSE (fn.amount_per_100g / d.amount) * 100 END,
				0
			) DESC,
			n.name
	`, foodID)
	if err != nil {
		return FoodDetail{}, err
	}
	defer rows.Close()

	for rows.Next() {
		var nutrient FoodNutrient
		if err := rows.Scan(&nutrient.Code, &nutrient.Name, &nutrient.Unit, &nutrient.AmountPer100G, &nutrient.DRIAmount, &nutrient.DRIPercent); err != nil {
			return FoodDetail{}, err
		}
		detail.Nutrients = append(detail.Nutrients, nutrient)
		detail.FoodSummary.Nutrients = append(detail.FoodSummary.Nutrients, nutrient.Code)
	}
	return detail, rows.Err()
}

func (s *Store) GetFoodDetailByBarcode(ctx context.Context, barcode string) (FoodDetail, error) {
	var foodID uuid.UUID
	err := s.pool.QueryRow(ctx, `
		SELECT id
		FROM foods
		WHERE barcode = $1 AND deleted_at IS NULL
	`, strings.TrimSpace(barcode)).Scan(&foodID)
	if err != nil {
		return FoodDetail{}, err
	}
	return s.GetFoodDetail(ctx, foodID)
}

func (s *Store) CreateFood(ctx context.Context, params CreateFoodParams) (FoodDetail, error) {
	source := strings.TrimSpace(params.Source)
	if source == "" {
		source = "user"
	}
	tx, err := s.pool.BeginTx(ctx, pgx.TxOptions{})
	if err != nil {
		return FoodDetail{}, err
	}
	defer tx.Rollback(ctx)

	_, err = tx.Exec(ctx, `
		INSERT INTO foods (id, owner_user_id, name, brand, category, serving_size_g, source, verified, barcode, image_url)
		VALUES ($1, $2, $3, $4, $5, $6, $7, false, $8, $9)
	`, params.ID, params.OwnerUserID, params.Name, params.Brand, params.Category, params.ServingSizeG, source, params.Barcode, params.ImageURL)
	if err != nil {
		return FoodDetail{}, err
	}

	for _, nutrient := range params.Nutrients {
		_, err := tx.Exec(ctx, `
			INSERT INTO food_nutrients (food_id, nutrient_id, amount_per_100g)
			SELECT $1, id, $3
			FROM nutrients
			WHERE code = $2
		`, params.ID, nutrient.Code, nutrient.AmountPer100G)
		if err != nil {
			return FoodDetail{}, err
		}
	}

	if err := tx.Commit(ctx); err != nil {
		return FoodDetail{}, err
	}
	return s.GetFoodDetail(ctx, params.ID)
}
