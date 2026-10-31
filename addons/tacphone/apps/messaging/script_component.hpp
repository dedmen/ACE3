// This file is only for use within ACE, you would not use this when creating 3rd party apps in stand-alone PBO's

#define APPNAME Messaging
#define COMPONENT_BEAUTIFIED Tacphone App Messaging

#include "..\script_component.hpp"

// Root Tacphone display modes. They cannot be read from the root
// script_component.hpp here, because that file redefines COMPONENT.
#define MESSAGING_DISPLAY_MODE_CLOSED 0
#define MESSAGING_DISPLAY_MODE_HUD 1
#define MESSAGING_DISPLAY_MODE_DIALOG 2
#define MESSAGING_DISPLAY_MODE_HIDDEN 3

// Presence values, matching ChatPresence in MessagingApp/src/api.ts.
#define MESSAGING_PRESENCE_AVAILABLE "available"
#define MESSAGING_PRESENCE_MINIMIZED "minimized"
#define MESSAGING_PRESENCE_OFFLINE "offline"

// Routing key of every request and push. Matches MESSAGING_APP_NAME.
#define MESSAGING_APP "Messaging"

// Number of messages per ChatState.Room chunk.
#define MESSAGING_SYNC_CHUNK_SIZE 100

// Chat object kind used for room invites carried by a normal chat message.
// The payload is { roomId, roomName, inviteKey }.
#define MESSAGING_INVITE_OBJECT_KIND "messaging.room_invite"
#define MESSAGING_INVITE_OBJECT_VERSION 1

// Persistence scaffolding (disabled). See fnc_serverExportState.
#define MESSAGING_PERSISTENCE_KEY "ace_tacphone_messaging_state"
#define MESSAGING_PERSISTENCE_VERSION 1
