/*

	Sends player connection/joining information over a TCP connection

	TODO:
	- Sending to socket as tasks that should loop until the socket is ready
	- TTL and Queue Size for sending task queue
	- Move configuration to CVARs
	- Call reconnect on sending result < 0
	- Review log messages, check for grammar

*/
#include <amxmodx>
#include <sockets>

#define PLUGIN "Join Alert"
#define AUTHOR "Pavel Kim"
#define VERSION "0.0.0"

#define MAX_PLAYERS 32
#define MAX_NAME_LENGTH 32

#define PLUGIN_HOST "127.0.0.1"
#define PLUGIN_PORT 28000

#define SOCK_NON_BLOCKING 1


enum _:player_data_struct {
	PLAYER_ID,
	PLAYER_NAME[MAX_NAME_LENGTH * 3],
	PLAYER_STEAMID[30],
	PLAYER_TEAM[1]
}

new player_data[MAX_PLAYERS + 1][player_data_struct]

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_event("TeamInfo", "hook_TeamInfo", "a")
	register_logevent("hook_RoundStart", 2, "1=Round_Start")
	register_logevent("hook_RoundEnd", 2, "1=Round_End")

}

public hook_RoundEnd() {

	new message[92]

	format(message, charsmax(message), "Round_Start: happened")
	say(message)

}

public hook_RoundStart() {

	new message[92]

	format(message, charsmax(message), "Round_End: happened")
	say(message)

}

public hook_TeamInfo() {
	new PlayerID = read_data(1)
	new TeamName[2]

	read_data(2, TeamName, charsmax(TeamName))
	
	new message[92]

	format(message, charsmax(message), "TeamInfo: PlayerID:'%i' TeamName:'%s' PLAYER_TEAM:'%s' SteamID:'%s' Name:'%s'", PlayerID, TeamName[0], player_data[PlayerID][PLAYER_TEAM], player_data[PlayerID][PLAYER_STEAMID], player_data[PlayerID][PLAYER_NAME])
	say(message)

	format(message, charsmax(message), "TEAM^t%i^t%s^t%s^n", PlayerID, player_data[PlayerID][PLAYER_STEAMID], TeamName[0])
	say_to_socket(message, charsmax(message))
	
	if (strcmp(player_data[PlayerID][PLAYER_TEAM], "")) {	
		if (!strcmp(player_data[PlayerID][PLAYER_TEAM], "U") && strcmp(TeamName, "U")) {
			copy(player_data[PlayerID][PLAYER_TEAM], charsmax(TeamName), TeamName)
			
			new message[64]
			format(message, charsmax(message), "ENTER^t%i^t%s^t%s^t%s^n", PlayerID, player_data[PlayerID][PLAYER_STEAMID], player_data[PlayerID][PLAYER_TEAM], player_data[PlayerID][PLAYER_NAME])
			say_to_socket(message, charsmax(message))
		
		} else if (strcmp(player_data[PlayerID][PLAYER_TEAM], "U") && !strcmp(TeamName, "U")) {
			new message[64]
			format(message, charsmax(message), "LEAVE^t%i^t%s^t%s^t%s^n", PlayerID, player_data[PlayerID][PLAYER_STEAMID], player_data[PlayerID][PLAYER_TEAM], player_data[PlayerID][PLAYER_NAME])
			say_to_socket(message, charsmax(message))
			arrayset(player_data[PlayerID], 0, player_data_struct)
		}
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
	format(message, charsmax(message), "DISCONNECT^t%i^t%s^t%s^n", id, player_data[id][PLAYER_STEAMID], player_data[id][PLAYER_NAME])
	say_to_socket(message, charsmax(message))

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
	format(message, charsmax(message), "[CONNECT] PlayerID: %i SteamID: %s Name: %s", id, player_data[id][PLAYER_STEAMID], player_data[id][PLAYER_NAME])
	say(message)

	format(message, charsmax(message), "CONNECT^t%i^t%s^t%s^n", id, player_data[id][PLAYER_STEAMID], player_data[id][PLAYER_NAME])
	say_to_socket(message, charsmax(message))

	return true
}


public say(message[]) {
	new final_message[128]
	format(final_message, charsmax(final_message), "[JOIN ALERT] %s", message)
	log_message(final_message)
}


public say_to_socket(message[], message_length) {

	new new_socket
	new new_socket_error

	new_socket = socket_open(PLUGIN_HOST, PLUGIN_PORT, 1, new_socket_error)

	switch (new_socket_error) {
		case 1: {
			say("[SOCKET] Unable to create socket.")
			return false
		}
		case 2: {
			say("[SOCKET] Unable to connect.")
			return false
		}
		case 3: {
			say("[SOCKET] Unable to connect to the port.")
			return false
		}
	}

	socket_send(new_socket, message, message_length)
	socket_close(new_socket)

	return PLUGIN_CONTINUE
}
