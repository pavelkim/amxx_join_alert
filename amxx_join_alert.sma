#include <amxmodx>
#include <sockets>

#define PLUGIN "Join Alert"
#define AUTHOR "Pavel Kim"
#define VERSION "1.1.0"

#define MAX_PLAYERS 32
#define MAX_NAME_LENGTH 32

#define PLUGIN_HOST "127.0.0.1"
#define PLUGIN_PORT 28000

enum _:player_data_struct {
	PLAYER_ID,
	PLAYER_NAME[MAX_NAME_LENGTH * 3],
	PLAYER_STEAMID[30],
	PLAYER_TEAM[1]
}

new player_data[MAX_PLAYERS + 1][player_data_struct]

new REPORT_SOCKET_ERROR
new REPORT_SOCKET = socket_open(PLUGIN_HOST, PLUGIN_PORT, SOCKET_UDP, REPORT_SOCKET_ERROR)

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR)

	switch (REPORT_SOCKET_ERROR) {
		case 1: {
			log_amx("[JOIN ALERT] Unable to create socket.")
			return
		}
		case 2: {
			log_amx("[JOIN ALERT] Unable to connect.")
			return
		}
		case 3: {
			log_amx("[JOIN ALERT] Unable to connect to the port.")
			return
		}
	}

	register_event("TeamInfo", "hook_TeamInfo", "a")

	socket_send(REPORT_SOCKET, "Hello", 5)
}

public hook_TeamInfo() {
	new PlayerID = read_data(1)
	new TeamName[2]

	read_data(2, TeamName, charsmax(TeamName))
	
	new message[64]
	format(message, 64, "[EVENT] TeamInfo: PlayerID: %i TeamName: %s", PlayerID, TeamName[0])
	say(message)

	if (!strcmp(player_data[PlayerID][PLAYER_TEAM], "U") && strcmp(TeamName, "U")) {

		copy(player_data[PlayerID][PLAYER_TEAM], charsmax(TeamName), TeamName)
		
		new message[64]
		format(message, 64, "[ENTER] PlayerID: %i SteamID: %s TeamName: %s", PlayerID, player_data[PlayerID][PLAYER_STEAMID], player_data[PlayerID][PLAYER_TEAM])
		say(message)
	
	} else if (strcmp(player_data[PlayerID][PLAYER_TEAM], "U") && !strcmp(TeamName, "U")) {

		new message[64]
		format(message, 64, "[LEAVE] PlayerID: %i SteamID: %s LastTeamName: %s", PlayerID, player_data[PlayerID][PLAYER_STEAMID], player_data[PlayerID][PLAYER_TEAM])
		say(message)

	}
	
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
	get_user_name(id, player_data[id][PLAYER_NAME], MAX_NAME_LENGTH)
	copy(player_data[id][PLAYER_TEAM], 1, "U")

	if (!strcmp(player_data[id][PLAYER_STEAMID], "BOT")) {
		return true
	}

	new message[80]
	format(message, 80, "[CONNECT] PlayerID: %i SteamID: %s Name: %s", id, player_data[id][PLAYER_STEAMID], player_data[id][PLAYER_NAME])
	say(message)

	return true
}

public say(message[]) {
	new final_message[128]
	format(final_message, charsmax(final_message), "[JOIN ALERT] %s", message)
	log_message(final_message)
}
