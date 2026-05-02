-- +goose Up
CREATE TABLE daily_nutrient_totals_cache (
    user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    logged_on date NOT NULL,
    nutrient_id uuid NOT NULL REFERENCES nutrients(id) ON DELETE CASCADE,
    code text NOT NULL,
    name text NOT NULL,
    unit text NOT NULL,
    amount numeric(12,3) NOT NULL,
    updated_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (user_id, logged_on, nutrient_id)
);

INSERT INTO daily_nutrient_totals_cache (user_id, logged_on, nutrient_id, code, name, unit, amount)
SELECT user_id, logged_on, nutrient_id, code, name, unit, amount
FROM daily_nutrient_totals;

DROP VIEW daily_nutrient_totals;
ALTER TABLE daily_nutrient_totals_cache RENAME TO daily_nutrient_totals;

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

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION refresh_daily_nutrient_totals_for_log()
RETURNS trigger AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        PERFORM refresh_daily_nutrient_totals(OLD.user_id, OLD.logged_on);
        RETURN OLD;
    END IF;

    IF TG_OP = 'UPDATE' AND (OLD.user_id <> NEW.user_id OR OLD.logged_on <> NEW.logged_on) THEN
        PERFORM refresh_daily_nutrient_totals(OLD.user_id, OLD.logged_on);
    END IF;

    PERFORM refresh_daily_nutrient_totals(NEW.user_id, NEW.logged_on);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION refresh_daily_nutrient_totals_for_item()
RETURNS trigger AS $$
DECLARE
    target_user_id uuid;
    target_logged_on date;
BEGIN
    IF TG_OP = 'DELETE' THEN
        SELECT user_id, logged_on INTO target_user_id, target_logged_on
        FROM meal_logs
        WHERE id = OLD.meal_log_id;
    ELSE
        SELECT user_id, logged_on INTO target_user_id, target_logged_on
        FROM meal_logs
        WHERE id = NEW.meal_log_id;
    END IF;

    IF target_user_id IS NOT NULL THEN
        PERFORM refresh_daily_nutrient_totals(target_user_id, target_logged_on);
    END IF;

    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
-- +goose StatementEnd

CREATE TRIGGER meal_logs_refresh_daily_totals
AFTER INSERT OR UPDATE OR DELETE ON meal_logs
FOR EACH ROW EXECUTE FUNCTION refresh_daily_nutrient_totals_for_log();

CREATE TRIGGER meal_log_items_refresh_daily_totals
AFTER INSERT OR UPDATE OR DELETE ON meal_log_items
FOR EACH ROW EXECUTE FUNCTION refresh_daily_nutrient_totals_for_item();

-- +goose Down
DROP TRIGGER IF EXISTS meal_log_items_refresh_daily_totals ON meal_log_items;
DROP TRIGGER IF EXISTS meal_logs_refresh_daily_totals ON meal_logs;
DROP FUNCTION IF EXISTS refresh_daily_nutrient_totals_for_item();
DROP FUNCTION IF EXISTS refresh_daily_nutrient_totals_for_log();
DROP FUNCTION IF EXISTS refresh_daily_nutrient_totals(uuid, date);
DROP TABLE IF EXISTS daily_nutrient_totals;

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
