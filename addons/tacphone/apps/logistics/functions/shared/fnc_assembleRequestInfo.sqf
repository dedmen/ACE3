#include "..\..\script_component.hpp"
/*
 * Author: Dedmen
 * Builds the LogisticsRequestInfo payload (plan section 4.2, see
 * ACE_TacPhone_Logistics/src/types.ts) from a server request record.
 *
 * Pure: reads only the record itself. The record and the payload share the
 * field names: location stays a hashmap {kind, marker, position [x, y]}
 * ("" for marker when the location is a position) and history an array of
 * {state, byUid, byName, at} hashmaps. All epoch fields (created, history at)
 * are UTC seconds as strings.
 *
 * Arguments:
 * 0: Request record <HASHMAP>
 *
 * Return Value:
 * LogisticsRequestInfo <HASHMAP> ({id, description, location, requesterUid, requesterName, created, state, history, roomId})
 *
 * Example:
 * [GVAR(serverRequests) get "L-1"] call ace_tacphone_Logistics_fnc_assembleRequestInfo
 *
 * Public: No
 */

params ["_record"];

createHashMapFromArray [
    ["id", _record get "id"],
    ["description", _record get "description"],
    ["location", _record get "location"],
    ["requesterUid", _record get "requesterUid"],
    ["requesterName", _record get "requesterName"],
    ["created", _record get "created"],
    ["state", _record get "state"],
    ["history", _record get "history"],
    ["roomId", _record get "roomId"]
]
