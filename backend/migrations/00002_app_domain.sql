-- +goose Up
CREATE EXTENSION IF NOT EXISTS pg_trgm;

CREATE TABLE nutrients (
    id uuid PRIMARY KEY,
    code text NOT NULL UNIQUE,
    name text NOT NULL,
    unit text NOT NULL,
    nutrient_group text NOT NULL DEFAULT 'vitamin',
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE dri_values (
    id uuid PRIMARY KEY,
    nutrient_id uuid NOT NULL REFERENCES nutrients(id) ON DELETE CASCADE,
    life_stage text NOT NULL DEFAULT 'adult',
    sex text CHECK (sex IN ('female', 'male', 'other') OR sex IS NULL),
    amount numeric(12,3) NOT NULL CHECK (amount > 0),
    created_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (nutrient_id, life_stage, sex)
);

CREATE TABLE foods (
    id uuid PRIMARY KEY,
    owner_user_id uuid REFERENCES users(id) ON DELETE SET NULL,
    name text NOT NULL,
    brand text,
    category text NOT NULL DEFAULT 'general',
    serving_size_g numeric(8,2) NOT NULL DEFAULT 100 CHECK (serving_size_g > 0),
    source text NOT NULL DEFAULT 'manual',
    verified boolean NOT NULL DEFAULT false,
    barcode text UNIQUE,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    deleted_at timestamptz
);

CREATE TABLE food_nutrients (
    food_id uuid NOT NULL REFERENCES foods(id) ON DELETE CASCADE,
    nutrient_id uuid NOT NULL REFERENCES nutrients(id) ON DELETE CASCADE,
    amount_per_100g numeric(12,3) NOT NULL DEFAULT 0 CHECK (amount_per_100g >= 0),
    PRIMARY KEY (food_id, nutrient_id)
);

CREATE TABLE meal_logs (
    id uuid PRIMARY KEY,
    user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    logged_on date NOT NULL,
    meal_type text NOT NULL CHECK (meal_type IN ('breakfast', 'lunch', 'snack', 'dinner', 'other')),
    notes text,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE meal_log_items (
    id uuid PRIMARY KEY,
    meal_log_id uuid NOT NULL REFERENCES meal_logs(id) ON DELETE CASCADE,
    user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    food_id uuid NOT NULL REFERENCES foods(id),
    serving_g numeric(8,2) NOT NULL CHECK (serving_g > 0),
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE VIEW daily_nutrient_totals AS
SELECT
    ml.user_id,
    ml.logged_on,
    n.id AS nutrient_id,
    n.code,
    n.name,
    n.unit,
    SUM(fn.amount_per_100g * (mli.serving_g / 100.0))::numeric(12,3) AS amount
FROM meal_logs ml
JOIN meal_log_items mli ON mli.meal_log_id = ml.id
JOIN food_nutrients fn ON fn.food_id = mli.food_id
JOIN nutrients n ON n.id = fn.nutrient_id
GROUP BY ml.user_id, ml.logged_on, n.id, n.code, n.name, n.unit;

CREATE TABLE favorites (
    user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    food_id uuid NOT NULL REFERENCES foods(id) ON DELETE CASCADE,
    created_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (user_id, food_id)
);

CREATE TABLE reminders (
    id uuid PRIMARY KEY,
    user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title text NOT NULL,
    body text,
    remind_at timestamptz NOT NULL,
    timezone text NOT NULL DEFAULT 'UTC',
    enabled boolean NOT NULL DEFAULT true,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX foods_name_trgm_idx ON foods USING gin (name gin_trgm_ops);
CREATE INDEX foods_category_idx ON foods(category);
CREATE INDEX food_nutrients_nutrient_idx ON food_nutrients(nutrient_id);
CREATE INDEX meal_logs_user_date_idx ON meal_logs(user_id, logged_on DESC);
CREATE INDEX meal_log_items_user_idx ON meal_log_items(user_id);
CREATE INDEX reminders_user_time_idx ON reminders(user_id, remind_at);

INSERT INTO nutrients (id, code, name, unit, nutrient_group) VALUES
('018f0000-0000-7000-8000-000000000001', 'D', 'Vitamin D', 'mcg', 'vitamin'),
('018f0000-0000-7000-8000-000000000002', 'B12', 'Vitamin B12', 'mcg', 'vitamin'),
('018f0000-0000-7000-8000-000000000003', 'Fe', 'Iron', 'mg', 'mineral'),
('018f0000-0000-7000-8000-000000000004', 'Ca', 'Calcium', 'mg', 'mineral'),
('018f0000-0000-7000-8000-000000000005', 'Mg', 'Magnesium', 'mg', 'mineral'),
('018f0000-0000-7000-8000-000000000006', 'C', 'Vitamin C', 'mg', 'vitamin'),
('018f0000-0000-7000-8000-000000000007', 'A', 'Vitamin A', 'mcg RAE', 'vitamin'),
('018f0000-0000-7000-8000-000000000008', 'B9', 'Folate', 'mcg DFE', 'vitamin'),
('018f0000-0000-7000-8000-000000000009', 'K', 'Vitamin K', 'mcg', 'vitamin'),
('018f0000-0000-7000-8000-000000000010', 'Protein', 'Protein', 'g', 'macro')
ON CONFLICT (code) DO NOTHING;

INSERT INTO dri_values (id, nutrient_id, life_stage, sex, amount) VALUES
('018f0000-0000-7000-8001-000000000001', '018f0000-0000-7000-8000-000000000001', 'adult', NULL, 20),
('018f0000-0000-7000-8001-000000000002', '018f0000-0000-7000-8000-000000000002', 'adult', NULL, 2.4),
('018f0000-0000-7000-8001-000000000003', '018f0000-0000-7000-8000-000000000003', 'adult', NULL, 18),
('018f0000-0000-7000-8001-000000000004', '018f0000-0000-7000-8000-000000000004', 'adult', NULL, 1000),
('018f0000-0000-7000-8001-000000000005', '018f0000-0000-7000-8000-000000000005', 'adult', NULL, 400),
('018f0000-0000-7000-8001-000000000006', '018f0000-0000-7000-8000-000000000006', 'adult', NULL, 90),
('018f0000-0000-7000-8001-000000000007', '018f0000-0000-7000-8000-000000000007', 'adult', NULL, 900),
('018f0000-0000-7000-8001-000000000008', '018f0000-0000-7000-8000-000000000008', 'adult', NULL, 400),
('018f0000-0000-7000-8001-000000000009', '018f0000-0000-7000-8000-000000000009', 'adult', NULL, 120),
('018f0000-0000-7000-8001-000000000010', '018f0000-0000-7000-8000-000000000010', 'adult', NULL, 50)
ON CONFLICT (nutrient_id, life_stage, sex) DO NOTHING;

INSERT INTO foods (id, name, category, serving_size_g, source, verified) VALUES
('018f0000-0000-7000-8002-000000000001', 'Salmon, Atlantic', 'seafood', 100, 'seed', true),
('018f0000-0000-7000-8002-000000000002', 'Spinach, raw', 'vegetables', 100, 'seed', true),
('018f0000-0000-7000-8002-000000000003', 'Greek yogurt', 'dairy', 170, 'seed', true),
('018f0000-0000-7000-8002-000000000004', 'Almonds, dry roast', 'nuts', 28, 'seed', true),
('018f0000-0000-7000-8002-000000000005', 'Sweet potato, baked', 'vegetables', 130, 'seed', true),
('018f0000-0000-7000-8002-000000000006', 'Lentils, cooked', 'legumes', 100, 'seed', true)
ON CONFLICT (id) DO NOTHING;

INSERT INTO food_nutrients (food_id, nutrient_id, amount_per_100g) VALUES
('018f0000-0000-7000-8002-000000000001', '018f0000-0000-7000-8000-000000000001', 13.0),
('018f0000-0000-7000-8002-000000000001', '018f0000-0000-7000-8000-000000000002', 3.2),
('018f0000-0000-7000-8002-000000000001', '018f0000-0000-7000-8000-000000000010', 22.0),
('018f0000-0000-7000-8002-000000000002', '018f0000-0000-7000-8000-000000000009', 483.0),
('018f0000-0000-7000-8002-000000000002', '018f0000-0000-7000-8000-000000000008', 194.0),
('018f0000-0000-7000-8002-000000000002', '018f0000-0000-7000-8000-000000000007', 469.0),
('018f0000-0000-7000-8002-000000000003', '018f0000-0000-7000-8000-000000000004', 110.0),
('018f0000-0000-7000-8002-000000000003', '018f0000-0000-7000-8000-000000000002', 0.75),
('018f0000-0000-7000-8002-000000000003', '018f0000-0000-7000-8000-000000000010', 10.0),
('018f0000-0000-7000-8002-000000000004', '018f0000-0000-7000-8000-000000000005', 270.0),
('018f0000-0000-7000-8002-000000000004', '018f0000-0000-7000-8000-000000000004', 269.0),
('018f0000-0000-7000-8002-000000000005', '018f0000-0000-7000-8000-000000000007', 961.0),
('018f0000-0000-7000-8002-000000000005', '018f0000-0000-7000-8000-000000000006', 19.6),
('018f0000-0000-7000-8002-000000000006', '018f0000-0000-7000-8000-000000000008', 181.0),
('018f0000-0000-7000-8002-000000000006', '018f0000-0000-7000-8000-000000000003', 3.3),
('018f0000-0000-7000-8002-000000000006', '018f0000-0000-7000-8000-000000000010', 9.0)
ON CONFLICT (food_id, nutrient_id) DO UPDATE SET amount_per_100g = EXCLUDED.amount_per_100g;

-- +goose Down
DROP TABLE IF EXISTS reminders;
DROP TABLE IF EXISTS favorites;
DROP VIEW IF EXISTS daily_nutrient_totals;
DROP TABLE IF EXISTS meal_log_items;
DROP TABLE IF EXISTS meal_logs;
DROP TABLE IF EXISTS food_nutrients;
DROP TABLE IF EXISTS foods;
DROP TABLE IF EXISTS dri_values;
DROP TABLE IF EXISTS nutrients;
DROP EXTENSION IF EXISTS pg_trgm;
