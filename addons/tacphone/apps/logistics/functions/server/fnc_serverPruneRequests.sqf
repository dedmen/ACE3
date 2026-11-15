#include "..\..\script_component.hpp"
/*
 * Author: Dedmen
 * Bounds the closed history of the queue. LOGISTICS_QUEUE_CAP limits open
 * requests only, so done/cancelled records would otherwise accumulate for
 * the whole mission: this keeps the newest LOGISTICS_CLOSED_HISTORY_CAP
 * closed records (ordered by their numeric id, the only server-trusted
 * sequence) and deletes every older one, pushing each deletion as
 * Logistics.Request.Remove so open pages drop the row. A reconnecting page
 * gets a fresh snapshot anyway.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call ace_tacphone_Logistics_fnc_serverPruneRequests
 *
 * Public: No
 */

// Keep the newest LOGISTICS_CLOSED_HISTORY_CAP closed requests.
private _closed = [];

{
    private _state = _x getOrDefault ["state", ""];
    if (_state == LOGISTICS_STATE_DONE || {_state == LOGISTICS_STATE_CANCELLED}) then {
        private _id = _x getOrDefault ["id", ""];
        _closed pushBack [parseNumber (_id select [2]), _id];   // "L-12" -> 12
    };
} forEach (values GVAR(serverRequests));

if (count _closed <= LOGISTICS_CLOSED_HISTORY_CAP) exitWith {};

_closed sort false;   // descending numeric id = newest first; the number
                      // (not the "L-2"/"L-10" string) decides the order

for "_i" from LOGISTICS_CLOSED_HISTORY_CAP to (count _closed - 1) do {
    private _id = (_closed select _i) select 1;
    GVAR(serverRequests) deleteAt _id;

    private _push = createHashMapFromArray [
        ["a", LOGISTICS_APP],
        ["c", "Logistics.Request.Remove"],
        ["id", _id]
    ];
    [_push] call FUNC(serverPushAll);
};
