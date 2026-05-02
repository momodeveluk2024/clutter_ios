-- +goose Up
WITH ranked AS (
    SELECT
        id,
        row_number() OVER (
            PARTITION BY nutrient_id, life_stage, sex
            ORDER BY created_at DESC, id DESC
        ) AS rn
    FROM dri_values
    WHERE sex IS NULL
)
DELETE FROM dri_values d
USING ranked r
WHERE d.id = r.id AND r.rn > 1;

CREATE UNIQUE INDEX IF NOT EXISTS dri_values_nutrient_lifestage_null_sex_idx
ON dri_values (nutrient_id, life_stage)
WHERE sex IS NULL;

-- +goose Down
DROP INDEX IF EXISTS dri_values_nutrient_lifestage_null_sex_idx;
