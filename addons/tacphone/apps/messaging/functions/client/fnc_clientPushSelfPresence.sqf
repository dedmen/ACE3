#include "..\..\script_component.hpp"
/*
 * Author: Dedmen
 * Pushes this player's effective self presence to the local pages.
 *
 * The "You" indicator is the player's effective presence across the in-game
 * phone and every external page: available when any client is visible,
 * minimized when clients exist but none are visible. The server only
 * broadcasts presence to peers, so the local pages keep their own copy in
 * sync here.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call ace_tacphone_Messaging_fnc_clientPushSelfPresence
 *
 * Public: No
 */

private _uid = getPlayerUID player;

if (_uid == "") exitWith {};

private _presence = [MESSAGING_PRESENCE_MINIMIZED, MESSAGING_PRESENCE_AVAILABLE] select (true in (values GVAR(webClients)));

[createHashMapFromArray [
    ["a", MESSAGING_APP],
    ["c", "Presence.Changed"],
    ["uid", _uid],
    ["presence", _presence],
    ["now", time]
]] call FUNC(clientPushToWeb);
