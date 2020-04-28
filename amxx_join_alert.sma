#include <amxmodx>

new PLUGIN[] = "AMXX Join Alert"
new AUTHOR[] = "Pavel Kim"
new VERSION[] = "1.0.0"

#define MAX_PLAYERS 32
#define MAX_NAME_LENGTH 32

enum _:player_data_struct {
	PLAYER_ID,
	PLAYER_NAME[MAX_NAME_LENGTH * 3],
	PLAYER_STEAMID[30]
}

new player_data[MAX_PLAYERS + 1][player_data_struct]

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_event("TeamInfo", "hook_TeamInfo", "a")
}

public hook_TeamInfo() {
	new PlayerID = read_data(1)
	new TeamName[2]

	read_data(2, TeamName, charsmax(TeamName))
	
	new message[64]
	format(message, 64, "TeamName Event: PlayerID: %i TeamName: %s", PlayerID, TeamName[0])
	say(message)
	
	return PLUGIN_CONTINUE
}

public OnAutoConfigsBuffered() {
	new players[MAX_PLAYERS]
	new players_number

	get_players(players, players_number, "h")
}

public client_disconnected(id, drop, message, maxlen) {
	new message[64]
	format(message, 64, "Client Disconnected Event: PlayerID: %i ", id)
	say(message)

	return true
}

public client_connect(id) {
	new message[64]
	format(message, 64, "Client Connected Event: PlayerID: %i ", id)
	say(message)

	return true
}

public client_putinserver(id) {

	arrayset(player_data[id], 0, player_data_struct)
	get_user_authid(id, player_data[id][PLAYER_STEAMID], charsmax(player_data[][PLAYER_STEAMID]))

	new message[80]
	format(message, 80, "Client Entering Game Event: PlayerID: %i SteamID: %s", id, player_data[id][PLAYER_STEAMID])
	say(message)

	return true
}

public say(message) {

	new final_message_size = charsmax(message) + 20
	new final_message[final_message_size]
	format(final_message, final_message_size, "= [JOIN ALERT] = %s", message)
	log_message(final_message)
}