package structs

import (
	"plugin"
)

type MessengerPluginConfigurationStruct struct {
	Token  string `json:"token"`
	ChatID int    `json:"chat_id"`
}

type CommandPluginConfigurationStruct struct {
	Messenger plugin.Symbol
}
