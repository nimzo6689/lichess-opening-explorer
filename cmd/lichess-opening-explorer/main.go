package main

import (
	"log"
	"time"

	"github.com/nimzo6689/lichess-trap-explorer/internal"
)

func main() {
	const speeds = "blitz"
	const ratings = "1200"
	uci := ""

	chessData, err := internal.CallLichessAPI(speeds, ratings, uci)
	if err != nil {
		log.Fatal(err)
	}
	err = internal.RegisterEvents(speeds, ratings, chessData)
	if err != nil {
		log.Fatal(err)
	}

	traverseMoves(speeds, ratings, uci, 1, nil, chessData)
}

func traverseMoves(speeds string, ratings string, uci string, frequency float64, openingId *int64, chessData *internal.ChessData) {

	gameCount := chessData.White + chessData.Black + chessData.Draws
	for _, move := range chessData.Moves {
		currentFrequency := float64(move.White+move.Black+move.Draws) / float64(gameCount) * frequency

		if currentFrequency < 0.0001 {
			break
		}

		currentUCI := uci
		if currentUCI == "" {
			currentUCI += move.UCI
		} else {
			currentUCI += "," + move.UCI
		}

		time.Sleep(500 * time.Millisecond)
		chessData, err := internal.CallLichessAPI(speeds, ratings, currentUCI)
		if err != nil {
			log.Fatal(err)
		}
		openingId, err := internal.RegisterBoard(speeds, ratings, move.SAN, openingId, chessData)
		if err != nil {
			log.Fatal(err)
		}

		traverseMoves(speeds, ratings, currentUCI, currentFrequency, &openingId, chessData)
	}
}
