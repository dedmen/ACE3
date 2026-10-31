#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Builds the roster payload: players, current human group members, sides,
 * presence and the enemy-chat setting.
 *
 * Players on other sides are only listed when the global enemy-chat setting is
 * enabled (or the debug override is set). Groups are always limited to the
 * requesting player's side, even when enemy chat is enabled. Only human members
 * are reported. Debug fake players, groups and their presence are included when
 * the addon was built with __A3_DEBUG__.
 *
 * Arguments:
 * 0: Requesting player <OBJECT> (optional; used for side filtering)
 *
 * Return Value:
 * Player list <HASHMAP> ({players, groups, allowEnemyChat})
 *
 * Example:
 * [player] call ace_tacphone_Messaging_fnc_getPlayerList
 *
 * Public: No
 */

params [["_requester", objNull]];

private _allowEnemyChat = missionNamespace getVariable [QEGVAR(tacphone,messagingAllowEnemyChat), false];

#ifdef __A3_DEBUG__
if (!isNil QGVAR(debugAllowEnemyChat)) then {
    _allowEnemyChat = GVAR(debugAllowEnemyChat);
};
#endif

private _requesterUid = "";
private _requesterSide = "";

if (!isNull _requester) then {
    _requesterUid = getPlayerUID _requester;
    _requesterSide = str (side _requester);
};

private _players = [];

{
    if (isPlayer _x) then {
        private _uid = getPlayerUID _x;

        if (_uid != _requesterUid && {_allowEnemyChat || {(str (side _x)) == _requesterSide}}) then {
            _players pushBack ([_uid] call FUNC(assembleParticipant));
        };
    };
} forEach allPlayers;

#ifdef __A3_DEBUG__
{
    private _uid = _x getOrDefault ["uid", ""];

    if (_uid != _requesterUid && {_allowEnemyChat || {(_x getOrDefault ["side", ""]) == _requesterSide}}) then {
        _players pushBack ([_uid] call FUNC(assembleParticipant));
    };
} forEach (values GVAR(debugFakePlayers));
#endif

private _groups = [];

{
    private _group = _x;
    private _members = [];
    private _groupSide = "";

    {
        if (isPlayer _x) then {
            _members pushBack (getPlayerUID _x);

            if (_groupSide == "") then {
                _groupSide = str (side _x);
            };
        };
    } forEach (units _group);

    if (_members isNotEqualTo [] && {_groupSide == _requesterSide}) then {
        _groups pushBack createHashMapFromArray [
            ["id", [_group] call FUNC(getGroupId)],
            ["name", groupId _group],
            ["side", _groupSide],
            ["memberUids", _members]
        ];
    };
} forEach allGroups;

#ifdef __A3_DEBUG__
{
    private _groupSide = _x getOrDefault ["side", ""];

    if (_groupSide == _requesterSide) then {
        private _members = _x getOrDefault ["memberUids", []];

        if (count _members > 0) then {
            _groups pushBack createHashMapFromArray [
                ["id", _x getOrDefault ["id", ""]],
                ["name", _x getOrDefault ["name", ""]],
                ["color", _x getOrDefault ["color", ""]],
                ["side", _groupSide],
                ["memberUids", _members]
            ];
        };
    };
} forEach (values GVAR(debugFakeGroups));
#endif

createHashMapFromArray [
    ["players", _players],
    ["groups", _groups],
    ["allowEnemyChat", _allowEnemyChat]
]
