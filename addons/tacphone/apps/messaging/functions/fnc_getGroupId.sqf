#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Stable id of a group. The group name is only unique per side, so the side is
 * part of the id. The web UI sends this id back for group selection.
 *
 * Arguments:
 * 0: Group <GROUP>
 *
 * Return Value:
 * Group id <STRING> ("WEST:Alpha 1-1")
 *
 * Example:
 * [group player] call ace_tacphone_Messaging_fnc_getGroupId
 *
 * Public: No
 */

params ["_group"];

format ["%1:%2", str (side _group), groupId _group]
