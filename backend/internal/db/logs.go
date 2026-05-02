package db

import (
	"context"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
)

type MealLog struct {
	ID        uuid.UUID     `json:"id"`
	UserID    uuid.UUID     `json:"user_id"`
	LoggedOn  string        `json:"logged_on"`
	MealType  string        `json:"meal_type"`
	Notes     *string       `json:"notes,omitempty"`
	Items     []MealLogItem `json:"items"`
	CreatedAt time.Time     `json:"created_at"`
}

type MealLogItem struct {
	ID       uuid.UUID `json:"id"`
	FoodID   uuid.UUID `json:"food_id"`
	FoodName string    `json:"food_name"`
	ImageURL *string   `json:"image_url,omitempty"`
	ServingG float64   `json:"serving_g"`
}

type CreateMealLogParams struct {
	ID       uuid.UUID
	UserID   uuid.UUID
	LoggedOn string
	MealType string
	Notes    *string
	Items    []CreateMealLogItem
}

type CreateMealLogItem struct {
	ID       uuid.UUID `json:"-"`
	FoodID   uuid.UUID `json:"food_id"`
	ServingG float64   `json:"serving_g"`
}

type NutrientTotal struct {
	Code       string   `json:"code"`
	Name       string   `json:"name"`
	Unit       string   `json:"unit"`
	Amount     float64  `json:"amount"`
	DRIAmount  *float64 `json:"dri_amount,omitempty"`
	DRIPercent *float64 `json:"dri_percent,omitempty"`
}

type DayNutrientTotals struct {
	Date      string          `json:"date"`
	Nutrients []NutrientTotal `json:"nutrients"`
}

func (s *Store) CreateMealLog(ctx context.Context, params CreateMealLogParams) (MealLog, error) {
	tx, err := s.pool.BeginTx(ctx, pgx.TxOptions{})
	if err != nil {
		return MealLog{}, err
	}
	defer tx.Rollback(ctx)

	_, err = tx.Exec(ctx, `
		INSERT INTO meal_logs (id, user_id, logged_on, meal_type, notes)
		VALUES ($1, $2, $3::date, $4, $5)
	`, params.ID, params.UserID, params.LoggedOn, params.MealType, params.Notes)
	if err != nil {
		return MealLog{}, err
	}

	for _, item := range params.Items {
		_, err := tx.Exec(ctx, `
			INSERT INTO meal_log_items (id, meal_log_id, user_id, food_id, serving_g)
			VALUES ($1, $2, $3, $4, $5)
		`, item.ID, params.ID, params.UserID, item.FoodID, item.ServingG)
		if err != nil {
			return MealLog{}, err
		}
	}

	if err := tx.Commit(ctx); err != nil {
		return MealLog{}, err
	}
	return s.GetMealLog(ctx, params.UserID, params.ID)
}

func (s *Store) GetMealLog(ctx context.Context, userID, logID uuid.UUID) (MealLog, error) {
	var log MealLog
	var loggedOn time.Time
	err := s.pool.QueryRow(ctx, `
		SELECT id, user_id, logged_on, meal_type, notes, created_at
		FROM meal_logs
		WHERE id = $1 AND user_id = $2
	`, logID, userID).Scan(&log.ID, &log.UserID, &loggedOn, &log.MealType, &log.Notes, &log.CreatedAt)
	if err != nil {
		return MealLog{}, err
	}
	log.LoggedOn = loggedOn.Format("2006-01-02")

	rows, err := s.pool.Query(ctx, `
		SELECT mli.id, mli.food_id, f.name, f.image_url, mli.serving_g::float8
		FROM meal_log_items mli
		JOIN foods f ON f.id = mli.food_id
		WHERE mli.meal_log_id = $1 AND mli.user_id = $2
		ORDER BY mli.created_at ASC
	`, logID, userID)
	if err != nil {
		return MealLog{}, err
	}
	defer rows.Close()

	for rows.Next() {
		var item MealLogItem
		if err := rows.Scan(&item.ID, &item.FoodID, &item.FoodName, &item.ImageURL, &item.ServingG); err != nil {
			return MealLog{}, err
		}
		log.Items = append(log.Items, item)
	}
	return log, rows.Err()
}

func (s *Store) ListMealLogs(ctx context.Context, userID uuid.UUID, from, to string) ([]MealLog, error) {
	rows, err := s.pool.Query(ctx, `
		SELECT id, user_id, logged_on, meal_type, notes, created_at
		FROM meal_logs
		WHERE user_id = $1
		  AND ($2 = '' OR logged_on >= $2::date)
		  AND ($3 = '' OR logged_on <= $3::date)
		ORDER BY logged_on DESC, created_at DESC
	`, userID, from, to)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	logs := []MealLog{}
	logIndexByID := map[uuid.UUID]int{}
	for rows.Next() {
		var log MealLog
		var loggedOn time.Time
		if err := rows.Scan(&log.ID, &log.UserID, &loggedOn, &log.MealType, &log.Notes, &log.CreatedAt); err != nil {
			return nil, err
		}
		log.LoggedOn = loggedOn.Format("2006-01-02")
		log.Items = []MealLogItem{}
		logIndexByID[log.ID] = len(logs)
		logs = append(logs, log)
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}
	if len(logs) == 0 {
		return logs, nil
	}

	logIDs := make([]uuid.UUID, 0, len(logs))
	for _, log := range logs {
		logIDs = append(logIDs, log.ID)
	}

	itemRows, err := s.pool.Query(ctx, `
		SELECT mli.meal_log_id, mli.id, mli.food_id, f.name, f.image_url, mli.serving_g::float8
		FROM meal_log_items mli
		JOIN foods f ON f.id = mli.food_id
		WHERE mli.user_id = $1 AND mli.meal_log_id = ANY($2)
		ORDER BY mli.created_at ASC
	`, userID, logIDs)
	if err != nil {
		return nil, err
	}
	defer itemRows.Close()

	for itemRows.Next() {
		var logID uuid.UUID
		var item MealLogItem
		if err := itemRows.Scan(&logID, &item.ID, &item.FoodID, &item.FoodName, &item.ImageURL, &item.ServingG); err != nil {
			return nil, err
		}
		if index, ok := logIndexByID[logID]; ok {
			logs[index].Items = append(logs[index].Items, item)
		}
	}
	return logs, itemRows.Err()
}

func (s *Store) DeleteMealLog(ctx context.Context, userID, logID uuid.UUID) error {
	_, err := s.pool.Exec(ctx, `DELETE FROM meal_logs WHERE id = $1 AND user_id = $2`, logID, userID)
	return err
}

func (s *Store) GetDailyNutrientTotals(ctx context.Context, userID uuid.UUID, date string) (DayNutrientTotals, error) {
	rows, err := s.pool.Query(ctx, `
		SELECT
			t.code,
			t.name,
			t.unit,
			t.amount::float8,
			d.amount::float8,
			CASE WHEN d.amount IS NULL THEN NULL ELSE ROUND((t.amount / d.amount) * 100, 1)::float8 END
		FROM daily_nutrient_totals t
		JOIN user_profiles p ON p.user_id = $1
		LEFT JOIN LATERAL (
			SELECT amount
			FROM dri_values d
			WHERE d.nutrient_id = t.nutrient_id
			  AND d.life_stage IN ('adult', CASE WHEN p.pregnancy_status = 'pregnant' THEN 'pregnancy' ELSE 'adult' END)
			  AND (d.sex = p.sex OR d.sex IS NULL)
			ORDER BY
			  CASE WHEN d.life_stage = CASE WHEN p.pregnancy_status = 'pregnant' THEN 'pregnancy' ELSE 'adult' END THEN 0 ELSE 1 END,
			  CASE WHEN d.sex = p.sex THEN 0 ELSE 1 END
			LIMIT 1
		) d ON true
		WHERE t.user_id = $1 AND t.logged_on = $2::date
		ORDER BY t.name
	`, userID, date)
	if err != nil {
		return DayNutrientTotals{}, err
	}
	defer rows.Close()

	totals := DayNutrientTotals{Date: date, Nutrients: []NutrientTotal{}}
	for rows.Next() {
		var total NutrientTotal
		if err := rows.Scan(&total.Code, &total.Name, &total.Unit, &total.Amount, &total.DRIAmount, &total.DRIPercent); err != nil {
			return DayNutrientTotals{}, err
		}
		totals.Nutrients = append(totals.Nutrients, total)
	}
	return totals, rows.Err()
}

func (s *Store) GetWeekNutrientTotals(ctx context.Context, userID uuid.UUID, endDate string) ([]DayNutrientTotals, error) {
	rows, err := s.pool.Query(ctx, `
		WITH days AS (
			SELECT logged_on::date
			FROM generate_series(($2::date - interval '6 days')::date, $2::date, interval '1 day') logged_on
		)
		SELECT
			days.logged_on::text,
			t.code,
			t.name,
			t.unit,
			t.amount::float8,
			d.amount::float8,
			CASE WHEN d.amount IS NULL OR t.amount IS NULL THEN NULL ELSE ROUND((t.amount / d.amount) * 100, 1)::float8 END
		FROM days
		LEFT JOIN daily_nutrient_totals t ON t.user_id = $1 AND t.logged_on = days.logged_on
		JOIN user_profiles p ON p.user_id = $1
		LEFT JOIN LATERAL (
			SELECT amount
			FROM dri_values d
			WHERE d.nutrient_id = t.nutrient_id
			  AND d.life_stage IN ('adult', CASE WHEN p.pregnancy_status = 'pregnant' THEN 'pregnancy' ELSE 'adult' END)
			  AND (d.sex = p.sex OR d.sex IS NULL)
			ORDER BY
			  CASE WHEN d.life_stage = CASE WHEN p.pregnancy_status = 'pregnant' THEN 'pregnancy' ELSE 'adult' END THEN 0 ELSE 1 END,
			  CASE WHEN d.sex = p.sex THEN 0 ELSE 1 END
			LIMIT 1
		) d ON true
		ORDER BY days.logged_on ASC, t.name ASC
	`, userID, endDate)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	dayIndex := map[string]int{}
	days := make([]DayNutrientTotals, 0, 7)
	for rows.Next() {
		var date string
		var code *string
		var name *string
		var unit *string
		var amount *float64
		var driAmount *float64
		var driPercent *float64
		if err := rows.Scan(&date, &code, &name, &unit, &amount, &driAmount, &driPercent); err != nil {
			return nil, err
		}
		index, ok := dayIndex[date]
		if !ok {
			days = append(days, DayNutrientTotals{Date: date, Nutrients: []NutrientTotal{}})
			index = len(days) - 1
			dayIndex[date] = index
		}
		if code != nil && name != nil && unit != nil && amount != nil {
			days[index].Nutrients = append(days[index].Nutrients, NutrientTotal{
				Code:       *code,
				Name:       *name,
				Unit:       *unit,
				Amount:     *amount,
				DRIAmount:  driAmount,
				DRIPercent: driPercent,
			})
		}
	}
	return days, rows.Err()
}

func (s *Store) GetStreak(ctx context.Context, userID uuid.UUID, today string) (int, error) {
	streak := 0
	err := s.pool.QueryRow(ctx, `
		WITH days AS (
			SELECT day::date AS logged_on
			FROM generate_series($2::date, ($2::date - interval '365 days')::date, '-1 day') day
		),
		flags AS (
			SELECT
				days.logged_on,
				EXISTS (
					SELECT 1
					FROM meal_logs ml
					WHERE ml.user_id = $1 AND ml.logged_on = days.logged_on
				) AS has_log
			FROM days
		),
		numbered AS (
			SELECT
				logged_on,
				has_log,
				SUM(CASE WHEN has_log THEN 0 ELSE 1 END) OVER (ORDER BY logged_on DESC) AS misses_so_far
			FROM flags
		)
		SELECT COUNT(*)::int
		FROM numbered
		WHERE has_log AND misses_so_far = 0
	`, userID, today).Scan(&streak)
	return streak, err
}
