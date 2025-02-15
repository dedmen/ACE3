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

			private _newMessages = [];
			{
				// _x timestamp 
				// _y {author: string, content: string}

				_newMessages pushBack createHashMapFromArray [
					["author", _y get "author"],
					["timestamp", _x],
					["content", _y get "content"]
				]
			}
			forEach (_y get "messages");

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

		private _target = _message get "receiver"; // ID of the contact, Steam UID for direct message, or group ID for groups
		private _content = _message get "content";
		private _timestamp = _message get "timestamp";

		//#TODO send message to the other player 


		private _newMessage = 
			createHashMapFromArray [
				["author", name player], // In here, this is always the name of the local player
				["timestamp", _timestamp],
				["content", _content]
			];

		// Store in local state
		[_target, _newMessage, true] call FUNC(insertMessageToState);

		//#TODO send to server (for JIP state) and target's machine so they can insert it to state

		// We send as JSON, because string is more efficient over network

		private _targets = [];

		//#TODO the ":" is just a placeholder, we need some non-number character in the ID to indicate it being a group chat
		if (_target find ":" != -1) then {
			//#TODO handle groups, we must find the players inside the group
		} else {
			// Target must be Steam UID, its a direct message. Find which player it goes to

			private _allPlayers = allPlayers;
			
			private _targetPlayer = _allPlayers param [_allPlayers findIf {getPlayerUID _x == _target}];
			_targets pushBack _targetPlayer; // Might be nil!
		};

		[QGVAR(newMessage), [_target, toJSON _newMessage], _targets] call CBA_fnc_targetEvent;
	};
}

