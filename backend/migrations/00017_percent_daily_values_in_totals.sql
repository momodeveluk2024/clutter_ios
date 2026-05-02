-- +goose Up
-- Include imported percent-Daily-Value food profiles in logged daily totals.
-- Percent values are converted back to nutrient amounts through the active adult DRI target.
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION refresh_daily_nutrient_totals(p_user_id uuid, p_logged_on date)
RETURNS void AS $$
BEGIN
    DELETE FROM daily_nutrient_totals
    WHERE user_id = p_user_id AND logged_on = p_logged_on;

    INSERT INTO daily_nutrient_totals (user_id, logged_on, nutrient_id, code, name, unit, amount)
    SELECT
        source.user_id,
        source.logged_on,
        source.nutrient_id,
        source.code,
        source.name,
        source.unit,
        SUM(source.amount)::numeric(12,3)
    FROM (
        SELECT
            ml.user_id,
            ml.logged_on,
            n.id AS nutrient_id,
            n.code,
            n.name,
            n.unit,
            fn.amount_per_100g * (mli.serving_g / 100.0) AS amount
        FROM meal_logs ml
        JOIN meal_log_items mli ON mli.meal_log_id = ml.id
        JOIN food_nutrients fn ON fn.food_id = mli.food_id
        JOIN nutrients n ON n.id = fn.nutrient_id
        WHERE ml.user_id = p_user_id AND ml.logged_on = p_logged_on

        UNION ALL

        SELECT
            ml.user_id,
            ml.logged_on,
            n.id AS nutrient_id,
            n.code,
            n.name,
            n.unit,
            (fdv.daily_value_percent / 100.0) * d.amount * (mli.serving_g / 100.0) AS amount
        FROM meal_logs ml
        JOIN meal_log_items mli ON mli.meal_log_id = ml.id
        JOIN food_nutrient_daily_values fdv ON fdv.food_id = mli.food_id
        JOIN nutrients n ON n.id = fdv.nutrient_id
        JOIN LATERAL (
            SELECT amount
            FROM dri_values d
            WHERE d.nutrient_id = n.id
              AND d.life_stage = 'adult'
              AND d.sex IS NULL
            ORDER BY d.created_at DESC, d.id DESC
            LIMIT 1
        ) d ON true
        WHERE ml.user_id = p_user_id
          AND ml.logged_on = p_logged_on
          AND NOT EXISTS (
              SELECT 1
              FROM food_nutrients fn
              WHERE fn.food_id = mli.food_id
                AND fn.nutrient_id = fdv.nutrient_id
          )
    ) source
    GROUP BY source.user_id, source.logged_on, source.nutrient_id, source.code, source.name, source.unit;
END;
$$ LANGUAGE plpgsql;
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION refresh_daily_nutrient_totals(p_user_id uuid, p_logged_on date)
RETURNS void AS $$
BEGIN
    DELETE FROM daily_nutrient_totals
    WHERE user_id = p_user_id AND logged_on = p_logged_on;

    INSERT INTO daily_nutrient_totals (user_id, logged_on, nutrient_id, code, name, unit, amount)
    SELECT
        ml.user_id,
        ml.logged_on,
        n.id,
        n.code,
        n.name,
        n.unit,
        SUM(fn.amount_per_100g * (mli.serving_g / 100.0))::numeric(12,3)
    FROM meal_logs ml
    JOIN meal_log_items mli ON mli.meal_log_id = ml.id
    JOIN food_nutrients fn ON fn.food_id = mli.food_id
    JOIN nutrients n ON n.id = fn.nutrient_id
    WHERE ml.user_id = p_user_id AND ml.logged_on = p_logged_on
    GROUP BY ml.user_id, ml.logged_on, n.id, n.code, n.name, n.unit;
END;
$$ LANGUAGE plpgsql;
-- +goose StatementEnd
