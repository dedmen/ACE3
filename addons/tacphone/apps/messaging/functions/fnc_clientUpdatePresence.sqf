#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Recomputes the visibility of one page client from the phone display mode and
 * reports changes to the server. The in-game client id "local" is driven by the
 * TacPhone display mode, external page clients report their own visibility in
 * the SetClientPresence request.
 *
 * Arguments:
 * 0: Client id <STRING> (optional; defaults to "local")
 *
 * Return Value:
 * None
 *
 * Example:
 * ["local"] call ace_tacphone_Messaging_fnc_clientUpdatePresence
 *
 * Public: No
 */

params [["_clientId", "local"]];

if (!hasInterface) exitWith {};

private _localPresence = [_clientId] call FUNC(getLocalPresence);
private _visible = _localPresence == MESSAGING_PRESENCE_AVAILABLE;
private _uid = getPlayerUID player;
private _previous = GVAR(webClients) getOrDefault [_clientId, nil];

GVAR(webClients) set [_clientId, _visible];

// Effective presence of this player across the in-game phone and every external
// page. Keep the page's own "You" indicator correct even when the player shares
// no room with anybody; Presence.Changed from the server is peer-only.
if (_uid != "") then {
    private _presence = [MESSAGING_PRESENCE_MINIMIZED, MESSAGING_PRESENCE_AVAILABLE] select (true in (values GVAR(webClients)));

    [createHashMapFromArray [
        ["a", MESSAGING_APP],
        ["c", "Presence.Changed"],
        ["uid", _uid],
        ["presence", _presence],
        ["now", time]
    ]] call FUNC(clientPushToWeb);
};

if (_previous isEqualTo _visible) exitWith {};

if (_uid == "") exitWith {};

[_uid, _clientId, createHashMapFromArray [
    ["c", "SetClientPresence"],
    ["visible", _visible]
]] call FUNC(relayToServer);
