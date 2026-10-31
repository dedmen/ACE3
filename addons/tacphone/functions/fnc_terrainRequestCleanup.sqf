#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Drops pending terrain transfer contexts from GVAR(pendingTerrainRequest).
 *
 * A context is registered by "RequestTerrainSVG" and removed again by the final/error
 * "ReplyRequestTerrainSVG" chunk. This cleans up transfers that were abandoned (for
 * example the page closed mid-transfer) or whose requesting browser disconnected.
 *
 * Only hashmap entries are inspected: the texture proxy stores promises in the same
 * map and those must not be touched here.
 *
 * Arguments:
 * 0: Client id to drop <STRING> (default: "" - no client based removal)
 * 1: Maximum age in seconds <NUMBER> (default: -1 - no age based removal)
 *
 * Return Value:
 * None
 *
 * Example:
 * ["", 60] call ace_tacphone_fnc_terrainRequestCleanup
 * [_clientId, -1] call ace_tacphone_fnc_terrainRequestCleanup
 *
 * Public: No
 */
params [["_clientId", ""], ["_maxAge", -1]];

private _pending = GVAR(pendingTerrainRequest);
private _now = diag_tickTime;

{
    private _context = _pending get _x;

    if (_context isEqualType createHashMap) then {
        private _expired = (_maxAge >= 0) && {(_now - (_context getOrDefault ["created", _now])) > _maxAge};
        private _matchesClient = (_clientId != "") && {(_context getOrDefault ["clientId", ""]) == _clientId};

        if (_expired || {_matchesClient}) then {
            _pending deleteAt _x;
        };
    };
} forEach (keys _pending);
