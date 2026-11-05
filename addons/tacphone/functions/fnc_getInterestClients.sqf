#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Returns the clients that currently hold a named information interest.
 * An empty array means nobody is interested, so callers can early-out before
 * assembling any data. Game pushes are broadcast by the in-game web UI hub, so
 * the returned ids are only used for this check, never as send targets.
 *
 * Arguments:
 * 0: Interest name <STRING> (default: "" -> empty array)
 *
 * Return Value:
 * Client ids <ARRAY of STRING>
 *
 * Example:
 * if ((["ACE_TacPhone_Map.markers"] call ace_tacphone_fnc_getInterestClients) isEqualTo []) exitWith {};
 * [createHashMapFromArray [["a", "ACE_TacPhone_Map"], ["c", "Marker.Upsert"]]] call ace_tacphone_fnc_sendCommandToPhone;
 *
 * Public: No
 */

params [["_interest", ""]];

if (isNil QGVAR(AppDataInterests)) exitWith { [] };
if (_interest == "") exitWith { [] };

// Hot-ish path (called per game event), keep it to one lookup plus one keys array
private _entry = GVAR(AppDataInterests) get _interest;

if (isNil "_entry") exitWith { [] };

private _clients = _entry get "clients";
if (isNil "_clients") exitWith { [] };

keys _clients
