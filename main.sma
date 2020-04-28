#include <amxmodx>

new PLUGIN[]="AMXX Join Alert"
new AUTHOR[]="uh9had"
new VERSION[]="1.0.0"

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_event("TeamInfo", "hook_TeamInfo", "a")
}

public hook_TeamInfo(PlayerID, TeamName) {
	new message[64]
	format(message, 64, "TeamName Event: PlayerID: %s TeamName: %s", PlayerID, TeamName)
	log_message(message)
	
	return PLUGIN_CONTINUE
}