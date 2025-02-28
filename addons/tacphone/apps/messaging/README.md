ace_tacphone_messaging
============

Chat message app.
Can send chat messages in player-to-player chats or group chats with multiple players as participants.


UI is implemented with HTML+Javascript
To debug/develop UI, enable "OpenDevConsole" in fnc_createApp.sqf, and run game with -debug parameter.

Server stores all messages from all players and all their chats to be able to transmit them back on JIP, it uses the players SteamID to assign chats to players.




