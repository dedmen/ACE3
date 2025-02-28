#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Store messages into the local messaging state
 *
 * Arguments:
 * contactId: String // Either a SteamUID of a player (for direct message), or the ID of a group conversation
 * message: Array of HashMap
 * sendToPhone: bool // Display it in local phone if it is open
 *
 * Return Value:
 * None
 *
 * Example:
 * [_contactId, [_message]] call ace_tacphone_messaging_fnc_insertMessagesToState
 *
 * Public: No
 */

params ["_contactId", "_newMessages", ["_sendToPhone", false, [false]]];

//#TODO we should store full state per player on server too if we want to have JIP. Alternative we could store in profileNamespace and see if player is reconnecting to the last server they were on

// _message = class Message {author: "displayname", content: "content", timestamp: "2025-02-15T16:42:05.127Z"}

#pragma region UpdateState

private _state = GVAR(state);
private _contacts = _state get "contacts";

private _contact = _contacts getOrDefaultCall [_contactId, {
	// Create new contact //#TODO This should not happen, we don't have the contact's name. The contacat should already be registered
	createHashMap
}, true];

private _messages = _contact getOrDefault ["messages", [], true];

_messages append _newMessages;

#pragma endregion UpdateState


// Now if the phone is currently open, immediately tell it about the new message

private _browserCtrl = localNamespace getVariable [QGVAR(browserCtrl), controlNull];

if (_sendToPhone && !isNull _browserCtrl) then {
	// Phone is open right now, tell it about the new message

	/*
	action: AddMessages
	contacts: [
		{
			id: "1234",
			messages: [{
				author: "AuthorName", //#TODO store space by using ID? But steam UID is too large to save space with it. If every contact has an array of participants, we could give the index here
				timestamp: "2025-02-15T16:42:05.127Z",
				content: "Hello world!"
			}, ...]
		}, ...
	]
	*/

	private _contacts = [
		createHashMapFromArray [
			["id", _contactId], //#TODO in direct messaging this is Steam UID of sender, in group messaging this is ID of the group
			["messages", _newMessages]
		]
	];

	private _commandMessage = createHashMapFromArray [
		["action", "AddMessages"],
		["contacts", _contacts]
	];

	//#TODO make function? this is re-used
	private _sendMessageToUI = {
		params ["_message"]; // Message is hashmap, _browserCtrl comes from parent scope
		systemChat toJSON _message;
		_browserCtrl ctrlWebBrowserAction ["ExecJS", format ["OnGameMessage(%1)", toJSON _message]];
	};
	_commandMessage call _sendMessageToUI;
};


// class Message {author: "displayname", content: "content", timestamp: "2025-02-15T16:42:05.127Z"}




