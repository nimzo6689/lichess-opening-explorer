package internal

import (
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"time"
)

type Opening struct {
	Eco  string `json:"eco"`
	Name string `json:"name"`
}

type Move struct {
	UCI   string `json:"uci"`
	SAN   string `json:"san"`
	White int    `json:"white"`
	Draws int    `json:"draws"`
	Black int    `json:"black"`
}

type ChessData struct {
	Opening Opening `json:"opening"`
	White   int     `json:"white"`
	Draws   int     `json:"draws"`
	Black   int     `json:"black"`
	Moves   []Move  `json:"moves"`
}

func CallLichessAPI(speeds string, ratings string, uci string) (*ChessData, error) {

	url := "https://explorer.lichess.ovh/lichess?" +
		"variant=standard&" +
		"speeds=" + speeds + "&" +
		"ratings=" + ratings + "&" +
		"play=" + uci

	maxRetries := 5
	for retries := 0; retries <= maxRetries; retries++ {

		client := &http.Client{}
		req, err := http.NewRequest("GET", url, nil)
		if err != nil {
			return nil, fmt.Errorf("failed to generate request: %v", err)
		}

		res, err := client.Do(req)
		if err != nil {
			if res != nil && res.StatusCode == 429 {
				fmt.Println("429 Too Many Requests")
				time.Sleep(1 * time.Minute)
				continue
			}
			return nil, fmt.Errorf("failed to communicate with API: %v", err)
		}

		// Because even when a 429 error occurs, 'err' remains nil.
		if res.StatusCode == 429 {
			fmt.Println("429 Too Many Requests")
			time.Sleep(1 * time.Minute)
			continue
		}

		defer res.Body.Close()
		body, err := io.ReadAll(res.Body)
		if err != nil {
			return nil, fmt.Errorf("failed to read body: %v", err)
		}

		return parseChessData(body)
	}
	return nil, fmt.Errorf(
		"exceeded the maximum number of API call attempts.")
}

func parseChessData(data []byte) (*ChessData, error) {

	var chessData ChessData
	if err := json.Unmarshal(data, &chessData); err != nil {
		log.Printf("Body: %s", string(data))
		return nil, err
	}
	return &chessData, nil
}
