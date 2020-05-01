package main

import (
	"fmt"
	"log"
	"strings"
	"structs"
)

/*
	Example:
	ENTER	3	STEAM_0:0:76269181	C
*/

var PluginConfiguration structs.CommandPluginConfigurationStruct

func CommandHandlerFunction(payload string) (string, error) {
	payload_parts := strings.Split(strings.TrimRight(payload, "\n"), "\t")

	if len(payload_parts) != 4 {
		return "", fmt.Errorf("Broken payload, expected 4 pieces.")
	}

	player_id := payload_parts[1]
	steam_id := payload_parts[2]
	player_team := payload_parts[3]

	log.Print("ENTER: ", player_id, steam_id, player_team)
	fmt.Printf("ENTER: SteamID: '%s', Team: '%s' (%s)\n", steam_id, player_team, player_id)

	go PluginConfiguration.Messenger.(func(string) (bool, error))(fmt.Sprintf("ENTER: SteamID: '%s', Team: '%s' (%s)\n", steam_id, player_team, player_id))

	response := "OK"

	return response, nil
}
