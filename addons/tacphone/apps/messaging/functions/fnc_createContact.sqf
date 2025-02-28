#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Create a new contact in messaging
 *
 * Arguments:
 * contactId: String // Either a SteamUID of a player (for direct message), or the ID of a group conversation
 * name: String // The displayName of the contact
 *
 * Return Value:
 * None
 *
 * Example:
 * ["1234", "MrX"] call ace_tacphone_messaging_fnc_createContact
 *
 * Public: No
 */

params ["_contactId", "_contactName"];

private _contacts = GVAR(state) get "contacts";

private _newContact = _contacts getOrDefaultCall [_contactId, { createHashMapFromArray [["id", _contactId], ["name", _contactName], ["messages", []]] }, true];

_newContact set ["name", _contactName]; // If contact already existed, we just update its name
