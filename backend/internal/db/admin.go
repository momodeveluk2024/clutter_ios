package db

import (
	"context"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
)

type AdminKPIValue struct {
	Value         int     `json:"value"`
	DeltaPct      float64 `json:"deltaPct,omitempty"`
	AddedThisWeek int     `json:"addedThisWeek,omitempty"`
	Over7Days     int     `json:"over7days,omitempty"`
}

type AdminOverview struct {
	KPIs struct {
		ActiveUsers7d       AdminKPIValue `json:"activeUsers7d"`
		MealsLoggedToday    AdminKPIValue `json:"mealsLoggedToday"`
		FoodsInCatalog      AdminKPIValue `json:"foodsInCatalog"`
		PendingVerification AdminKPIValue `json:"pendingVerification"`
	} `json:"kpis"`
	LogsByDay    []AdminLogsByDay   `json:"logsByDay"`
	TopNutrients []AdminTopNutrient `json:"topNutrients"`
}

type AdminLogsByDay struct {
	Day  string `json:"day"`
	Logs int    `json:"logs"`
}

type AdminTopNutrient struct {
	Code string `json:"code"`
	Logs int    `json:"logs"`
}

type AdminUserSummary struct {
	ID          uuid.UUID  `json:"id"`
	Email       string     `json:"email"`
	Role        string     `json:"role"`
	DisplayName string     `json:"displayName"`
	Initials    string     `json:"initials"`
	Sex         *string    `json:"sex"`
	Age         *int       `json:"age"`
	Activity    *string    `json:"activity"`
	Status      string     `json:"status"`
	Logs30d     int        `json:"logs30d"`
	LastActive  *time.Time `json:"lastActive"`
	Joined      string     `json:"joined"`
	Platform    string     `json:"platform"`
	SuspendedAt *time.Time `json:"suspendedAt,omitempty"`
	DeletedAt   *time.Time `json:"deletedAt,omitempty"`
}

type AdminUserDetail struct {
	AdminUserSummary
	Timezone      string             `json:"timezone"`
	Units         string             `json:"units"`
	Goals         []string           `json:"goals"`
	Allergens     []string           `json:"allergens"`
	RecentLogs    []AdminMealLog     `json:"recentLogs"`
	Sessions      []AdminUserSession `json:"sessions"`
	ReminderCount int                `json:"reminderCount"`
	SafetyStatus  string             `json:"safetyStatus"`
}

type AdminUserSession struct {
	ID        uuid.UUID  `json:"id"`
	UserAgent *string    `json:"userAgent,omitempty"`
	IP        *string    `json:"ip,omitempty"`
	CreatedAt time.Time  `json:"createdAt"`
	ExpiresAt time.Time  `json:"expiresAt"`
	RevokedAt *time.Time `json:"revokedAt,omitempty"`
}

type AdminMealLog struct {
	ID           uuid.UUID `json:"id"`
	UserID       uuid.UUID `json:"userId"`
	UserEmail    string    `json:"userEmail"`
	UserInitials string    `json:"userInitials"`
	LoggedAt     time.Time `json:"loggedAt"`
	Meal         string    `json:"meal"`
	Items        string    `json:"items"`
	TopNutrients []string  `json:"topNutrients"`
	Flagged      bool      `json:"flagged,omitempty"`
}

type AdminNutrient struct {
	ID        uuid.UUID `json:"id"`
	Code      string    `json:"code"`
	Name      string    `json:"name"`
	Unit      string    `json:"unit"`
	Group     string    `json:"group"`
	DRIAdult  float64   `json:"driAdult"`
	FoodCount int       `json:"foodCount"`
	UpdatedAt string    `json:"updatedAt"`
}

type AdminFood struct {
	ID           uuid.UUID      `json:"id"`
	Name         string         `json:"name"`
	Brand        *string        `json:"brand,omitempty"`
	Category     string         `json:"category"`
	ServingSizeG float64        `json:"servingSizeG"`
	Source       string         `json:"source"`
	Verified     bool           `json:"verified"`
	ImageURL     *string        `json:"imageUrl,omitempty"`
	Barcode      *string        `json:"barcode,omitempty"`
	UpdatedAt    time.Time      `json:"updatedAt"`
	Nutrients    []FoodNutrient `json:"nutrients"`
}

type AdminReminder struct {
	ID        uuid.UUID `json:"id"`
	UserID    uuid.UUID `json:"userId"`
	UserEmail string    `json:"userEmail"`
	Title     string    `json:"title"`
	Body      *string   `json:"body,omitempty"`
	Trigger   string    `json:"trigger"`
	Audience  string    `json:"audience"`
	Sent7d    int       `json:"sent7d"`
	Active    bool      `json:"active"`
	RemindAt  time.Time `json:"remindAt"`
	Timezone  string    `json:"timezone"`
}

type AdminReminderTemplate struct {
	ID        uuid.UUID `json:"id"`
	Title     string    `json:"title"`
	Body      string    `json:"body"`
	Trigger   string    `json:"trigger"`
	Audience  string    `json:"audience"`
	Sent7d    int       `json:"sent7d"`
	Active    bool      `json:"active"`
	UpdatedAt time.Time `json:"updatedAt"`
}

type AdminAuditEntry struct {
	ID        string    `json:"id"`
	Actor     string    `json:"actor"`
	Action    string    `json:"action"`
	Target    string    `json:"target"`
	CreatedAt time.Time `json:"createdAt"`
}

type UpdateAdminFoodParams struct {
	ID               uuid.UUID
	Name             *string
	Brand            *string
	Category         *string
	ServingSizeG     *float64
	ImageURL         *string
	Barcode          *string
	Source           *string
	Verified         *bool
	Nutrients        []CreateFoodNutrient
	ReplaceNutrients bool
}

type CreateAdminFoodParams struct {
	Name         string
	Brand        *string
	Category     string
	ServingSizeG float64
	ImageURL     *string
	Barcode      *string
	Source       string
	Verified     bool
	Nutrients    []CreateFoodNutrient
}

type UpsertAdminNutrientParams struct {
	Code     string
	Name     string
	Unit     string
	Group    string
	DRIAdult float64
}

type UpdateAdminUserProfileParams struct {
	UserID      uuid.UUID
	DisplayName *string
	Sex         *string
	Activity    *string
	Timezone    *string
	Units       *string
}

type UpsertAdminReminderTemplateParams struct {
	ID       uuid.UUID
	Title    string
	Body     string
	Trigger  string
	Audience string
	Active   bool
}

func (s *Store) GetAdminOverview(ctx context.Context, now time.Time, rangeName string) (AdminOverview, error) {
	var overview AdminOverview
	today := now.Format("2006-01-02")
	daysBack := adminRangeDays(rangeName)
	rangeStart := now.AddDate(0, 0, -daysBack)

	if err := s.pool.QueryRow(ctx, `
		SELECT
			(SELECT COUNT(DISTINCT user_id)::int FROM sessions WHERE created_at >= $1),
			(SELECT COUNT(*)::int FROM meal_logs WHERE logged_on = $2::date),
			(SELECT COUNT(*)::int FROM foods WHERE deleted_at IS NULL),
			(SELECT COUNT(*)::int FROM foods WHERE deleted_at IS NULL AND created_at >= $1),
			(SELECT COUNT(*)::int FROM foods WHERE deleted_at IS NULL AND verified = false),
			(SELECT COUNT(*)::int FROM foods WHERE deleted_at IS NULL AND verified = false AND created_at < $1)
	`, rangeStart, today).Scan(
		&overview.KPIs.ActiveUsers7d.Value,
		&overview.KPIs.MealsLoggedToday.Value,
		&overview.KPIs.FoodsInCatalog.Value,
		&overview.KPIs.FoodsInCatalog.AddedThisWeek,
		&overview.KPIs.PendingVerification.Value,
		&overview.KPIs.PendingVerification.Over7Days,
	); err != nil {
		return AdminOverview{}, err
	}

	rows, err := s.pool.Query(ctx, `
		WITH days AS (
			SELECT day::date AS day
			FROM generate_series(($1::date - make_interval(days => $2::int))::date, $1::date, interval '1 day') day
		)
		SELECT to_char(days.day, 'Mon DD'), COUNT(ml.id)::int
		FROM days
		LEFT JOIN meal_logs ml ON ml.logged_on = days.day
		GROUP BY days.day
		ORDER BY days.day ASC
	`, today, daysBack)
	if err != nil {
		return AdminOverview{}, err
	}
	defer rows.Close()
	for rows.Next() {
		var point AdminLogsByDay
		if err := rows.Scan(&point.Day, &point.Logs); err != nil {
			return AdminOverview{}, err
		}
		overview.LogsByDay = append(overview.LogsByDay, point)
	}
	if err := rows.Err(); err != nil {
		return AdminOverview{}, err
	}

	nutrientRows, err := s.pool.Query(ctx, `
		SELECT n.code, COUNT(DISTINCT ml.id)::int AS logs
		FROM meal_logs ml
		JOIN meal_log_items mli ON mli.meal_log_id = ml.id
		JOIN food_nutrients fn ON fn.food_id = mli.food_id
		JOIN nutrients n ON n.id = fn.nutrient_id
		WHERE ml.logged_on >= ($1::date - interval '30 days')::date
		GROUP BY n.code
		ORDER BY logs DESC, n.code ASC
		LIMIT 8
	`, today)
	if err != nil {
		return AdminOverview{}, err
	}
	defer nutrientRows.Close()
	for nutrientRows.Next() {
		var nutrient AdminTopNutrient
		if err := nutrientRows.Scan(&nutrient.Code, &nutrient.Logs); err != nil {
			return AdminOverview{}, err
		}
		overview.TopNutrients = append(overview.TopNutrients, nutrient)
	}
	return overview, nutrientRows.Err()
}

func (s *Store) ListAdminUsers(ctx context.Context, status string, limit int) ([]AdminUserSummary, error) {
	if limit <= 0 || limit > 100 {
		limit = 50
	}
	rows, err := s.pool.Query(ctx, `
		SELECT
			u.id,
			u.email::text,
			u.role,
			p.display_name,
			p.sex,
			CASE WHEN p.date_of_birth IS NULL THEN NULL ELSE date_part('year', age(p.date_of_birth))::int END,
			p.activity_level,
			CASE
				WHEN u.deleted_at IS NOT NULL THEN 'pending_deletion'
				WHEN u.suspended_at IS NOT NULL THEN 'suspended'
				WHEN u.email_verified_at IS NULL THEN 'unverified'
				ELSE 'verified'
			END AS status,
			(SELECT COUNT(*)::int FROM meal_logs ml WHERE ml.user_id = u.id AND ml.logged_on >= current_date - interval '30 days') AS logs30d,
			(SELECT MAX(s.created_at) FROM sessions s WHERE s.user_id = u.id) AS last_active,
			to_char(u.created_at, 'YYYY-MM-DD') AS joined,
			COALESCE((SELECT CASE WHEN s.user_agent ILIKE '%android%' THEN 'Android' WHEN s.user_agent ILIKE '%iphone%' OR s.user_agent ILIKE '%ios%' THEN 'iOS' ELSE 'Web' END FROM sessions s WHERE s.user_id = u.id ORDER BY s.created_at DESC LIMIT 1), 'Web') AS platform,
			u.suspended_at,
			u.deleted_at
		FROM users u
		JOIN user_profiles p ON p.user_id = u.id
		WHERE ($1 = '' OR CASE
				WHEN u.deleted_at IS NOT NULL THEN 'pending_deletion'
				WHEN u.suspended_at IS NOT NULL THEN 'suspended'
				WHEN u.email_verified_at IS NULL THEN 'unverified'
				ELSE 'verified'
			END = $1)
		ORDER BY u.created_at DESC
		LIMIT $2
	`, strings.TrimSpace(status), limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	users := []AdminUserSummary{}
	for rows.Next() {
		var user AdminUserSummary
		if err := rows.Scan(&user.ID, &user.Email, &user.Role, &user.DisplayName, &user.Sex, &user.Age, &user.Activity, &user.Status, &user.Logs30d, &user.LastActive, &user.Joined, &user.Platform, &user.SuspendedAt, &user.DeletedAt); err != nil {
			return nil, err
		}
		user.Initials = initials(user.DisplayName, user.Email)
		users = append(users, user)
	}
	return users, rows.Err()
}

func (s *Store) GetAdminUser(ctx context.Context, userID uuid.UUID) (AdminUserDetail, error) {
	users, err := s.ListAdminUsers(ctx, "", 100)
	if err != nil {
		return AdminUserDetail{}, err
	}
	var detail AdminUserDetail
	found := false
	for _, user := range users {
		if user.ID == userID {
			detail.AdminUserSummary = user
			found = true
			break
		}
	}
	if !found {
		return AdminUserDetail{}, pgx.ErrNoRows
	}

	if err := s.pool.QueryRow(ctx, `
		SELECT timezone, units, goals, allergens, (SELECT COUNT(*)::int FROM reminders WHERE user_id = $1)
		FROM user_profiles
		WHERE user_id = $1
	`, userID).Scan(&detail.Timezone, &detail.Units, &detail.Goals, &detail.Allergens, &detail.ReminderCount); err != nil {
		return AdminUserDetail{}, err
	}
	detail.SafetyStatus = "normal"

	logs, err := s.ListAdminMealLogs(ctx, userID, "", "", 5)
	if err != nil {
		return AdminUserDetail{}, err
	}
	detail.RecentLogs = logs

	sessionRows, err := s.pool.Query(ctx, `
		SELECT id, user_agent, ip::text, created_at, expires_at, revoked_at
		FROM sessions
		WHERE user_id = $1
		ORDER BY created_at DESC
		LIMIT 10
	`, userID)
	if err != nil {
		return AdminUserDetail{}, err
	}
	defer sessionRows.Close()
	for sessionRows.Next() {
		var session AdminUserSession
		if err := sessionRows.Scan(&session.ID, &session.UserAgent, &session.IP, &session.CreatedAt, &session.ExpiresAt, &session.RevokedAt); err != nil {
			return AdminUserDetail{}, err
		}
		detail.Sessions = append(detail.Sessions, session)
	}
	return detail, sessionRows.Err()
}

func (s *Store) ListAdminMealLogs(ctx context.Context, userID uuid.UUID, from, to string, limit int) ([]AdminMealLog, error) {
	if limit <= 0 || limit > 100 {
		limit = 50
	}
	rows, err := s.pool.Query(ctx, `
		SELECT
			ml.id,
			ml.user_id,
			u.email::text,
			p.display_name,
			ml.created_at,
			ml.meal_type,
			COALESCE(string_agg(DISTINCT f.name, ', '), '(no items)') AS items,
			COALESCE(array_agg(DISTINCT n.code) FILTER (WHERE n.code IS NOT NULL), '{}')::text[] AS nutrients,
			COUNT(mli.id) = 0 AS flagged
		FROM meal_logs ml
		JOIN users u ON u.id = ml.user_id
		JOIN user_profiles p ON p.user_id = u.id
		LEFT JOIN meal_log_items mli ON mli.meal_log_id = ml.id
		LEFT JOIN foods f ON f.id = mli.food_id
		LEFT JOIN food_nutrients fn ON fn.food_id = f.id
		LEFT JOIN nutrients n ON n.id = fn.nutrient_id
		WHERE ($1::uuid IS NULL OR ml.user_id = $1)
		  AND ($2 = '' OR ml.logged_on >= $2::date)
		  AND ($3 = '' OR ml.logged_on <= $3::date)
		GROUP BY ml.id, ml.user_id, u.email, p.display_name, ml.created_at, ml.meal_type
		ORDER BY ml.logged_on DESC, ml.created_at DESC
		LIMIT $4
	`, nullableUUID(userID), strings.TrimSpace(from), strings.TrimSpace(to), limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	logs := []AdminMealLog{}
	for rows.Next() {
		var log AdminMealLog
		var displayName string
		if err := rows.Scan(&log.ID, &log.UserID, &log.UserEmail, &displayName, &log.LoggedAt, &log.Meal, &log.Items, &log.TopNutrients, &log.Flagged); err != nil {
			return nil, err
		}
		log.UserInitials = initials(displayName, log.UserEmail)
		logs = append(logs, log)
	}
	return logs, rows.Err()
}

func (s *Store) ListAdminNutrients(ctx context.Context) ([]AdminNutrient, error) {
	rows, err := s.pool.Query(ctx, `
		SELECT
			n.id,
			n.code,
			n.name,
			n.unit,
			n.nutrient_group,
			COALESCE(d.amount::float8, 0),
			COUNT(DISTINCT fn.food_id)::int,
			to_char(MAX(COALESCE(d.created_at, n.created_at)), 'YYYY-MM-DD')
		FROM nutrients n
		LEFT JOIN dri_values d ON d.nutrient_id = n.id AND d.life_stage = 'adult' AND d.sex IS NULL
		LEFT JOIN food_nutrients fn ON fn.nutrient_id = n.id
		GROUP BY n.id, n.code, n.name, n.unit, n.nutrient_group, d.amount
		ORDER BY n.nutrient_group, n.name
	`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	nutrients := []AdminNutrient{}
	for rows.Next() {
		var nutrient AdminNutrient
		if err := rows.Scan(&nutrient.ID, &nutrient.Code, &nutrient.Name, &nutrient.Unit, &nutrient.Group, &nutrient.DRIAdult, &nutrient.FoodCount, &nutrient.UpdatedAt); err != nil {
			return nil, err
		}
		nutrients = append(nutrients, nutrient)
	}
	return nutrients, rows.Err()
}

func (s *Store) UpdateAdminNutrientDRI(ctx context.Context, code string, amount float64) (AdminNutrient, error) {
	tx, err := s.pool.BeginTx(ctx, pgx.TxOptions{})
	if err != nil {
		return AdminNutrient{}, err
	}
	defer tx.Rollback(ctx)

	var nutrientID uuid.UUID
	if err := tx.QueryRow(ctx, `SELECT id FROM nutrients WHERE lower(code) = lower($1)`, strings.TrimSpace(code)).Scan(&nutrientID); err != nil {
		return AdminNutrient{}, err
	}
	tag, err := tx.Exec(ctx, `
		UPDATE dri_values
		SET amount = $2,
		    created_at = now()
		WHERE nutrient_id = $1
		  AND life_stage = 'adult'
		  AND sex IS NULL
	`, nutrientID, amount)
	if err != nil {
		return AdminNutrient{}, err
	}
	if tag.RowsAffected() == 0 {
		if _, err := tx.Exec(ctx, `
			INSERT INTO dri_values (id, nutrient_id, life_stage, sex, amount)
			VALUES (gen_random_uuid(), $1, 'adult', NULL, $2)
		`, nutrientID, amount); err != nil {
			return AdminNutrient{}, err
		}
	}
	if err := tx.Commit(ctx); err != nil {
		return AdminNutrient{}, err
	}
	nutrients, err := s.ListAdminNutrients(ctx)
	if err != nil {
		return AdminNutrient{}, err
	}
	for _, nutrient := range nutrients {
		if strings.EqualFold(nutrient.Code, code) {
			return nutrient, nil
		}
	}
	return AdminNutrient{}, pgx.ErrNoRows
}

func (s *Store) ListAdminFoods(ctx context.Context, q, category, verified string, limit int) ([]AdminFood, error) {
	if limit <= 0 || limit > 100 {
		limit = 50
	}
	rows, err := s.pool.Query(ctx, `
		SELECT id, name, brand, category, serving_size_g::float8, source, verified, image_url, barcode, updated_at
		FROM foods
		WHERE deleted_at IS NULL
		  AND ($1 = '' OR name ILIKE '%' || $1 || '%' OR similarity(name, $1) > 0.18)
		  AND ($2 = '' OR category = $2)
		  AND ($3 = '' OR verified = ($3 = 'true'))
		ORDER BY verified ASC, updated_at DESC, name ASC
		LIMIT $4
	`, strings.TrimSpace(q), strings.TrimSpace(category), strings.TrimSpace(verified), limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	foods := []AdminFood{}
	for rows.Next() {
		var food AdminFood
		if err := rows.Scan(&food.ID, &food.Name, &food.Brand, &food.Category, &food.ServingSizeG, &food.Source, &food.Verified, &food.ImageURL, &food.Barcode, &food.UpdatedAt); err != nil {
			return nil, err
		}
		if food.Source == "user" {
			food.Source = "user_submitted"
		}
		foods = append(foods, food)
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}
	for i := range foods {
		detail, err := s.GetFoodDetail(ctx, foods[i].ID)
		if err != nil {
			return nil, err
		}
		foods[i].Nutrients = detail.Nutrients
	}
	return foods, nil
}

func (s *Store) UpdateAdminFood(ctx context.Context, params UpdateAdminFoodParams) (FoodDetail, error) {
	tx, err := s.pool.BeginTx(ctx, pgx.TxOptions{})
	if err != nil {
		return FoodDetail{}, err
	}
	defer tx.Rollback(ctx)

	_, err = tx.Exec(ctx, `
		UPDATE foods
		SET name = COALESCE($2, name),
		    brand = COALESCE($3, brand),
		    category = COALESCE($4, category),
		    serving_size_g = COALESCE($5, serving_size_g),
		    image_url = COALESCE($6, image_url),
		    barcode = COALESCE($7, barcode),
		    source = COALESCE($8, source),
		    verified = COALESCE($9, verified),
		    updated_at = now()
		WHERE id = $1 AND deleted_at IS NULL
	`, params.ID, trimAdminOptional(params.Name), trimAdminOptional(params.Brand), trimAdminOptional(params.Category), params.ServingSizeG, trimAdminOptional(params.ImageURL), trimAdminOptional(params.Barcode), trimAdminOptional(params.Source), params.Verified)
	if err != nil {
		return FoodDetail{}, err
	}
	if params.ReplaceNutrients {
		if _, err := tx.Exec(ctx, `DELETE FROM food_nutrients WHERE food_id = $1`, params.ID); err != nil {
			return FoodDetail{}, err
		}
		for _, nutrient := range params.Nutrients {
			if _, err := tx.Exec(ctx, `
				INSERT INTO food_nutrients (food_id, nutrient_id, amount_per_100g)
				SELECT $1, id, $3
				FROM nutrients
				WHERE lower(code) = lower($2)
				ON CONFLICT (food_id, nutrient_id) DO UPDATE
				SET amount_per_100g = EXCLUDED.amount_per_100g
			`, params.ID, nutrient.Code, nutrient.AmountPer100G); err != nil {
				return FoodDetail{}, err
			}
		}
	}
	if err := tx.Commit(ctx); err != nil {
		return FoodDetail{}, err
	}
	return s.GetFoodDetail(ctx, params.ID)
}

func (s *Store) VerifyAdminFood(ctx context.Context, foodID uuid.UUID) (FoodDetail, error) {
	_, err := s.pool.Exec(ctx, `UPDATE foods SET verified = true, updated_at = now() WHERE id = $1 AND deleted_at IS NULL`, foodID)
	if err != nil {
		return FoodDetail{}, err
	}
	return s.GetFoodDetail(ctx, foodID)
}

func (s *Store) DeleteAdminFood(ctx context.Context, foodID uuid.UUID) error {
	_, err := s.pool.Exec(ctx, `UPDATE foods SET deleted_at = now(), updated_at = now() WHERE id = $1 AND deleted_at IS NULL`, foodID)
	return err
}

func (s *Store) CreateAdminFood(ctx context.Context, params CreateAdminFoodParams) (FoodDetail, error) {
	foodID, err := uuid.NewV7()
	if err != nil {
		return FoodDetail{}, err
	}
	tx, err := s.pool.BeginTx(ctx, pgx.TxOptions{})
	if err != nil {
		return FoodDetail{}, err
	}
	defer tx.Rollback(ctx)

	_, err = tx.Exec(ctx, `
		INSERT INTO foods (id, name, brand, category, serving_size_g, source, verified, barcode, image_url)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
	`, foodID, strings.TrimSpace(params.Name), trimAdminOptional(params.Brand), strings.ToLower(strings.TrimSpace(params.Category)), params.ServingSizeG, strings.TrimSpace(params.Source), params.Verified, trimAdminOptional(params.Barcode), trimAdminOptional(params.ImageURL))
	if err != nil {
		return FoodDetail{}, err
	}
	for _, nutrient := range params.Nutrients {
		if _, err := tx.Exec(ctx, `
			INSERT INTO food_nutrients (food_id, nutrient_id, amount_per_100g)
			SELECT $1, id, $3
			FROM nutrients
			WHERE lower(code) = lower($2)
		`, foodID, nutrient.Code, nutrient.AmountPer100G); err != nil {
			return FoodDetail{}, err
		}
	}
	if err := tx.Commit(ctx); err != nil {
		return FoodDetail{}, err
	}
	return s.GetFoodDetail(ctx, foodID)
}

func (s *Store) UpsertAdminNutrient(ctx context.Context, params UpsertAdminNutrientParams) (AdminNutrient, error) {
	tx, err := s.pool.BeginTx(ctx, pgx.TxOptions{})
	if err != nil {
		return AdminNutrient{}, err
	}
	defer tx.Rollback(ctx)

	var nutrientID uuid.UUID
	if err := tx.QueryRow(ctx, `
		INSERT INTO nutrients (id, code, name, unit, nutrient_group)
		VALUES (gen_random_uuid(), $1, $2, $3, $4)
		ON CONFLICT (code) DO UPDATE
		SET name = EXCLUDED.name,
		    unit = EXCLUDED.unit,
		    nutrient_group = EXCLUDED.nutrient_group
		RETURNING id
	`, strings.TrimSpace(params.Code), strings.TrimSpace(params.Name), strings.TrimSpace(params.Unit), strings.TrimSpace(params.Group)).Scan(&nutrientID); err != nil {
		return AdminNutrient{}, err
	}
	if params.DRIAdult > 0 {
		tag, err := tx.Exec(ctx, `
			UPDATE dri_values
			SET amount = $2,
			    created_at = now()
			WHERE nutrient_id = $1 AND life_stage = 'adult' AND sex IS NULL
		`, nutrientID, params.DRIAdult)
		if err != nil {
			return AdminNutrient{}, err
		}
		if tag.RowsAffected() == 0 {
			if _, err := tx.Exec(ctx, `
				INSERT INTO dri_values (id, nutrient_id, life_stage, sex, amount)
				VALUES (gen_random_uuid(), $1, 'adult', NULL, $2)
			`, nutrientID, params.DRIAdult); err != nil {
				return AdminNutrient{}, err
			}
		}
	}
	if err := tx.Commit(ctx); err != nil {
		return AdminNutrient{}, err
	}
	return s.adminNutrientByCode(ctx, params.Code)
}

func (s *Store) adminNutrientByCode(ctx context.Context, code string) (AdminNutrient, error) {
	nutrients, err := s.ListAdminNutrients(ctx)
	if err != nil {
		return AdminNutrient{}, err
	}
	for _, nutrient := range nutrients {
		if strings.EqualFold(nutrient.Code, code) {
			return nutrient, nil
		}
	}
	return AdminNutrient{}, pgx.ErrNoRows
}

func (s *Store) VerifyAdminUser(ctx context.Context, userID uuid.UUID) (AdminUserDetail, error) {
	_, err := s.pool.Exec(ctx, `UPDATE users SET email_verified_at = COALESCE(email_verified_at, now()), updated_at = now() WHERE id = $1`, userID)
	if err != nil {
		return AdminUserDetail{}, err
	}
	return s.GetAdminUser(ctx, userID)
}

func (s *Store) SuspendAdminUser(ctx context.Context, userID uuid.UUID, suspended bool) (AdminUserDetail, error) {
	_, err := s.pool.Exec(ctx, `
		UPDATE users
		SET suspended_at = CASE WHEN $2 THEN COALESCE(suspended_at, now()) ELSE NULL END,
		    updated_at = now()
		WHERE id = $1 AND deleted_at IS NULL
	`, userID, suspended)
	if err != nil {
		return AdminUserDetail{}, err
	}
	if suspended {
		_, _ = s.pool.Exec(ctx, `UPDATE sessions SET revoked_at = now() WHERE user_id = $1 AND revoked_at IS NULL`, userID)
	}
	return s.GetAdminUser(ctx, userID)
}

func (s *Store) DeleteAdminUser(ctx context.Context, userID uuid.UUID) error {
	_, err := s.pool.Exec(ctx, `UPDATE users SET deleted_at = COALESCE(deleted_at, now()), updated_at = now() WHERE id = $1`, userID)
	if err != nil {
		return err
	}
	_, err = s.pool.Exec(ctx, `UPDATE sessions SET revoked_at = now() WHERE user_id = $1 AND revoked_at IS NULL`, userID)
	return err
}

func (s *Store) UpdateAdminUserProfile(ctx context.Context, params UpdateAdminUserProfileParams) (AdminUserDetail, error) {
	_, err := s.pool.Exec(ctx, `
		UPDATE user_profiles
		SET display_name = COALESCE($2, display_name),
		    sex = COALESCE($3, sex),
		    activity_level = COALESCE($4, activity_level),
		    timezone = COALESCE($5, timezone),
		    units = COALESCE($6, units),
		    updated_at = now()
		WHERE user_id = $1
	`, params.UserID, trimAdminOptional(params.DisplayName), trimAdminOptional(params.Sex), trimAdminOptional(params.Activity), trimAdminOptional(params.Timezone), trimAdminOptional(params.Units))
	if err != nil {
		return AdminUserDetail{}, err
	}
	return s.GetAdminUser(ctx, params.UserID)
}

func (s *Store) RevokeAdminUserSession(ctx context.Context, userID, sessionID uuid.UUID) error {
	_, err := s.pool.Exec(ctx, `UPDATE sessions SET revoked_at = now() WHERE user_id = $1 AND id = $2 AND revoked_at IS NULL`, userID, sessionID)
	return err
}

func (s *Store) ListAdminReminders(ctx context.Context, limit int) ([]AdminReminder, error) {
	if limit <= 0 || limit > 100 {
		limit = 50
	}
	rows, err := s.pool.Query(ctx, `
		SELECT r.id, r.user_id, u.email::text, r.title, r.body, r.remind_at, r.timezone, r.enabled
		FROM reminders r
		JOIN users u ON u.id = r.user_id
		ORDER BY r.remind_at ASC
		LIMIT $1
	`, limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	reminders := []AdminReminder{}
	for rows.Next() {
		var reminder AdminReminder
		if err := rows.Scan(&reminder.ID, &reminder.UserID, &reminder.UserEmail, &reminder.Title, &reminder.Body, &reminder.RemindAt, &reminder.Timezone, &reminder.Active); err != nil {
			return nil, err
		}
		reminder.Trigger = reminder.RemindAt.Format(time.RFC3339)
		reminder.Audience = reminder.UserEmail
		reminders = append(reminders, reminder)
	}
	return reminders, rows.Err()
}

func (s *Store) ListAdminReminderTemplates(ctx context.Context) ([]AdminReminderTemplate, error) {
	rows, err := s.pool.Query(ctx, `
		SELECT id, title, body, trigger, audience, sent_7d, active, updated_at
		FROM reminder_templates
		ORDER BY active DESC, updated_at DESC, title ASC
	`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	templates := []AdminReminderTemplate{}
	for rows.Next() {
		var template AdminReminderTemplate
		if err := rows.Scan(&template.ID, &template.Title, &template.Body, &template.Trigger, &template.Audience, &template.Sent7d, &template.Active, &template.UpdatedAt); err != nil {
			return nil, err
		}
		templates = append(templates, template)
	}
	return templates, rows.Err()
}

func (s *Store) UpsertAdminReminderTemplate(ctx context.Context, params UpsertAdminReminderTemplateParams) (AdminReminderTemplate, error) {
	id := params.ID
	if id == uuid.Nil {
		var err error
		id, err = uuid.NewV7()
		if err != nil {
			return AdminReminderTemplate{}, err
		}
	}
	var template AdminReminderTemplate
	err := s.pool.QueryRow(ctx, `
		INSERT INTO reminder_templates (id, title, body, trigger, audience, active)
		VALUES ($1, $2, $3, $4, $5, $6)
		ON CONFLICT (id) DO UPDATE
		SET title = EXCLUDED.title,
		    body = EXCLUDED.body,
		    trigger = EXCLUDED.trigger,
		    audience = EXCLUDED.audience,
		    active = EXCLUDED.active,
		    updated_at = now()
		RETURNING id, title, body, trigger, audience, sent_7d, active, updated_at
	`, id, strings.TrimSpace(params.Title), strings.TrimSpace(params.Body), strings.TrimSpace(params.Trigger), strings.TrimSpace(params.Audience), params.Active).Scan(
		&template.ID, &template.Title, &template.Body, &template.Trigger, &template.Audience, &template.Sent7d, &template.Active, &template.UpdatedAt,
	)
	return template, err
}

func (s *Store) ListAdminAuditEntries(ctx context.Context) ([]AdminAuditEntry, error) {
	return []AdminAuditEntry{}, nil
}

func nullableUUID(id uuid.UUID) *uuid.UUID {
	if id == uuid.Nil {
		return nil
	}
	return &id
}

func adminRangeDays(rangeName string) int {
	switch strings.ToLower(strings.TrimSpace(rangeName)) {
	case "year":
		return 365
	case "month":
		return 30
	default:
		return 7
	}
}

func trimAdminOptional(value *string) *string {
	if value == nil {
		return nil
	}
	trimmed := strings.TrimSpace(*value)
	if trimmed == "" {
		return nil
	}
	return &trimmed
}

func initials(name, fallback string) string {
	fields := strings.Fields(name)
	if len(fields) >= 2 {
		return strings.ToUpper(string([]rune(fields[0])[0]) + string([]rune(fields[1])[0]))
	}
	if len(fields) == 1 {
		runes := []rune(fields[0])
		if len(runes) >= 2 {
			return strings.ToUpper(string(runes[:2]))
		}
		if len(runes) == 1 {
			return strings.ToUpper(string(runes[0]))
		}
	}
	if fallback != "" {
		return strings.ToUpper(string([]rune(fallback)[0]))
	}
	return "U"
}
