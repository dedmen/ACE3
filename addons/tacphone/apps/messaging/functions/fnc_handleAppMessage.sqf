#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Handles a message that was sent from the UI
 *
 * Arguments:
 * The UI's WebBrowser control
 *
 * Return Value:
 * None
 *
 * Example:
 * [_browserControl, ""] call ace_tacphone_messaging_fnc_handleAppMessage
 *
 * Public: No
 */

params ["_browserControl", "_message"];

systemChat str ["AppMessageOut", _message];
diag_log ["AppMessageOut", _message];

private _sendMessageToUI = {
	params ["_message"]; // Message is hashmap, _browserControl comes from parent scope
	_browserControl ctrlWebBrowserAction ["ExecJS", format ["OnGameMessage(%1)", toJSON _message]];
};

private _message = fromJSON _message;

switch (_message get "action") do
{
	case "InitialLoad": {

		// Send it all contacts and then all messages of them

		// ### Contacts
		private _contacts = [];
		{
			// _x contactId
			// _y class Contact 
			_contacts pushBack createHashMapFromArray [["id", _x], ["name", _y get "name"]];
		} forEach (GVAR(state) get "contacts");

		private _commandMessage = createHashMapFromArray [["action", "AddContacts"], ["contacts", _contacts]];
		_commandMessage call _sendMessageToUI;


		// ### Messages

		// Send all the contacts messages
		private _contacts = [];
		{
			// _x contactId
			// _y class Contact 

			private _newMessages = (_y get "messages");

			_contacts pushBack createHashMapFromArray [
				["id", _x], //#TODO in direct messaging this is Steam UID of sender, in group messaging this is ID of the group
				["messages", _newMessages]
			]
		} forEach (GVAR(state) get "contacts");

		private _commandMessage = createHashMapFromArray [
			["action", "AddMessages"],
			["contacts", _contacts]
		];
		_commandMessage call _sendMessageToUI;

		// ### Set self name 

		private _commandMessage = createHashMapFromArray [
			["action", "SetSelfUser"],
			["name", name player]
		];
		_commandMessage call _sendMessageToUI;




		//#TODO remember the chat that was last opened, and re-open it

	};

	case "SendNewMessage": {
		private _targetContactId = _message get "receiver"; // ID of the contact, Steam UID for direct message, or group ID for groups
		private _chatMessage = _message get "message";

		// This code is written so that the javascript has (near) full control over the contents of the Message structure.
		// We don't actually access the contents of the Message structure, we just pass it around.

		// This arrives from JS, that means we get new string instances for all the message hashmap keys
		// To save memory, we deduplicate them by re-assigning (That will make all the keys in all messages we store, become a reference to our strings in this file)
		// Note that if new entries are added to message structure, they should be handled here too, but forgetting it will just waste some memory
		{
			private _oldValue = _chatMessage get _x;
			_chatMessage deleteAt _x;
			_chatMessage set [_x, _oldValue];
		} forEach ["author", "content", "timestamp"];

		// Store in local state (don#t send to phone, because it came from phone so it already has it)
		[_targetContactId, [_chatMessage], false] call FUNC(insertMessagesToState);

		// Now send to other machines over network

		private _targets = [];

		//#TODO the ":" is just a placeholder, we need some non-number character in the ID to indicate it being a group chat
		if (_targetContactId find ":" != -1) then {
			//#TODO handle groups, we must find the players inside the group
		} else {
			// Target must be Steam UID, its a direct message. Find which player it goes to

			private _allPlayers = allPlayers;
			
			private _targetPlayer = _allPlayers param [_allPlayers findIf {getPlayerUID _x == _targetContactId}];
			_targets pushBack _targetPlayer; // Might be nil!
		};

		// We send as JSON, because string is more efficient over network
		private _messageEncoded = toJSON _chatMessage;

		[QGVAR(newMessage), [_targetContactId, _messageEncoded], _targets] call CBA_fnc_targetEvent; // Send to other participants
		[QGVAR(newMessageServer), [getPlayerUID player, _targetContactId, _messageEncoded]] call CBA_fnc_serverEvent; // Send to server for JIP state
	};
};

