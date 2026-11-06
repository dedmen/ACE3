PREP_SUBDIR(shared,processBrowserRequest);

// Server-only
PREP_SUBDIR(server,serverHandleRequest);
PREP_SUBDIR(server,serverPushToUids);
PREP_SUBDIR(server,serverCreateRoom);
PREP_SUBDIR(server,serverAddParticipants);
PREP_SUBDIR(server,serverRemoveParticipants);
PREP_SUBDIR(server,serverHandleNewMessage);
PREP_SUBDIR(server,serverForwardMessage);
PREP_SUBDIR(server,serverInviteToRoom);
PREP_SUBDIR(server,serverJoinRoom);
PREP_SUBDIR(server,serverSync);
PREP_SUBDIR(server,serverPushMessage);
PREP_SUBDIR(server,serverSendPush);
PREP_SUBDIR(server,serverPushPlayerList);
PREP_SUBDIR(server,serverCanChat);
PREP_SUBDIR(server,serverStoreRoom);
PREP_SUBDIR(server,serverBroadcastRoom);
PREP_SUBDIR(server,serverRoomParticipants);
PREP_SUBDIR(server,serverParticipantSides);
PREP_SUBDIR(server,serverSetRoomPublic);
PREP_SUBDIR(server,serverListPublicRooms);
PREP_SUBDIR(server,serverPushPublicRooms);
PREP_SUBDIR(server,serverBroadcastPresence);
PREP_SUBDIR(server,serverUpdatePresence);
PREP_SUBDIR(server,serverSetClientPresence);
PREP_SUBDIR(server,serverPlayerDisconnected);
PREP_SUBDIR(server,serverTrackGroup);
PREP_SUBDIR(server,serverRefreshGroupFlag);
PREP_SUBDIR(server,serverGroupChanged);
PREP_SUBDIR(server,serverGroupDeleted);
PREP_SUBDIR(server,serverGroupSystemMessage);
PREP_SUBDIR(server,serverDeleteRoom);
PREP_SUBDIR(server,serverUntrackGroup);
PREP_SUBDIR(server,serverExportState);
PREP_SUBDIR(server,serverImportState);
PREP_SUBDIR(server,serverSaveState);
PREP_SUBDIR(server,serverLoadState);

// Client-only
PREP_SUBDIR(client,clientHandlePush);
PREP_SUBDIR(client,clientPushToWeb);
PREP_SUBDIR(client,clientUpdatePresence);
PREP_SUBDIR(client,clientRemoveClient);

// Shared helpers
PREP_SUBDIR(shared,getPlayerList);
PREP_SUBDIR(shared,generateId);
PREP_SUBDIR(shared,assembleMessage);
PREP_SUBDIR(shared,assembleParticipant);
PREP_SUBDIR(shared,getPlayerByUid);
PREP_SUBDIR(shared,getGroupId);
PREP_SUBDIR(shared,getGroupMemberUids);
PREP_SUBDIR(shared,getPresence);
PREP_SUBDIR(shared,getLocalPresence);
PREP_SUBDIR(shared,relayToServer);

// Debug-only commands. Never compiled into release builds.
#ifdef __A3_DEBUG__
PREP_SUBDIR(debug,debugHandleRequest);
PREP_SUBDIR(debug,debugAddFakePlayers);
PREP_SUBDIR(debug,debugReset);
PREP_SUBDIR(debug,debugInjectMessage);
PREP_SUBDIR(debug,debugGroupUnit);
PREP_SUBDIR(debug,debugAIGroup);
PREP_SUBDIR(debug,debugRoomInfo);
PREP_SUBDIR(debug,debugSetRoomPublic);
PREP_SUBDIR(debug,debugSetAllowEnemyChat);
PREP_SUBDIR(debug,debugSetPresence);
PREP_SUBDIR(debug,debugSaveState);
PREP_SUBDIR(debug,debugLoadState);
#endif
