#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Per-frame instrument update, running at ANIM_UPDATE_INTERVAL while a client
 * holds INTEREST_ANIM. Pushes the 5 Hz Vehicle.Anim payload to the phones.
 *
 * Arguments:
 * 0: PFH arguments <ARRAY> (unused)
 * 1: PFH handle <NUMBER> (unused)
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call ace_tacphone_vehicle_fnc_pushAnim
 *
 * Public: No
 */

params ["_args", "_handle"];

// Cheap early-out before any data assembly, nobody is interested
if (([INTEREST_ANIM] call EFUNC(tacphone,getInterestClients)) isEqualTo []) exitWith {};
if (isNull player) exitWith {};

private _vehicle = vehicle player;
if (isNull _vehicle) exitWith {};
if (_vehicle isEqualTo player) exitWith {};

// Crew changes only on board/dismount, and the anim payload no longer
// carries it (O1): every occupant, driver and passengers alike, polls the
// crew list here at 0.5 Hz and pushes on signature change. Deliberately
// 0.5 Hz, not 5 Hz, to avoid re-creating O1 for every passenger.
private _now = CBA_missionTime;
if (isNil QGVAR(nextCrewPoll) || {_now >= GVAR(nextCrewPoll)}) then {
    GVAR(nextCrewPoll) = _now + 0.5;

    private _crew = [_vehicle] call FUNC(buildCrew);
    private _signature = _crew apply {
        format ["%1|%2|%3", _x get "name", _x get "role", _x get "cargoIndex"]
    };

    if (isNil QGVAR(crewSignature) || {GVAR(crewSignature) isNotEqualTo _signature}) then {
        GVAR(crewSignature) = _signature;

        private _crewUpdate = createHashMapFromArray [
            ["a", "ACE_TacPhone_Vehicle"],
            ["c", "Vehicle.Crew"],
            ["crew", _crew]
        ];
        [_crewUpdate] call EFUNC(tacphone,sendCommandToPhone);
    };
};

// The anim payload itself is driver-only; passengers stop here.
if (driver _vehicle isNotEqualTo player) exitWith {};

private _update = [_vehicle] call FUNC(buildAnimPayload);
_update set ["a", "ACE_TacPhone_Vehicle"];
_update set ["c", "Vehicle.Anim"];

[_update] call EFUNC(tacphone,sendCommandToPhone);
