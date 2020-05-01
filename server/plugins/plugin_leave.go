package main

import (
	"fmt"
	"log"
	"strings"
	"structs"
)

/*
	Example:
	LEAVE	3	STEAM_0:0:76269181	C
*/

var PluginConfiguration structs.CommandPluginConfigurationStruct

func CommandHandlerFunction(payload string) (string, error) {
	payload_parts := strings.Split(strings.TrimRight(payload, "\n"), "\t")

	if len(payload_parts) != 5 {
		return "", fmt.Errorf("Broken payload, expected 5 pieces.")
	}

	player_id := payload_parts[1]
	steam_id := payload_parts[2]
	player_team := payload_parts[3]
	player_name := payload_parts[4]

	log.Printf("LEAVE: id:%s steamid:%s team:%s name:%s", player_id, steam_id, player_team, player_name)
	fmt.Printf("LEAVE: id:%s steamid:%s team:%s name:%s", player_id, steam_id, player_team, player_name)

	response := "OK"

	return response, nil
}
