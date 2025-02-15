#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Store message into the local messaging state
 *
 * Arguments:
 * contactId: String // Either a SteamUID of a player (for direct message), or the ID of a group conversation
 * message: HashMap
 * sendToPhone: bool // Display it in local phone if it is open
 *
 * Return Value:
 * None
 *
 * Example:
 * [_contactId, _message] call ace_tacphone_messaging_fnc_insertMessageToState
 *
 * Public: No
 */

params ["_contactId", "_message", ["_sendToPhone", false, [false]]];

//#TODO we should store full state per player on server too if we want to have JIP. Alternative we could store in profileNamespace and see if player is reconnecting to the last server they were on

// _message = class Message {author: "displayname", content: "content", timestamp: "2025-02-15T16:42:05.127Z"}

#pragma region UpdateState

private _state = GVAR(state);
private _contacts = _state get "contacts";

private _contact = _contacts getOrDefaultCall [_contactId, {
	// Create new contact //#TODO This should not happen, we don't have the contact's name. The contacat should already be registered
	createHashMap
}, true];

private _messages = _contact getOrDefaultCall ["messages", {createHashMap}, true];

_messages set [
	_message get "timestamp",
	createHashMapFromArray [
		// Note: By creating a new hashmap here, we save memory usage because the strings "author" and "content" will be de-duplicated, whereas our input might have new instances
		["author", _message get "author"],
		["content", _message get "content"],
		["timestamp", _message get "timestamp"] // Yes we duplicate it in key and in the object, but it only costs us 16 bytes extra memory
	]
];

#pragma endregion UpdateState


// Now if the phone is currently open, immediately tell it about the new message

private _browserCtrl = localNamespace getVariable [QGVAR(browserCtrl), controlNull];

if !(isNull _browserCtrl) then {
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

	private _newMessages = [
		createHashMapFromArray [
			["author", _message get "author"], // In here, this is always the name of the local player //#TODO player name, what if remote controlling unit in zeus?
			["timestamp", _message get "timestamp"],
			["content", _message get "content"]
		]
	];

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
		_browserCtrl ctrlWebBrowserAction ["ExecJS", format ["OnGameMessage(%1)", toJSON _message]];
	};
	_commandMessage call _sendMessageToUI;
};


// class Message {author: "displayname", content: "content", timestamp: "2025-02-15T16:42:05.127Z"}




