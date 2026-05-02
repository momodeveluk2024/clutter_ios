package db

import (
	"context"
	"sort"
	"strings"
	"time"

	"github.com/google/uuid"
)

type Reminder struct {
	ID        uuid.UUID `json:"id"`
	UserID    uuid.UUID `json:"user_id"`
	Title     string    `json:"title"`
	Body      *string   `json:"body,omitempty"`
	RemindAt  time.Time `json:"remind_at"`
	Timezone  string    `json:"timezone"`
	Enabled   bool      `json:"enabled"`
	CreatedAt time.Time `json:"created_at"`
}

type CreateReminderParams struct {
	ID       uuid.UUID
	UserID   uuid.UUID
	Title    string
	Body     *string
	RemindAt time.Time
	Timezone string
	Enabled  bool
}

type Recommendation struct {
	Code         string    `json:"code"`
	Name         string    `json:"name"`
	Message      string    `json:"message"`
	Percent      *float64  `json:"percent,omitempty"`
	FoodID       uuid.UUID `json:"food_id"`
	FoodName     string    `json:"food_name"`
	FoodImageURL *string   `json:"food_image_url,omitempty"`
}

type DailyMealPlan struct {
	Date  string         `json:"date"`
	Meals []MealPlanSlot `json:"meals"`
}

type MealPlanSlot struct {
	MealType       string         `json:"meal_type"`
	Title          string         `json:"title"`
	FocusNutrients []string       `json:"focus_nutrients"`
	Items          []MealPlanItem `json:"items"`
}

type MealPlanItem struct {
	FoodID       uuid.UUID `json:"food_id"`
	FoodName     string    `json:"food_name"`
	FoodImageURL *string   `json:"food_image_url,omitempty"`
	Reason       string    `json:"reason"`
}

type recommendationProfile struct {
	DietaryPattern string
	Allergens      []string
	Goals          []string
}

type recommendationCandidate struct {
	Code          string
	Name          string
	Percent       *float64
	FoodID        uuid.UUID
	FoodName      string
	FoodImageURL  *string
	Category      string
	AmountPer100G float64
}

type scoredRecommendation struct {
	recommendation Recommendation
	score          float64
	amount         float64
}

func (s *Store) AddFavorite(ctx context.Context, userID, foodID uuid.UUID) error {
	_, err := s.pool.Exec(ctx, `
		INSERT INTO favorites (user_id, food_id)
		VALUES ($1, $2)
		ON CONFLICT (user_id, food_id) DO NOTHING
	`, userID, foodID)
	return err
}

func (s *Store) RemoveFavorite(ctx context.Context, userID, foodID uuid.UUID) error {
	_, err := s.pool.Exec(ctx, `DELETE FROM favorites WHERE user_id = $1 AND food_id = $2`, userID, foodID)
	return err
}

func (s *Store) ListFavorites(ctx context.Context, userID uuid.UUID) ([]FoodSummary, error) {
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
			), '{}')::text[] AS nutrient_codes
		FROM favorites fav
		JOIN foods f ON f.id = fav.food_id
		WHERE fav.user_id = $1 AND f.deleted_at IS NULL
		ORDER BY fav.created_at DESC
	`, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	foods := []FoodSummary{}
	for rows.Next() {
		var food FoodSummary
		if err := rows.Scan(&food.ID, &food.Name, &food.Brand, &food.Category, &food.ServingSizeG, &food.Verified, &food.ImageURL, &food.Nutrients); err != nil {
			return nil, err
		}
		foods = append(foods, food)
	}
	return foods, rows.Err()
}

func (s *Store) CreateReminder(ctx context.Context, params CreateReminderParams) (Reminder, error) {
	var reminder Reminder
	err := s.pool.QueryRow(ctx, `
		INSERT INTO reminders (id, user_id, title, body, remind_at, timezone, enabled)
		VALUES ($1, $2, $3, $4, $5, $6, $7)
		RETURNING id, user_id, title, body, remind_at, timezone, enabled, created_at
	`, params.ID, params.UserID, params.Title, params.Body, params.RemindAt, params.Timezone, params.Enabled).Scan(
		&reminder.ID,
		&reminder.UserID,
		&reminder.Title,
		&reminder.Body,
		&reminder.RemindAt,
		&reminder.Timezone,
		&reminder.Enabled,
		&reminder.CreatedAt,
	)
	return reminder, err
}

func (s *Store) ListReminders(ctx context.Context, userID uuid.UUID) ([]Reminder, error) {
	rows, err := s.pool.Query(ctx, `
		SELECT id, user_id, title, body, remind_at, timezone, enabled, created_at
		FROM reminders
		WHERE user_id = $1
		ORDER BY remind_at ASC
	`, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	reminders := []Reminder{}
	for rows.Next() {
		var reminder Reminder
		if err := rows.Scan(&reminder.ID, &reminder.UserID, &reminder.Title, &reminder.Body, &reminder.RemindAt, &reminder.Timezone, &reminder.Enabled, &reminder.CreatedAt); err != nil {
			return nil, err
		}
		reminders = append(reminders, reminder)
	}
	return reminders, rows.Err()
}

func (s *Store) DeleteReminder(ctx context.Context, userID, reminderID uuid.UUID) error {
	_, err := s.pool.Exec(ctx, `DELETE FROM reminders WHERE user_id = $1 AND id = $2`, userID, reminderID)
	return err
}

func (s *Store) GetRecommendations(ctx context.Context, userID uuid.UUID, date string) ([]Recommendation, error) {
	var profile recommendationProfile
	if err := s.pool.QueryRow(ctx, `
		SELECT COALESCE(dietary_pattern, ''), allergens, goals
		FROM user_profiles
		WHERE user_id = $1
	`, userID).Scan(&profile.DietaryPattern, &profile.Allergens, &profile.Goals); err != nil {
		return nil, err
	}

	rows, err := s.pool.Query(ctx, `
		WITH low AS (
			SELECT
				n.id AS nutrient_id,
				n.code,
				n.name,
				COALESCE((t.amount / d.amount) * 100, 0)::float8 AS percent
			FROM nutrients n
			JOIN user_profiles p ON p.user_id = $1
			LEFT JOIN LATERAL (
				SELECT amount
				FROM dri_values d
				WHERE d.nutrient_id = n.id
				  AND d.life_stage IN ('adult', CASE WHEN p.pregnancy_status = 'pregnant' THEN 'pregnancy' ELSE 'adult' END)
				  AND (d.sex = p.sex OR d.sex IS NULL)
				ORDER BY
				  CASE WHEN d.life_stage = CASE WHEN p.pregnancy_status = 'pregnant' THEN 'pregnancy' ELSE 'adult' END THEN 0 ELSE 1 END,
				  CASE WHEN d.sex = p.sex THEN 0 ELSE 1 END
				LIMIT 1
			) d ON true
			LEFT JOIN daily_nutrient_totals t ON t.nutrient_id = n.id AND t.user_id = $1 AND t.logged_on = $2::date
			WHERE d.amount IS NOT NULL
			  AND COALESCE((t.amount / d.amount) * 100, 0) < 80
			ORDER BY COALESCE((t.amount / d.amount) * 100, 0) ASC
			LIMIT 8
		)
		SELECT
			low.code,
			low.name,
			low.percent,
			f.id,
			f.name,
			f.image_url,
			f.category,
			fn.amount_per_100g::float8
		FROM low
		JOIN food_nutrients fn ON fn.nutrient_id = low.nutrient_id
		JOIN foods f ON f.id = fn.food_id AND f.deleted_at IS NULL
		ORDER BY low.code, fn.amount_per_100g DESC
	`, userID, date)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	candidates := []recommendationCandidate{}
	for rows.Next() {
		var candidate recommendationCandidate
		var percent float64
		if err := rows.Scan(&candidate.Code, &candidate.Name, &percent, &candidate.FoodID, &candidate.FoodName, &candidate.FoodImageURL, &candidate.Category, &candidate.AmountPer100G); err != nil {
			return nil, err
		}
		candidate.Percent = &percent
		candidates = append(candidates, candidate)
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}
	return buildRecommendations(profile, candidates, 5), nil
}

func (s *Store) GetDailyMealPlan(ctx context.Context, userID uuid.UUID, date string) (DailyMealPlan, error) {
	recommendations, err := s.GetRecommendations(ctx, userID, date)
	if err != nil {
		return DailyMealPlan{}, err
	}
	return buildDailyMealPlan(date, recommendations), nil
}

func buildDailyMealPlan(date string, recommendations []Recommendation) DailyMealPlan {
	slots := []MealPlanSlot{
		{MealType: "breakfast", Title: "Breakfast"},
		{MealType: "lunch", Title: "Lunch"},
		{MealType: "snack", Title: "Snack"},
		{MealType: "dinner", Title: "Dinner"},
	}
	for i := range slots {
		if i >= len(recommendations) {
			slots[i].Items = []MealPlanItem{}
			slots[i].FocusNutrients = []string{}
			continue
		}
		rec := recommendations[i]
		slots[i].FocusNutrients = []string{rec.Code}
		slots[i].Items = []MealPlanItem{{
			FoodID:       rec.FoodID,
			FoodName:     rec.FoodName,
			FoodImageURL: rec.FoodImageURL,
			Reason:       mealPlanReason(rec),
		}}
	}
	return DailyMealPlan{Date: date, Meals: slots}
}

func mealPlanReason(rec Recommendation) string {
	name := strings.TrimSpace(rec.Name)
	food := strings.TrimSpace(rec.FoodName)
	if name == "" && food == "" {
		return rec.Message
	}
	if name == "" {
		return "A practical food to add today."
	}
	if food == "" {
		return "Helps cover " + name + "."
	}
	return "Helps cover " + name + " with " + food + "."
}

func buildRecommendations(profile recommendationProfile, candidates []recommendationCandidate, limit int) []Recommendation {
	if limit <= 0 {
		return []Recommendation{}
	}
	bestByCode := map[string]recommendationCandidate{}
	for _, candidate := range candidates {
		if !foodAllowedForProfile(profile, candidate.Category, candidate.FoodName) {
			continue
		}
		current, ok := bestByCode[candidate.Code]
		if !ok || candidate.AmountPer100G > current.AmountPer100G {
			bestByCode[candidate.Code] = candidate
		}
	}

	scored := make([]scoredRecommendation, 0, len(bestByCode))
	for _, candidate := range bestByCode {
		recommendation := Recommendation{
			Code:         candidate.Code,
			Name:         candidate.Name,
			Percent:      candidate.Percent,
			FoodID:       candidate.FoodID,
			FoodName:     candidate.FoodName,
			FoodImageURL: candidate.FoodImageURL,
		}
		recommendation.Message = "You are below target for " + recommendation.Name + ". Try adding " + recommendation.FoodName + "."
		scored = append(scored, scoredRecommendation{
			recommendation: recommendation,
			score:          recommendationScore(profile.Goals, candidate.Code, candidate.Percent),
			amount:         candidate.AmountPer100G,
		})
	}

	sort.SliceStable(scored, func(i, j int) bool {
		if scored[i].score != scored[j].score {
			return scored[i].score > scored[j].score
		}
		leftPercent := percentValue(scored[i].recommendation.Percent)
		rightPercent := percentValue(scored[j].recommendation.Percent)
		if leftPercent != rightPercent {
			return leftPercent < rightPercent
		}
		if scored[i].amount != scored[j].amount {
			return scored[i].amount > scored[j].amount
		}
		return scored[i].recommendation.Name < scored[j].recommendation.Name
	})

	if len(scored) > limit {
		scored = scored[:limit]
	}
	recommendations := make([]Recommendation, 0, len(scored))
	for _, item := range scored {
		recommendations = append(recommendations, item.recommendation)
	}
	return recommendations
}

func recommendationScore(goals []string, code string, percent *float64) float64 {
	return 100 - percentValue(percent) + goalBoost(goals, code)
}

func percentValue(percent *float64) float64 {
	if percent == nil {
		return 100
	}
	return *percent
}

func goalBoost(goals []string, code string) float64 {
	boosts := map[string]map[string]float64{
		"energy":           {"B12": 30, "B9": 20, "Mg": 15, "Fe": 15, "Protein": 10},
		"immunity":         {"C": 30, "D": 20, "Zn": 20, "A": 12},
		"bone health":      {"Ca": 35, "D": 35, "K": 12, "Mg": 10},
		"heart health":     {"Mg": 25, "K": 15, "B9": 15},
		"focus":            {"B12": 25, "Mg": 20, "Fe": 10},
		"fitness":          {"Protein": 30, "Mg": 20, "Fe": 10},
		"iron support":     {"Fe": 40, "B9": 12, "B12": 12},
		"better digestion": {"B9": 18, "Mg": 12},
		"skin & hair":      {"A": 20, "C": 20, "Protein": 12, "Zn": 12},
		"sleep":            {"Mg": 30, "D": 10},
	}
	total := 0.0
	for _, goal := range goals {
		goalBoosts := boosts[strings.ToLower(strings.TrimSpace(goal))]
		total += goalBoosts[code]
	}
	return total
}

func foodAllowedForProfile(profile recommendationProfile, category, foodName string) bool {
	category = strings.ToLower(strings.TrimSpace(category))
	name := strings.ToLower(foodName)
	diet := strings.ToLower(strings.TrimSpace(profile.DietaryPattern))

	switch diet {
	case "vegan":
		if categoryIn(category, "meat", "poultry", "seafood", "dairy", "eggs") {
			return false
		}
	case "vegetarian":
		if categoryIn(category, "meat", "poultry", "seafood") {
			return false
		}
	case "pescatarian":
		if categoryIn(category, "meat", "poultry") {
			return false
		}
	}

	for _, allergen := range profile.Allergens {
		switch strings.ToLower(strings.TrimSpace(allergen)) {
		case "dairy":
			if category == "dairy" {
				return false
			}
		case "eggs":
			if category == "eggs" || strings.Contains(name, "egg") {
				return false
			}
		case "soy":
			if category == "soy" || strings.Contains(name, "soy") || strings.Contains(name, "tofu") || strings.Contains(name, "tempeh") {
				return false
			}
		case "peanuts", "tree nuts":
			if category == "nuts" || strings.Contains(name, "peanut") || strings.Contains(name, "almond") || strings.Contains(name, "nut") {
				return false
			}
		case "wheat / gluten":
			if category == "grains" || strings.Contains(name, "wheat") || strings.Contains(name, "gluten") {
				return false
			}
		case "shellfish", "fish":
			if category == "seafood" {
				return false
			}
		case "sesame":
			if strings.Contains(name, "sesame") {
				return false
			}
		}
	}

	return true
}

func categoryIn(category string, values ...string) bool {
	for _, value := range values {
		if category == value {
			return true
		}
	}
	return false
}
