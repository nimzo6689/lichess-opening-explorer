package internal

import (
	"database/sql"
	"fmt"
	"time"

	_ "github.com/mattn/go-sqlite3"
)

func RegisterStatistics(speeds string, ratings string, chessData *ChessData) error {
	db, err := sql.Open("sqlite3", "lichess.db")
	if err != nil {
		return fmt.Errorf("failed to connect DB: %v", err)
	}
	defer db.Close()

	sql := `
	INSERT INTO statistics (white_wins, black_wins, draws, ratings, speeds)
	VALUES (?, ?, ?, ?, ?);`
	_, err = db.Exec(sql, chessData.White, chessData.Black, chessData.Draws, ratings, speeds)
	if err != nil {
		return fmt.Errorf("failed to insert: %v", err)
	}
	return nil
}

func RegisterBoard(speeds string, ratings string, moves string, openingId *int64, chessData *ChessData) (int64, error) {
	db, err := sql.Open("sqlite3", "lichess.db")
	if err != nil {
		return -1, fmt.Errorf("failed to connect DB: %v", err)
	}
	defer db.Close()

	maxRetries := 5
	for retries := 0; retries <= maxRetries; retries++ {

		sql := `
	      INSERT INTO openings (moves, white_wins, black_wins, draws, ratings, speeds, previous_opening_id)
	      VALUES (?, ?, ?, ?, ?, ?, ?);`
		result, err := db.Exec(sql, moves, chessData.White, chessData.Black, chessData.Draws, ratings, speeds, openingId)
		if err != nil {
			fmt.Printf("failed to insert: %v", err)
			time.Sleep(10 * time.Second)
			continue
		}

		return result.LastInsertId()
	}

	return -1, fmt.Errorf(
		"exceeded the maximum number of DB operation attempts.")
}
