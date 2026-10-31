#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Writes the exported state to missionProfileNamespace under a versioned key.
 *
 * Persistence is disabled: nothing calls this automatically, it only runs when a
 * debug command invokes it. See FUNC(serverExportState) for the open TODOs.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Saved <BOOL>
 *
 * Example:
 * [] call ace_tacphone_Messaging_fnc_serverSaveState
 *
 * Public: No
 */

private _state = [] call FUNC(serverExportState);
private _json = toJSON _state;

missionProfileNamespace setVariable [MESSAGING_PERSISTENCE_KEY, _json];
saveMissionProfileNamespace;

true
