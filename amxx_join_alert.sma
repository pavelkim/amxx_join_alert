#include <amxmodx>
#include <sockets>

#define PLUGIN "Join Alert"
#define AUTHOR "Pavel Kim"
#define VERSION "1.1.0"

#define MAX_PLAYERS 32
#define MAX_NAME_LENGTH 32

#define PLUGIN_HOST "127.0.0.1"
#define PLUGIN_PORT 28000

#define TASKID_GETANSWER 0
#define TASKID_CLOSESOCKET 1


enum _:player_data_struct {
	PLAYER_ID,
	PLAYER_NAME[MAX_NAME_LENGTH * 3],
	PLAYER_STEAMID[30],
	PLAYER_TEAM[1]
}

new player_data[MAX_PLAYERS + 1][player_data_struct]
new REPORT_SOCKET

public plugin_init() {

	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_event("TeamInfo", "hook_TeamInfo", "a")

    set_task(1.0, "task_check_on_socket", TASKID_GETANSWER, "", 0, "b") 
    set_task(20.0, "task_close_socket", TASKID_CLOSESOCKET, "", 0, "a", 1) 

}

public plugin_cfg() {
	new report_socket_error
	REPORT_SOCKET = socket_open(PLUGIN_HOST, PLUGIN_PORT, 1, report_socket_error)

	switch (report_socket_error) {
		case 1: {
			say("[JOIN ALERT] Unable to create socket.")
			return
		}
		case 2: {
			say("[JOIN ALERT] Unable to connect.")
			return
		}
		case 3: {
			say("[JOIN ALERT] Unable to connect to the port.")
			return
		}
	}

	socket_send(REPORT_SOCKET, "Hello^n", 7)
}

public plugin_end() {
	socket_send(REPORT_SOCKET, "Bye^n", 5)
	socket_close(REPORT_SOCKET)
}

public hook_TeamInfo() {
	new PlayerID = read_data(1)
	new TeamName[2]

	read_data(2, TeamName, charsmax(TeamName))
	
	new message[64]
	format(message, charsmax(message), "[EVENT] TeamInfo: PlayerID: %i TeamName: %s", PlayerID, TeamName[0])
	say(message)

	if (!strcmp(player_data[PlayerID][PLAYER_TEAM], "U") && strcmp(TeamName, "U")) {

		copy(player_data[PlayerID][PLAYER_TEAM], charsmax(TeamName), TeamName)
		
		new message[64]
		format(message, charsmax(message), "[ENTER] PlayerID: %i SteamID: %s TeamName: %s", PlayerID, player_data[PlayerID][PLAYER_STEAMID], player_data[PlayerID][PLAYER_TEAM])
		say(message)


		format(message, charsmax(message), "ENTER^t%i^t%s^t%s^n", PlayerID, player_data[PlayerID][PLAYER_STEAMID], player_data[PlayerID][PLAYER_TEAM])
		socket_send(REPORT_SOCKET, message, charsmax(message))
	
	} else if (strcmp(player_data[PlayerID][PLAYER_TEAM], "U") && !strcmp(TeamName, "U")) {

		new message[64]
		format(message, charsmax(message), "[LEAVE] PlayerID: %i SteamID: %s LastTeamName: %s", PlayerID, player_data[PlayerID][PLAYER_STEAMID], player_data[PlayerID][PLAYER_TEAM])
		say(message)

		format(message, charsmax(message), "LEAVE^t%i^t%s^t%s^n", PlayerID, player_data[PlayerID][PLAYER_STEAMID], player_data[PlayerID][PLAYER_TEAM])
		socket_send(REPORT_SOCKET, message, charsmax(message))
	}
	
	return PLUGIN_CONTINUE
}

public task_check_on_socket() {
	new message[24]
	format(message, charsmax(message), "[SOCKET] State: %i", REPORT_SOCKET)
	say(message)

	format(message, charsmax(message), "DEBUG^tS%i^n", REPORT_SOCKET)
	socket_send(REPORT_SOCKET, message, charsmax(message))

	return PLUGIN_CONTINUE
}

public task_close_socket() {

	socket_send(REPORT_SOCKET, "CLOSINGSOCKET^n", 14)
	socket_close(REPORT_SOCKET)

	say("[SOCKET] Task just have closed the socket.")

	return PLUGIN_CONTINUE
}

public OnAutoConfigsBuffered() {
	new players[MAX_PLAYERS]
	new players_number

	get_players(players, players_number, "h")
}

public client_disconnected(id, drop, message, maxlen) {
	new message[64]
	format(message, charsmax(message), "Client Disconnected Event: PlayerID: %i ", id)
	say(message)

	return true
}

public client_connect(id) {
	new message[64]
	format(message, charsmax(message), "Client Connected Event: PlayerID: %i ", id)
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
	format(message, charsmax(message), "[CONNECT] PlayerID: %i SteamID: %s Name: %s", id, player_data[id][PLAYER_STEAMID], player_data[id][PLAYER_NAME])
	say(message)

	format(message, charsmax(message), "CONNECT^t%i^t%s^t%s^n", id, player_data[id][PLAYER_STEAMID], player_data[id][PLAYER_NAME])
	socket_send(REPORT_SOCKET, message, charsmax(message))

	return true
}

public say(message[]) {
	new final_message[128]
	format(final_message, charsmax(final_message), "[JOIN ALERT] %s", message)
	log_message(final_message)
}
