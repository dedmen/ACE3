#include "script_component.hpp"

//#include "initKeybinds.inc.sqf"


// State will store all contacts, all messages and some info about last UI state
// It will also be filled when phone is not open
// When phone is opened, it loads all data out of it


// class Contact {id: "steamuid", name: "displayname", messages: HashMap<string (timestamp), Message> }
// class Message {author: "displayname", content: "content", timestamp: "2025-02-15T16:42:05.127Z"}

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


	[QGVAR(newMessage), {
		params ["_contactId","_message"];
		// contactId: String // Either a SteamUID of a player (for direct message), or the ID of a group conversation
		// _message: String // JSON string {author: "displayname", content: "content", timestamp: "2025-02-15T16:42:05.127Z"}

		// Insert into local state and display on phone if open
		[_contactId, fromJSON _message, true] call FUNC(insertMessageToState);

		//#TODO notification sound?
	}] call CBA_fnc_addEventHandler;
}

