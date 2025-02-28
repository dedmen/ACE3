#include "script_component.hpp"

//#include "initKeybinds.inc.sqf"


// State will store all contacts, all messages and some info about last UI state
// It will also be filled when phone is not open
// When phone is opened, it loads all data out of it


// class Contact {id: "steamuid", name: "displayname", messages: HashMap<string (timestamp), Message> }
// class Message {author: "displayname", content: "content", timestamp: "2025-02-15T16:42:05.127Z"}

if (isServer) then {
	GVAR(jipState) = createHashMap;

	[QGVAR(newMessageServer), {
		params ["_senderId", "_contactId", "_message"];

		// This arrives over network, that means we get new string instances for all the message hashmap keys
		// To save memory, we deduplicate them by re-assigning (That will make all the keys in all messages we store, become a reference to our strings in this file)
		// Note that if new entries are added to message structure, they should be handled here too, but forgetting it will just waste some memory
		_message = fromJSON _message;

		{
			private _oldValue = _message get _x;
			_message deleteAt _x;
			_message set [_x, _oldValue];
		} forEach ["author", "content", "timestamp"];

		// Insert into local state and display on phone if open
		[_senderId, _contactId, _message] call FUNC(serverHandleNewMessage);
	}] call CBA_fnc_addEventHandler;

	[QGVAR(requestMessagesJIP), {
		params ["_senderPlayerUID", "_senderOwnerId"];

		// The player with UID _senderId, wants to retrieve their JIP stash, we send them all their conversations as Dictionary<ContactID, Message[]>
		private _playerMap = GVAR(jipState) getOrDefault [_senderPlayerUID, createHashMap, true];
		[QGVAR(responseMessagesJIP), [toJSON _playerMap], _senderOwnerId] call CBA_fnc_ownerEvent;
	}] call CBA_fnc_addEventHandler;



	addMissionEventHandler ["PlayerConnected", {
		params ["_id", "_uid", "_name", "_jip", "_owner", "_idstr"];
		[QGVAR(registerNewContact), [_uid, _name]] call CBA_fnc_remoteEvent;
	}];
};


if (!isDedicated) then {
	GVAR(state) = createHashMapFromArray [
		["contacts", createHashMap] // contactId: class Contact
	];
	//#TODO we need to keep it updated when new player joins 
	private _contacts = GVAR(state) get "contacts";
	{
		//#TODO do not add local player itself to contacts

		[getPlayerUID _x, name _x] call FUNC(createContact);
	} forEach allPlayers;

	[QGVAR(registerNewContact), {
		params ["_contactId","_name"];
		[_contactId, _name] call FUNC(createContact);
	}] call CBA_fnc_addEventHandler;

	[QGVAR(newMessage), {
		params ["_contactId","_message"];
		// contactId: String // Either a SteamUID of a player (for direct message), or the ID of a group conversation
		// _message: String // JSON string {author: "displayname", content: "content", timestamp: "2025-02-15T16:42:05.127Z"}

		// This arrives over network, that means we get new string instances for all the message hashmap keys
		// To save memory, we deduplicate them by re-assigning (That will make all the keys in all messages we store, become a reference to our strings in this file)
		// Note that if new entries are added to message structure, they should be handled here too, but forgetting it will just waste some memory
		_message = fromJSON _message;

		{
			private _oldValue = _message get _x;
			_message deleteAt _x;
			_message set [_x, _oldValue];
		} forEach ["author", "content", "timestamp"];

		// Insert into local state and display on phone if open
		[_contactId, [_message], true] call FUNC(insertMessagesToState);

		//#TODO notification sound?
	}] call CBA_fnc_addEventHandler;

	[QGVAR(responseMessagesJIP), {
		params ["_messageData"];

		// Server has sent us our JIP state as JSON string of Dictionary<ContactID, Message[]>
		// Apply them to our local state

		_messageData = fromJSON _messageData; // Convert to hashmap
		{
			[_x, _y, true] call FUNC(insertMessagesToState);
		} forEach _messageData;

	}] call CBA_fnc_addEventHandler;

	// Request JIP state from server
	[QGVAR(requestMessagesJIP), [getPlayerUID player, clientOwner]] call CBA_fnc_serverEvent;
}

