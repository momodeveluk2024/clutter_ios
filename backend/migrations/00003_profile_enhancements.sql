-- +goose Up
ALTER TABLE user_profiles
    ADD COLUMN pregnancy_status text CHECK (
        pregnancy_status IN ('none', 'pregnant', 'postpartum', 'trying') OR pregnancy_status IS NULL
    ),
    ADD COLUMN dietary_pattern text,
    ADD COLUMN allergens text[] NOT NULL DEFAULT '{}'::text[],
    ADD COLUMN goals text[] NOT NULL DEFAULT '{}'::text[];

CREATE INDEX foods_barcode_idx ON foods(barcode) WHERE barcode IS NOT NULL;

-- +goose Down
DROP INDEX IF EXISTS foods_barcode_idx;
ALTER TABLE user_profiles
    DROP COLUMN IF EXISTS goals,
    DROP COLUMN IF EXISTS allergens,
    DROP COLUMN IF EXISTS dietary_pattern,
    DROP COLUMN IF EXISTS pregnancy_status;
