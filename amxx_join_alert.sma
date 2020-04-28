#include <amxmodx>

new PLUGIN[]="AMXX Join Alert"
new AUTHOR[]="uh9had"
new VERSION[]="1.0.0"

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR)
	// register_event("TeamInfo", "hook_TeamInfo", "a")
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
	new message[64]
	format(message, 64, "Client Entering Game Event: PlayerID: %s ", id)
	log_message(message)

	return true
}
