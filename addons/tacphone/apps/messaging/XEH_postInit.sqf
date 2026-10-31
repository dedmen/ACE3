#include "script_component.hpp"

// Server: requests relayed by a page client.
[QGVAR(clientRequest), {
    params ["_uid", "_clientId", "_requestJson"];

    if (!isServer) exitWith {};

    private _request = fromJSON _requestJson;

    if (!(_request isEqualType createHashMap)) exitWith {};

    [_request, _clientId, [_uid] call FUNC(getPlayerByUid)] call FUNC(serverHandleRequest);
}] call CBA_fnc_addEventHandler;

// Client: pushes from the server to the page clients of this player.
[QGVAR(serverPush), {
    params ["_pushJson"];

    private _push = fromJSON _pushJson;

    if (!(_push isEqualType createHashMap)) exitWith {};

    [_push] call FUNC(clientHandlePush);
}] call CBA_fnc_addEventHandler;

if (isServer) then {
    // A player left the mission: drop every page client and report them offline.
    addMissionEventHandler ["HandleDisconnect", {
        params ["_unit"];

        [_unit] call FUNC(serverPlayerDisconnected);
    }];
};

// A WebSocket page client went away. This runs on whichever machine hosts the
// WebSocket extension: the server removes the client directly, a client relays
// the removal to the server.
[QEGVAR(tacphone,clientDisconnected), {
    params ["_clientId"];

    [_clientId] call FUNC(clientRemoveClient);
}] call CBA_fnc_addEventHandler;

if (hasInterface) then {
    // The local phone client follows the TacPhone display mode.
    [QEGVAR(tacphone,displayModeChanged), {
        ["local"] call FUNC(clientUpdatePresence);
    }] call CBA_fnc_addEventHandler;

    // Register the in-game phone once the player and the root display mode exist.
    [{
        ["local"] call FUNC(clientUpdatePresence);
    }, [], 1] call CBA_fnc_waitAndExecute;
};
