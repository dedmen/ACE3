#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Builds the top-down sling scope payload for a helicopter: its heading plus
 * the sling candidates below it (fnc_scanSlingTargets), nearest first, capped
 * at SLING_MAX_TARGETS, each with its world-frame relative position, body-frame
 * footprint (local X/Y extents) and own heading, and clearance. The scope
 * rotates the footprint to the target's heading, so the drawn box matches the
 * object's real orientation. The name is the class displayName, or a readable
 * name derived from the config name when the class has none (never the netId
 * or the raw class name). Full precision, no rounding.
 *
 * Arguments:
 * 0: Vehicle (heli) <OBJECT>
 *
 * Return Value:
 * HASHMAP of the Vehicle.Sling fields (without a/c)
 *
 * Example:
 * [vehicle player] call ace_tacphone_vehicle_fnc_buildSlingPayload
 *
 * Public: No
 */

params ["_vehicle"];

// Same world-space corner sweep as fnc_scanSlingTargets:
// [minX,minY,minZ,maxX,maxY,maxZ] of the eight boundingBoxReal corners
// transformed with modelToWorld.
private _worldBox = {
    params ["_obj", "_box"];
    private _a = _box param [0];
    private _b = _box param [1];
    private _ext = [1e10, 1e10, 1e10, -1e10, -1e10, -1e10];
    {
        private _w = _obj modelToWorld _x;
        _ext set [0, (_ext select 0) min (_w select 0)];
        _ext set [1, (_ext select 1) min (_w select 1)];
        _ext set [2, (_ext select 2) min (_w select 2)];
        // The world corner holds X/Y/Z at 0/1/2; the running max/min slots
        // in _ext are 3/4/5
        _ext set [3, (_ext select 3) max (_w select 0)];
        _ext set [4, (_ext select 4) max (_w select 1)];
        _ext set [5, (_ext select 5) max (_w select 2)];
    } forEach [
        [_a select 0, _a select 1, _a select 2], [_a select 0, _a select 1, _b select 2],
        [_a select 0, _b select 1, _a select 2], [_a select 0, _b select 1, _b select 2],
        [_b select 0, _a select 1, _a select 2], [_b select 0, _a select 1, _b select 2],
        [_b select 0, _b select 1, _a select 2], [_b select 0, _b select 1, _b select 2]
    ];
    _ext
};

private _heliExt = [_vehicle, boundingBoxReal _vehicle] call _worldBox;
private _heliBottom = _heliExt select 2;
private _heliX = ((_heliExt select 0) + (_heliExt select 3)) / 2;
private _heliY = ((_heliExt select 1) + (_heliExt select 4)) / 2;

private _slingLoad = getSlingLoad _vehicle;

// The scan is nearest first and uncapped; the scope shows at most
// SLING_MAX_TARGETS
private _pairs = [_vehicle, SLING_SCAN_RADIUS] call FUNC(scanSlingTargets);
_pairs = _pairs select [0, SLING_MAX_TARGETS min (count _pairs)];

private _targets = [];
{
    private _obj = _x select 0;
    private _box = boundingBoxReal _obj;
    private _ext = [_obj, _box] call _worldBox;
    private _cx = ((_ext select 0) + (_ext select 3)) / 2;
    private _cy = ((_ext select 1) + (_ext select 4)) / 2;
    // Body-frame footprint: the world sweep above loses the object's
    // rotation, so the scope pairs the local X/Y extents with the target's
    // heading to draw the rotated footprint.
    private _a = _box param [0];
    private _b = _box param [1];

    private _cfg = configOf _obj;
    private _name = getText (_cfg >> "displayName");
    if (_name == "") then {
        // No displayName in the class: derive a readable name from the
        // config name ("B_Quadbike_01_F" -> "Quadbike 01") instead of
        // showing the raw class name. Drop a one-letter faction prefix and
        // the trailing _F variant marker.
        private _tokens = (configName _cfg) splitString "_";
        if ((count _tokens) > 1 && (count (_tokens select 0)) == 1) then {
            _tokens = _tokens select [1, (count _tokens) - 1];
        };
        if ((count _tokens) > 0 && (_tokens select ((count _tokens) - 1)) == "F") then {
            _tokens = _tokens select [0, (count _tokens) - 1];
        };
        _name = _tokens joinString " ";
        if (_name == "") then {
            _name = configName _cfg;
        };
    };

    _targets pushBack (createHashMapFromArray [
        ["netId", netId _obj],
        ["name", _name],
        ["relX", _cx - _heliX],
        ["relY", _cy - _heliY],
        ["width", (_b select 1) - (_a select 1)],
        ["length", (_b select 0) - (_a select 0)],
        ["heading", getDir _obj],
        ["clearance", _heliBottom - (_ext select 5)],
        ["attached", _slingLoad isEqualTo _obj],
        ["canLoad", _x select 1]
    ]);
} forEach _pairs;

createHashMapFromArray [
    ["heading", getDir _vehicle],
    ["targets", _targets],
    ["t", CBA_missionTime]
]
