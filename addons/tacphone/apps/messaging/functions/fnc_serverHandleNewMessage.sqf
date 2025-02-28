#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Handles a new message being sent between players or in a group on server side.
 * Server stores messages for JIP
 *
 * Arguments:
 * senderPlayerID: String PlayerUID of player who sent the message
 * contactId: String // Either a SteamUID of a player (for direct message), or the ID of a group conversation
 * message: HashMap
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call ace_tacphone_messaging_fnc_serverHandleNewMessage
 *
 * Public: No
 */
params ["_senderPlayerID", "_contactId", "_message"];


// Find the contact, it is either a conversation between two players, or a group
// Note the state sharing here, we intentionally share one instance of the messages array between multiple players to not store duplicates and waste memory
// That way a single insert into a conversation, adds the message to all participants

/*
GVAR(jipState) = Dictionary<PlayerUID, Dictionary<ContactId, Message[]>>

Each player has a mapping for all their conversations.
But, in a Player-to-Player DM conversation, both players will reference the same Message[] array instance
*/


private _playerMap = GVAR(jipState) getOrDefault [_senderPlayerID, createHashMap, true];

// conversation is just an array of messages
private _conversation = _playerMap getOrDefaultCall [_contactId, {
	// Here is where we need to handle creating the shared array between multiple players 

	private _conversationId = _contactId; // We might replace it later

    // This will become a list of playerUID's of all members (except the sender) in the conversation
	private _conversationMembers = [];

	// If contact is a DM, we only have two participants, _senderPlayerID and _contactId 
	// If it is only numbers and nothing else, its a playerUID
	if (_contactId regexMatch "^\d*$") then {
		_conversationMembers = [_contactId];

		// This is a bit cheaty way to do it, but its simple to do it here
		// In player-to-player, both players have different IDs for the same conversation. As we now add it to the opposite player, we also need to use the opposite ID 
		_conversationId = _senderPlayerID;
	} else {
		//#TODO get all group members
		//#TODO handle groups
		_conversationMembers = []; //#TODO


		_conversationMembers deleteAt (_conversationMembers find _senderPlayerID); // We already handle the sender, we don't want to assign it twice

		// Note: With groups, we could run into a situation where other group members already have the conversation, but a recently added member does not yet have it
		// In that case we land here trying to create the array, but the array already exists. So we check first if someone else has this conversation
		// With player-to-player that situation should never come up, as all participants are always initialized with the first message

		private _found = _conversationMembers findIf { 
			private _playerData = GVAR(jipState) getOrDefault [_x, createHashMap, true];
			_conversationId in _playerData;
		};

		if (_found != -1) exitWith {
			// Member already has the conversation, re-use it and apply it to our sender player
			
			private _playerData = GVAR(jipState) get (_conversationMembers select _found);
			_playerData get _conversationId;
		};
	};

	private _messagesList = [];

	// Assign the shared array to all members of the conversation
	{
		private _playerData = GVAR(jipState) getOrDefault [_x, createHashMap, true];
		_playerData set [_conversationId, _messagesList];
	} forEach _conversationMembers;

	_messagesList
}, true];

// Append the new message to the conversation (It will be added to all participants through the shared array instance)
_conversation pushBack _message;
