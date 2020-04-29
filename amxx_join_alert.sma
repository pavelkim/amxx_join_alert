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

#define REPORT_SOCKET_BUFFER_SIZE 32

enum _:player_data_struct {
	PLAYER_ID,
	PLAYER_NAME[MAX_NAME_LENGTH * 3],
	PLAYER_STEAMID[30],
	PLAYER_TEAM[1]
}

new player_data[MAX_PLAYERS + 1][player_data_struct]

new REPORT_SOCKET
new REPORT_SOCKET_BUFFER[REPORT_SOCKET_BUFFER_SIZE]
new REPORT_SOCKET_BUFFER_USED = 0

public plugin_init() {

	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_event("TeamInfo", "hook_TeamInfo", "a")
}

public plugin_cfg() {
	prepare_socket()
}

public plugin_end() {
	say_to_socket2("Bye^n", 5)
	socket_close(REPORT_SOCKET)
}

public hook_TeamInfo() {
	new PlayerID = read_data(1)
	new TeamName[2]

	read_data(2, TeamName, charsmax(TeamName))
	
	new message[64]
	format(message, charsmax(message), "TEAM^t%i^t%s^t%s^n", PlayerID, player_data[PlayerID][PLAYER_STEAMID], TeamName[0])
	say_to_socket2(message, charsmax(message))

	if (!strcmp(player_data[PlayerID][PLAYER_TEAM], "U") && strcmp(TeamName, "U")) {
		copy(player_data[PlayerID][PLAYER_TEAM], charsmax(TeamName), TeamName)
		
		new message[64]
		format(message, charsmax(message), "ENTER^t%i^t%s^t%s^n", PlayerID, player_data[PlayerID][PLAYER_STEAMID], player_data[PlayerID][PLAYER_TEAM])
		say_to_socket2(message, charsmax(message))
	
	} else if (strcmp(player_data[PlayerID][PLAYER_TEAM], "U") && !strcmp(TeamName, "U")) {
		new message[64]
		format(message, charsmax(message), "LEAVE^t%i^t%s^t%s^n", PlayerID, player_data[PlayerID][PLAYER_STEAMID], player_data[PlayerID][PLAYER_TEAM])
		say_to_socket2(message, charsmax(message))
	}
	
	return PLUGIN_CONTINUE
}

public task_check_on_socket() {
	new message[24]
	new socket_state

	if (REPORT_SOCKET > 0) {
		socket_state = 1
		format(message, charsmax(message), "DEBUG^tS%i^n", socket_state)
		say_to_socket2(message, charsmax(message))

	} else {
		socket_state = -1
	}

	return PLUGIN_CONTINUE
}

public task_open_socket() {

	new report_socket_error

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
	say_to_socket2("Hello^n", 7)

	return PLUGIN_CONTINUE
}

public task_close_socket() {
	close_socket()
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
	say_to_socket2(message, charsmax(message))

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
	say_to_socket2(message, charsmax(message))

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

	if (is_socket_alive()) {
		result = socket_send(REPORT_SOCKET, message, message_length)

		format(final_message, charsmax(final_message), "[SOCKET] Sending result: %i", result)
		say(final_message)

	} else {
		say("[SOCKET] Socket is not ready. Can't send the message.")
	}

	return PLUGIN_CONTINUE
}

public say_to_socket2(message[], message_length) {

	new result
	new final_message[128]
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

	say("[SOCKET] Successfully opened a socket.")

	result = socket_send(new_socket, message, message_length)
	format(final_message, charsmax(final_message), "[SOCKET] Sending result: %i", result)
	say(final_message)

	socket_close()

	return PLUGIN_CONTINUE
}

public is_socket_alive() {

	if (REPORT_SOCKET > 0) {

		if (socket_change(REPORT_SOCKET, 1)) {
			// TODO: Buffer out of bound
			REPORT_SOCKET_BUFFER_USED++
			new buffer_idx = REPORT_SOCKET_BUFFER_USED - 1
			socket_recv(REPORT_SOCKET, REPORT_SOCKET_BUFFER[buffer_idx], 1)
			
			if (strlen(REPORT_SOCKET_BUFFER[buffer_idx]) > 0) {
				say("[SOCKET] Got some data, put it in buffer. Carrying on now.")
				
				return true

			} else {
				say("[SOCKET] Got nothing, probably a dead connection.")

				close_socket()
				prepare_socket()

				return false
			}

		} else	{
			return true
		}

	} else {
		prepare_socket()
		return false		
	}
}

public prepare_socket() {
	
	if ( !task_exists(TASKID_OPENSOCKET) ) {
		new task_param[1]
		format(task_param, 1, "%i", TASKID_OPENSOCKET)
		set_task(0.5, "task_open_socket", TASKID_OPENSOCKET, task_param, 1, "b")
	
	} else {
		say("[SOCKET] Socket opening task already exists.")
	}
	
	return PLUGIN_CONTINUE
}

public close_socket() {
	socket_close(REPORT_SOCKET)
	return PLUGIN_CONTINUE
}
