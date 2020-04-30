package main

import (
	"fmt"
	"log"
	"strings"
)

/*
	Example:
	CONNECT	4	STEAM_0:0:76269181	uh9had
*/

func CommandHandlerFunction(payload string) (*string, error) {
	payload_parts := strings.Split(payload, "\t")

	if len(payload_parts) != 4 {
		return nil, fmt.Errorf("Broken payload, expected 4 pieces.")
	}

	player_id := payload_parts[1]
	steam_id := payload_parts[2]
	player_name := payload_parts[3]

	log.Print("CONNECT: ", player_id, steam_id, player_name)
	fmt.Printf("CONNECT: SteamID: '%s', Name: '%s' (%s)\n", steam_id, player_name, player_id)

	response := "OK"

	return &response, nil
}
