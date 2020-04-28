#include <amxmodx>

new PLUGIN[] = "AMXX Join Alert"
new AUTHOR[] = "uh9had"
new VERSION[] = "1.0.0"

enum _:player_data_struct {
	PLAYER_ID,
	PLAYER_NAME[MAX_NAME_LENGTH * 3],
	PLAYER_STEAMID[30]
}

new player_data[MAX_PLAYERS + 1][player_data_struct]

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR)
	// register_event("TeamInfo", "hook_TeamInfo", "a")
}

public OnAutoConfigsBuffered() {
	new players[]
	new players_number

	get_players(players[MAX_PLAYERS], players_number, "h")
}

public client_disconnected(id, drop, message, maxlen) {
	new message[64]
	format(message, 64, "Client Disconnected Event: PlayerID: %s ", id)
	log_message(message)

	return true
}

public client_connect(id) {
	new message[64]
	format(message, 64, "Client Connected Event: PlayerID: %s ", id)
	log_message(message)

	return true
}

public client_putinserver(id) {

	arrayset(player_data[id], 0, player_data_struct)
	get_user_authid(id, player_data[id][PLAYER_STEAMID], charsmax(player_data[][PLAYER_STEAMID]))

	new message[64]
	format(message, 64, "Client Entering Game Event: PlayerID: %i SteamID: %s", id, player_data[id][PLAYER_STEAMID])
	log_message(message)

	return true
}
