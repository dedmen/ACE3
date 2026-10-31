#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Generates a server-side id.
 *
 * "msg:" uses the monotonic message counter ("msg:12"). "grp:" uses the room
 * counter plus a random suffix ("grp:3_482913"). Every other prefix gets a
 * random suffix only.
 *
 * Arguments:
 * 0: Prefix <STRING> (for example "grp:" or "msg:")
 *
 * Return Value:
 * Id <STRING>
 *
 * Example:
 * ["grp:"] call ace_tacphone_Messaging_fnc_generateId
 *
 * Public: No
 */

params ["_prefix"];

switch (_prefix) do {
    case "msg:": {
        GVAR(serverMessageCounter) = GVAR(serverMessageCounter) + 1;
        format ["msg:%1", GVAR(serverMessageCounter)]
    };
    case "grp:": {
        GVAR(serverRoomCounter) = GVAR(serverRoomCounter) + 1;
        format ["grp:%1_%2", GVAR(serverRoomCounter), round (random 999999)]
    };
    default {
        format ["%1%2", _prefix, round (random 1000000000)]
    };
}
