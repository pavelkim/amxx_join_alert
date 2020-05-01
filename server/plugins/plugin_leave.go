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

	log.Printf("LEAVE: name:%s steamid:%s id:%s team:%s \n", player_name, steam_id, player_id, player_team)
	fmt.Printf("LEAVE: name:%s steamid:%s id:%s team:%s \n", player_name, steam_id, player_id, player_team)

	response := "OK"

	return response, nil
}
