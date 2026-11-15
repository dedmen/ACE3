#include "script_component.hpp"

// Server: requests relayed by a page client.
[QGVAR(clientRequest), {
    params ["_uid", "_clientId", "_requestJson"];

    if (!isServer) exitWith {};

    private _request = fromJSON _requestJson;

    if (!(_request isEqualType createHashMap)) exitWith {};

    [_request, _clientId, [_uid] call FUNC(getPlayerByUid)] call FUNC(serverHandleRequest);
}] call CBA_fnc_addEventHandler;

// Client: pushes from the server to this player's in-game page. The server
// sends one QGVAR(serverPush) target event per player (fnc_serverPushAll);
// this handler delivers the push to the local page, which the web UI hub
// then broadcasts to every web client. Without this client leg, pushes never
// left the server machine on a dedicated server.
[QGVAR(serverPush), {
    params ["_pushJson"];

    private _push = fromJSON _pushJson;

    if (!(_push isEqualType createHashMap)) exitWith {};

    [_push] call FUNC(clientHandlePush);
}] call CBA_fnc_addEventHandler;

// Interest bookkeeping for this app is done by the web host (the pages hold and release the interest); no SQF-side CBA handlers are needed.

if (isServer) then {
    // A player left the mission: drop their role (their requests stay).
    addMissionEventHandler ["HandleDisconnect", {
        params ["_unit"];

        [_unit] call FUNC(serverPlayerDisconnected);
    }];
};
