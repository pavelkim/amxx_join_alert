AMX Mod X Join Alert plugin
===========================

Sends out notifications over a TCP Socket on the following events:
- Player connected to the server
- Player joined the game
- Player left the game

Requirements
============

To successfully use the plugin you need the following components:
1. HLDS Server 
1. cstrike game
1. AMX Mod X 1.8.2
1. TCP Socket listener

Setup
=====

1. Compile the plugin
1. Copy compiled plugin into your `cstrike/cstrike/addons/amxmodx/plugins` directory
1. Start TCP Socket server on tcp4:127.0.0.1:28000
1. Restart HLDS Server

Protocol
========

Package scheme: `EVENT`\t`DATASET`\n
Dataset scheme: `FIELD1`\t`FIELD2`\t`FIELD4`\t`FIELDn`\t

|  Event  | Fields |     1    |    2    |      3     |      4     |
|:-------:|:------:|:--------:|:-------:|:----------:|:----------:|
| CONNECT | 3      | PlayerID | SteamID | PlayerName | N/A        |
| ENTER   | 4      | PlayerID | SteamID | PlayerTeam | PlayerName |
| LEAVE   | 4      | PlayerID | SteamID | PlayerTeam | PlayerName |

Workflow
========

Overall process:

1. HLDS Server is running
1. AMX Mod X is enabled
1. AMX Mod X has Join Alert plugin enabled
1. Cstrike game goes on
1. A player connects to the server
1. Plugin triggers CONNECT event
1. A player picks a team to join and joins it
1. Plugin triggers ENTER event
1. A player gets tired and leaves the game
1. Plugin triggers LEAVE event

Event triggering process:

1. Something happens
1. HLDS/cstrike triggers an event
1. AMX Mod X receives that event
1. AMX Mod X triggers corresponging event for plugins
1. Plugin handles event with a function

Package sending process:

1. Nothing is happening, no sockets are open
1. An event happens
1. Plugin handler function being executed
1. Hahdler function triggers `say_to_socket2()` function
1. `say_to_socket2()` function makes an attempt to open a TCP socket
1. `say_to_socket2()` function verifies if the socket was successfully opened
1. If fails opening a socket, error is written to HLDS console and `bool:false` returned
1. If no errors appeared, a message is being sent over the opened socket and then the socket is being closed 


Examples
========

Package examples
----------------

Here goes a number of explained event and package contents examples.

1. Player MrBean connected to the server:
`CONNECT	9	STEAM_0:2:90009000	MrBean`
1. Player MrBean chose to play as a CT:
`ENTER	9	STEAM_0:2:90009000	C	MrBean`
1. Player MrBean finally left the game:
`LEAVE	9	STEAM_0:2:90009000	C	MrBean`

Using netcat to receive data from the plugin
--------------------------------------------

```bash
[hlds@cs16server ~]$ nc -tl4 127.0.0.1 28000
CONNECT	9	STEAM_0:2:90009000	MrBean
ENTER	9	STEAM_0:2:90009000	C	MrBean
LEAVE	9	STEAM_0:2:90009000	C	MrBean
```
