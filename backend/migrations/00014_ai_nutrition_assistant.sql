-- +goose Up
INSERT INTO nutrients (id, code, name, unit, nutrient_group)
VALUES ('018f0000-0000-7000-8000-000000000028', 'Calories', 'Calories', 'kcal', 'macro')
ON CONFLICT (code) DO NOTHING;

INSERT INTO dri_values (id, nutrient_id, life_stage, sex, amount)
SELECT '018f0000-0000-7000-8001-000000000028', id, 'adult', NULL, 2000
FROM nutrients
WHERE code = 'Calories'
ON CONFLICT (nutrient_id, life_stage, sex) DO NOTHING;

CREATE TABLE ai_estimates (
    id uuid PRIMARY KEY,
    user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    image_url text,
    image_key text,
    prompt_version text NOT NULL,
    provider text NOT NULL DEFAULT 'development',
    model text NOT NULL,
    status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'needs_review', 'accepted', 'failed', 'reviewed')),
    confidence numeric(5,4) NOT NULL DEFAULT 0 CHECK (confidence >= 0 AND confidence <= 1),
    meal_type text NOT NULL DEFAULT 'other' CHECK (meal_type IN ('breakfast', 'lunch', 'snack', 'dinner', 'other')),
    logged_on date NOT NULL DEFAULT CURRENT_DATE,
    locale text NOT NULL DEFAULT 'en',
    unit_system text NOT NULL DEFAULT 'metric',
    question text,
    questions jsonb NOT NULL DEFAULT '[]'::jsonb,
    warnings jsonb NOT NULL DEFAULT '[]'::jsonb,
    raw_model_json jsonb NOT NULL DEFAULT '{}'::jsonb,
    normalized_json jsonb NOT NULL DEFAULT '{}'::jsonb,
    accepted_log_id uuid REFERENCES meal_logs(id) ON DELETE SET NULL,
    reviewed_by uuid REFERENCES users(id) ON DELETE SET NULL,
    reviewed_status text,
    review_notes text,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE ai_estimate_items (
    id uuid PRIMARY KEY,
    estimate_id uuid NOT NULL REFERENCES ai_estimates(id) ON DELETE CASCADE,
    user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name text NOT NULL,
    matched_food_id uuid REFERENCES foods(id) ON DELETE SET NULL,
    quantity_g numeric(8,2) NOT NULL CHECK (quantity_g > 0),
    calories_kcal numeric(10,2) NOT NULL DEFAULT 0 CHECK (calories_kcal >= 0),
    protein_g numeric(10,2) NOT NULL DEFAULT 0 CHECK (protein_g >= 0),
    carbs_g numeric(10,2) NOT NULL DEFAULT 0 CHECK (carbs_g >= 0),
    fat_g numeric(10,2) NOT NULL DEFAULT 0 CHECK (fat_g >= 0),
    confidence numeric(5,4) NOT NULL DEFAULT 0 CHECK (confidence >= 0 AND confidence <= 1),
    source text NOT NULL DEFAULT 'ai_estimate',
    position int NOT NULL DEFAULT 0,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE ai_conversations (
    id uuid PRIMARY KEY,
    user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    estimate_id uuid REFERENCES ai_estimates(id) ON DELETE SET NULL,
    title text NOT NULL DEFAULT 'Nutrition chat',
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE ai_conversation_messages (
    id uuid PRIMARY KEY,
    conversation_id uuid NOT NULL REFERENCES ai_conversations(id) ON DELETE CASCADE,
    user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role text NOT NULL CHECK (role IN ('user', 'assistant')),
    content text NOT NULL,
    model text,
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE ai_usage_events (
    id uuid PRIMARY KEY,
    user_id uuid REFERENCES users(id) ON DELETE SET NULL,
    estimate_id uuid REFERENCES ai_estimates(id) ON DELETE SET NULL,
    conversation_id uuid REFERENCES ai_conversations(id) ON DELETE SET NULL,
    provider text NOT NULL,
    model text NOT NULL,
    operation text NOT NULL,
    status text NOT NULL CHECK (status IN ('ok', 'error', 'blocked')),
    latency_ms int NOT NULL DEFAULT 0 CHECK (latency_ms >= 0),
    input_tokens int NOT NULL DEFAULT 0 CHECK (input_tokens >= 0),
    output_tokens int NOT NULL DEFAULT 0 CHECK (output_tokens >= 0),
    error_class text,
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX ai_estimates_user_created_idx ON ai_estimates(user_id, created_at DESC);
CREATE INDEX ai_estimates_status_idx ON ai_estimates(status, created_at DESC);
CREATE INDEX ai_estimate_items_estimate_idx ON ai_estimate_items(estimate_id, position ASC);
CREATE INDEX ai_conversations_user_idx ON ai_conversations(user_id, updated_at DESC);
CREATE INDEX ai_usage_events_created_idx ON ai_usage_events(created_at DESC);

-- +goose Down
DROP TABLE IF EXISTS ai_usage_events;
DROP TABLE IF EXISTS ai_conversation_messages;
DROP TABLE IF EXISTS ai_conversations;
DROP TABLE IF EXISTS ai_estimate_items;
DROP TABLE IF EXISTS ai_estimates;
DELETE FROM dri_values WHERE id = '018f0000-0000-7000-8001-000000000028';
DELETE FROM nutrients WHERE id = '018f0000-0000-7000-8000-000000000028' AND code = 'Calories';
