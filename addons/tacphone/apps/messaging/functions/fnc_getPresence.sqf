#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Current effective presence of a PlayerUID as known by the server.
 *
 * Arguments:
 * 0: Player UID <STRING>
 *
 * Return Value:
 * Presence <STRING> ("available", "minimized" or "offline")
 *
 * Example:
 * ["76561198000000000"] call ace_tacphone_Messaging_fnc_getPresence
 *
 * Public: No
 */

params [["_uid", ""]];

if (_uid == "") exitWith {
    MESSAGING_PRESENCE_OFFLINE
};

GVAR(serverPlayerPresence) getOrDefault [_uid, MESSAGING_PRESENCE_OFFLINE]
