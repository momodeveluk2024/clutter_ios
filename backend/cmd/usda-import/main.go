package main

import (
	"context"
	"encoding/csv"
	"flag"
	"fmt"
	"log"
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

type csvRow struct {
	Barcode       string
	Name          string
	Brand         string
	Category      string
	ServingSizeG  float64
	NutrientCode  string
	AmountPer100G float64
}

func main() {
	csvPath := flag.String("csv", "", "path to a small USDA-style CSV fixture")
	databaseURL := flag.String("database-url", os.Getenv("DATABASE_URL"), "Postgres connection string")
	flag.Parse()

	if *csvPath == "" {
		log.Fatal("-csv is required")
	}
	if *databaseURL == "" {
		log.Fatal("DATABASE_URL or -database-url is required")
	}

	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, *databaseURL)
	if err != nil {
		log.Fatalf("connect database: %v", err)
	}
	defer pool.Close()

	rows, err := readRows(*csvPath)
	if err != nil {
		log.Fatalf("read csv: %v", err)
	}

	foodIDs := map[string]uuid.UUID{}
	imported, skipped, err := importRows(ctx, pool, rows, foodIDs)
	if err != nil {
		log.Fatalf("import csv: %v", err)
	}
	log.Printf("usda import complete: foods=%d nutrients=%d skipped_unknown_nutrients=%d", len(foodIDs), imported, skipped)
}

func readRows(path string) ([]csvRow, error) {
	file, err := os.Open(path)
	if err != nil {
		return nil, err
	}
	defer file.Close()

	reader := csv.NewReader(file)
	reader.TrimLeadingSpace = true
	records, err := reader.ReadAll()
	if err != nil {
		return nil, err
	}
	if len(records) < 2 {
		return nil, fmt.Errorf("csv must include a header and at least one row")
	}

	header := map[string]int{}
	for i, column := range records[0] {
		header[strings.ToLower(strings.TrimSpace(column))] = i
	}

	rows := make([]csvRow, 0, len(records)-1)
	for _, record := range records[1:] {
		servingSizeG, err := strconv.ParseFloat(required(record, header, "serving_size_g"), 64)
		if err != nil {
			return nil, fmt.Errorf("invalid serving_size_g: %w", err)
		}
		amountPer100G, err := strconv.ParseFloat(required(record, header, "amount_per_100g"), 64)
		if err != nil {
			return nil, fmt.Errorf("invalid amount_per_100g: %w", err)
		}
		rows = append(rows, csvRow{
			Barcode:       optional(record, header, "barcode"),
			Name:          required(record, header, "name"),
			Brand:         optional(record, header, "brand"),
			Category:      required(record, header, "category"),
			ServingSizeG:  servingSizeG,
			NutrientCode:  required(record, header, "nutrient_code"),
			AmountPer100G: amountPer100G,
		})
	}
	return rows, nil
}

func importRows(ctx context.Context, pool *pgxpool.Pool, rows []csvRow, foodIDs map[string]uuid.UUID) (int, int, error) {
	imported := 0
	skipped := 0
	for _, row := range rows {
		key := row.Barcode
		if key == "" {
			key = strings.ToLower(row.Name + "|" + row.Brand)
		}

		foodID, ok := foodIDs[key]
		if !ok {
			var err error
			foodID, err = upsertFood(ctx, pool, row)
			if err != nil {
				return imported, skipped, err
			}
			foodIDs[key] = foodID
		}

		tag, err := pool.Exec(ctx, `
			INSERT INTO food_nutrients (food_id, nutrient_id, amount_per_100g)
			SELECT $1, id, $3
			FROM nutrients
			WHERE code = $2
			ON CONFLICT (food_id, nutrient_id)
			DO UPDATE SET amount_per_100g = EXCLUDED.amount_per_100g
		`, foodID, row.NutrientCode, row.AmountPer100G)
		if err != nil {
			return imported, skipped, err
		}
		if tag.RowsAffected() == 0 {
			skipped++
			continue
		}
		imported++
	}
	return imported, skipped, nil
}

func upsertFood(ctx context.Context, pool *pgxpool.Pool, row csvRow) (uuid.UUID, error) {
	foodID, err := uuid.NewV7()
	if err != nil {
		return uuid.Nil, err
	}
	if row.Barcode == "" {
		_, err := pool.Exec(ctx, `
			INSERT INTO foods (id, name, brand, category, serving_size_g, source, verified)
			VALUES ($1, $2, NULLIF($3, ''), $4, $5, 'usda_csv', false)
		`, foodID, row.Name, row.Brand, row.Category, row.ServingSizeG)
		return foodID, err
	}

	err = pool.QueryRow(ctx, `
		INSERT INTO foods (id, name, brand, category, serving_size_g, source, verified, barcode)
		VALUES ($1, $2, NULLIF($3, ''), $4, $5, 'usda_csv', false, $6)
		ON CONFLICT (barcode) DO UPDATE
		SET name = EXCLUDED.name,
		    brand = EXCLUDED.brand,
		    category = EXCLUDED.category,
		    serving_size_g = EXCLUDED.serving_size_g,
		    updated_at = now()
		RETURNING id
	`, foodID, row.Name, row.Brand, row.Category, row.ServingSizeG, row.Barcode).Scan(&foodID)
	if err != nil && err != pgx.ErrNoRows {
		return uuid.Nil, err
	}
	return foodID, nil
}

func required(record []string, header map[string]int, name string) string {
	value := optional(record, header, name)
	if value == "" {
		log.Fatalf("missing required csv column/value: %s", name)
	}
	return value
}

func optional(record []string, header map[string]int, name string) string {
	index, ok := header[name]
	if !ok || index >= len(record) {
		return ""
	}
	return strings.TrimSpace(record[index])
}
