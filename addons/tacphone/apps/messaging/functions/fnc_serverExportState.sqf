#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Flattens the server room maps into a serializable structure for
 * missionProfileNamespace. Persistence is disabled in this task: nothing calls
 * this automatically.
 *
 * Participant maps are flattened to [uid, info] pairs so the shared room record
 * can be rebuilt by FUNC(serverImportState).
 *
 * TODO: decide when to save (round end, mission end, periodic).
 * TODO: schema migration once the version changes.
 * TODO: size limits, missionProfileNamespace is a small profile file.
 * TODO: whether state should survive mission switches.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Serialized state <HASHMAP>
 *
 * Example:
 * [] call ace_tacphone_Messaging_fnc_serverExportState
 *
 * Public: No
 */

private _rooms = [];

{
    private _record = _x;
    private _participantMap = _record get "participants";
    private _participants = [];

    {
        _participants pushBack [_x, _participantMap get _x];
    } forEach (keys _participantMap);

    _rooms pushBack createHashMapFromArray [
        ["id", _record get "id"],
        ["kind", _record get "kind"],
        ["name", _record getOrDefault ["name", ""]],
        ["participants", _participants],
        ["groups", keys (_record getOrDefault ["groups", createHashMap])],
        ["messages", _record getOrDefault ["messages", []]],
        ["createdAt", _record getOrDefault ["createdAt", 0]],
        ["createdBy", _record getOrDefault ["createdBy", ""]],
        ["inviteKey", _record getOrDefault ["inviteKey", ""]]
    ];
} forEach (values GVAR(serverRooms));

createHashMapFromArray [
    ["version", MESSAGING_PERSISTENCE_VERSION],
    ["savedAt", time],
    ["messageCounter", GVAR(serverMessageCounter)],
    ["roomCounter", GVAR(serverRoomCounter)],
    ["rooms", _rooms]
]
