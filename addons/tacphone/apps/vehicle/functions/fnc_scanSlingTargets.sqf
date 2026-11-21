#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Shared sling candidate scan used by the Hook action (fnc_doSlingLoad) and
 * the scope payload (fnc_buildSlingPayload), so both agree on what the hook
 * can pick: every object within the radius (3D distance, SLING_SCAN_RADIUS)
 * that is alive, not an animal and not carried by another helicopter,
 * nearest first. There is NO vertical listing filter: everything in the
 * radius is shown (a target that is not yet reachable is drawn
 * de-emphasized, not hidden).
 *
 * canLoad is the hook's real verdict, not just the game's: the helicopter
 * must canSlingLoad the object AND the pilot hook must reach it - within
 * SLING_ATTACH_2D (horizontal) of the helicopter, and the cargo top at most
 * SLING_ATTACH_HEIGHT below the helicopter's BELLY (its bounding-box bottom,
 * the same reference the scope's clearance readout uses,
 * fnc_buildSlingPayload), with a SLING_ATTACH_ABOVE tolerance above it (a
 * vehicle parked under a grounded helicopter). The reach changes with the
 * flight, so it is re-checked every tick; only the game verdict is cached.
 *
 * Arguments:
 * 0: Helicopter <OBJECT>
 * 1: Radius <NUMBER>
 *
 * Return Value:
 * ARRAY of [Object <OBJECT>, canLoad <BOOL>] pairs, nearest first (horizontal
 * distance), NOT capped
 *
 * Example:
 * [vehicle player, SLING_SCAN_RADIUS] call ace_tacphone_vehicle_fnc_scanSlingTargets
 *
 * Public: No
 */

params ["_heli", "_radius"];

// Transform the eight corners of the model-space bounding box into world
// space and report [minX,minY,minZ,maxX,maxY,maxZ]: an axis-aligned model
// box reaches its world X/Y/Z extrema at its corners, so the corner sweep is
// exact even for a tilted object.
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

// The gate below measures against the helicopter's BELLY (its bounding-box
// bottom), the same reference the scope's clearance readout uses
// (fnc_buildSlingPayload): the hook hangs from the helicopter bottom, and
// the scope and the hook must agree on what is reachable.
private _heliBottom = ([_heli, boundingBoxReal _heli] call _worldBox) select 2;

// canSlingLoad verdicts cached per target netId; the verdicts only apply to
// the helicopter that filled them, so the cache is rebuilt when the heli
// changes (the interest transitions clear it for hygiene).
if (isNil QGVAR(slingCache)) then {
    GVAR(slingCache) = createHashMap;
    GVAR(slingCacheHeli) = "";
};
if (netId _heli isNotEqualTo GVAR(slingCacheHeli)) then {
    GVAR(slingCache) = createHashMap;
    GVAR(slingCacheHeli) = netId _heli;
};
private _cache = GVAR(slingCache);

private _ranked = [];

// AllVehicles covers cars/boats/other helis; ThingX covers crates and other
// props. The per-tick alive check keeps a stale canLoad verdict harmless.
{
    private _obj = _x;
    if (_obj isEqualTo _heli) then { continueWith {}; };
    if (!alive _obj) then { continueWith {}; };
    // Animals (snakes, livestock, ...) are engine "vehicles" (they appear in
    // AllVehicles) but are never sling cargo; the scope must not list them.
    if (_obj isKindOf "Land_Creatures") then { continueWith {}; };

    private _ext = [_obj, boundingBoxReal _obj] call _worldBox;
    // Already carried by another helicopter. Cargo WE carry is a valid scope
    // target: fnc_buildSlingPayload flags it attached.
    if !((isNull (getSlingLoad _obj)) || {(getSlingLoad _obj) isEqualTo _heli}) then { continueWith {}; };

    private _dist2D = _obj distance2D _heli;
    private _key = netId _obj;
    private _canLoad = false;
    if (_key in _cache) then {
        _canLoad = _cache get _key;
    } else {
        _canLoad = _heli canSlingLoad _obj;
        _cache set [_key, _canLoad];
    };
    // The game verdict is half the hook's reach: the pilot hook also has to
    // physically reach the cargo - SLING_ATTACH_2D away at most
    // horizontally, and the cargo top at most SLING_ATTACH_HEIGHT below
    // the helicopter's belly, or up to SLING_ATTACH_ABOVE above it (a
    // vehicle parked under a grounded helicopter; the engine's own
    // canSlingLoad accepts it). Re-checked every tick: the distance
    // changes while the helicopter flies.
    if (_canLoad) then {
        private _drop = _heliBottom - (_ext select 5);
        _canLoad = _dist2D <= SLING_ATTACH_2D && {_drop >= -SLING_ATTACH_ABOVE && {_drop <= SLING_ATTACH_HEIGHT}};
    };

    _ranked pushBack [_dist2D, _forEachIndex, _obj, _canLoad];
} forEach (nearestObjects [_heli, ["AllVehicles", "ThingX"], _radius]);

// nearestObjects orders by 3D distance, so a high object would outrank a
// closer one below; re-sort by horizontal distance (the index breaks ties so
// the sort never compares objects)
_ranked sort true;

_ranked apply { [_x select 2, _x select 3] };
