package main

import (
	"database/sql"
	"errors"
	"fmt"
	"log"
	"os"

	"github.com/momodeveluk2024/nutrivita-flutter/backend/internal/config"
	"github.com/pressly/goose/v3"

	_ "github.com/jackc/pgx/v5/stdlib"
)

func main() {
	cfg, err := config.Load()
	if err != nil {
		log.Fatal(err)
	}

	command := "up"
	if len(os.Args) > 1 {
		command = os.Args[1]
	}

	database, err := sql.Open("pgx", cfg.DatabaseURL)
	if err != nil {
		log.Fatal(err)
	}
	defer database.Close()

	if err := goose.SetDialect("postgres"); err != nil {
		log.Fatal(err)
	}
	if err := goose.Run(command, database, "migrations", os.Args[2:]...); err != nil {
		if errors.Is(err, goose.ErrNoNextVersion) || errors.Is(err, goose.ErrNoCurrentVersion) || errors.Is(err, goose.ErrNotApplied) {
			fmt.Println(err)
			return
		}
		log.Fatal(err)
	}
}
