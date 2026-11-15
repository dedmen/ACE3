#include "..\..\script_component.hpp"
/*
 * Author: Dedmen
 * Opens the participant cache scope for the current server run. Every server
 * entry point that assembles participants (request dispatch, group events)
 * opens one; a scope stays open until the next one starts.
 *
 * Within one run the SQF world is frozen (engine events only run between
 * scripts), so a participant assembled under a scope stays valid for the
 * rest of the run: FUNC(serverCachedParticipant) and the per-side public
 * list cache are honoured only while a scope is open (O3/O2).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call ace_tacphone_Messaging_fnc_serverBeginParticipantScope
 *
 * Public: No
 */

GVAR(serverParticipantScope) = GVAR(serverParticipantScope) + 1;
GVAR(serverParticipantCache) = createHashMap;
GVAR(serverPublicListCache) = createHashMap;
