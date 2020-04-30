package main

import (
	"fmt"
	"log"
	"strings"
)

/*
	Example:
	LEAVE	3	STEAM_0:0:76269181	C
*/

func CommandHandlerFunction(payload string) (*string, error) {
	payload_parts := strings.Split(payload, "\t")

	if len(payload_parts) != 4 {
		return nil, fmt.Errorf("Broken payload, expected 4 pieces.")
	}

	player_id := payload_parts[1]
	steam_id := payload_parts[2]
	player_team := payload_parts[3]

	log.Print("LEAVE: ", player_id, steam_id, player_team)
	fmt.Printf("LEAVE: SteamID: '%s', Team: '%s' (%s)\n", steam_id, player_team, player_id)

	response := "OK"

	return &response, nil
}
