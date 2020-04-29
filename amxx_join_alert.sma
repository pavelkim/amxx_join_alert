/*

	Sends player connection/joining information over a TCP connection

	TODO:
	- Sending to socket as tasks that should loop until the socket is ready
	- TTL and Queue Size for sending task queue
	- Move configuration to CVARs
	- Call reconnect on sending result < 0
	- Better handle socket changing
	- Fix how task id is being passed to task_open_socket
	- Review log messages, check for grammar

*/
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
#define TASKID_OPENSOCKET 2
#define TASKID_READSOCKET 2

#define SOCK_NON_BLOCKING 1

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

	// set_task(1.0, "task_check_on_socket", TASKID_GETANSWER, "", 0, "b") 
	// set_task(20.0, "task_close_socket", TASKID_CLOSESOCKET, "", 0, "a", 1) 

}

public plugin_cfg() {
	prepare_socket()
}

public plugin_end() {
	say_to_socket("Bye^n", 5)
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
		say_to_socket(message, charsmax(message))
	
	} else if (strcmp(player_data[PlayerID][PLAYER_TEAM], "U") && !strcmp(TeamName, "U")) {
		new message[64]
		format(message, charsmax(message), "[LEAVE] PlayerID: %i SteamID: %s LastTeamName: %s", PlayerID, player_data[PlayerID][PLAYER_STEAMID], player_data[PlayerID][PLAYER_TEAM])
		say(message)

		format(message, charsmax(message), "LEAVE^t%i^t%s^t%s^n", PlayerID, player_data[PlayerID][PLAYER_STEAMID], player_data[PlayerID][PLAYER_TEAM])
		say_to_socket(message, charsmax(message))
	}
	
	return PLUGIN_CONTINUE
}

public task_check_on_socket() {
	new message[24]
	new socket_state

	if (REPORT_SOCKET > 0) {
		socket_state = 1
		format(message, charsmax(message), "[SOCKET] State: %i", socket_state)
		say(message)

		format(message, charsmax(message), "DEBUG^tS%i^n", socket_state)
		say_to_socket(message, charsmax(message))

	} else {
		socket_state = -1
	}


	return PLUGIN_CONTINUE
}

public task_read_from_socket() {
	
	new socket_data[1500]
	new socket_state

	say("[SOCKET] Reading from socket..")

	if (REPORT_SOCKET > 0) {
		say("[SOCKET] Socket is ready")
		socket_recv(REPORT_SOCKET, socket_data, 1500)

		if (strlen(socket_data) > 0) {
			new message[1550]
			say("[SOCKET] Got some data")

			format(message, charsmax(message), "[SOCKET] Recieved: '%s'", socket_data)
			say(message)

		} else {
			say("[SOCKET] Got nothing, probably a dead connection.")
			close_socket()
			prepare_socket()
		}

	} else {
		say("[SOCKET] Socket is not ready, calling prepare_socket function")
		prepare_socket()
	}

	return PLUGIN_CONTINUE
}

public task_open_socket() {

	new report_socket_error
	new self_task_id = read_data(1)

	say("[SOCKET] Removing socket opening task.")
	remove_task(TASKID_OPENSOCKET)

	say("[SOCKET] Trying to open a socket")

	REPORT_SOCKET = socket_open(PLUGIN_HOST, PLUGIN_PORT, 1, report_socket_error)

	switch (report_socket_error) {
		case 1: {
			say("[SOCKET] Unable to create socket.")
			prepare_socket()
			return false
		}
		case 2: {
			say("[SOCKET] Unable to connect.")
			prepare_socket()
			return false
		}
		case 3: {
			say("[SOCKET] Unable to connect to the port.")
			prepare_socket()
			return false
		}
	}

	say("[SOCKET] Successfully opened a socket.")
	say_to_socket("Hello^n", 7)


	return PLUGIN_CONTINUE
}

public task_close_socket() {

	say_to_socket("CLOSINGSOCKET^n", 14)
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
	say_to_socket(message, charsmax(message))

	return true
}

public say(message[]) {
	new final_message[128]
	format(final_message, charsmax(final_message), "[JOIN ALERT] %s", message)
	log_message(final_message)
}

public say_to_socket(message[], message_length) {

	new result
	new final_message[128]

	if (REPORT_SOCKET > 0) {
		say("[SOCKET] Socket is ready")
		say("[SOCKET] Waiting for socket to change..")

		if (socket_change(REPORT_SOCKET, 1000)) {
			say("[SOCKET] Socket changed")
			// set_task(0.1, "task_read_from_socket", TASKID_READSOCKET, "", 0, "a", 1) 
			task_read_from_socket()
			// return PLUGIN_CONTINUE

		} else {
			say("[SOCKET] Socket hasn't changed")
		}

		format(final_message, charsmax(final_message), "[SOCKET] Sending: '%s' Lentgth: %i", message, message_length)
		say(final_message)
		
		result = socket_send(REPORT_SOCKET, message, message_length)

		format(final_message, charsmax(final_message), "[SOCKET] Sending result: %i", result)
		say(final_message)

		if (result < 0) {
			say("[SOCKET] Result was negative, calling prepare_socket function.")
			prepare_socket()
		}

	} else {
		say("[SOCKET] Socket is not ready, calling prepare_socket function.")
		prepare_socket()
	}

	return PLUGIN_CONTINUE
}

public prepare_socket() {
	
	if ( !task_exists(TASKID_OPENSOCKET) ) {
		new task_param[1]
		format(task_param, 1, "%i", TASKID_OPENSOCKET)
		set_task(1.0, "task_open_socket", TASKID_OPENSOCKET, task_param, 1, "b")
	
	} else {
		say("[SOCKET] Socket opening task already exists.")
	}
	
	return PLUGIN_CONTINUE
}

public close_socket() {
	socket_close(REPORT_SOCKET)
	return PLUGIN_CONTINUE
}
