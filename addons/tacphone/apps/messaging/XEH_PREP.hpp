PREP(processBrowserRequest);

// Server-only
PREP(serverHandleRequest);
PREP(serverCreateRoom);
PREP(serverAddParticipants);
PREP(serverRemoveParticipants);
PREP(serverHandleNewMessage);
PREP(serverForwardMessage);
PREP(serverInviteToRoom);
PREP(serverJoinRoom);
PREP(serverSync);
PREP(serverSyncRoom);
PREP(serverPushMessage);
PREP(serverSendPush);
PREP(serverPushPlayerList);
PREP(serverAssembleRoom);
PREP(serverCanChat);
PREP(serverBuildRoom);
PREP(serverStoreRoom);
PREP(serverAddParticipantToRoom);
PREP(serverBroadcastRoom);
PREP(serverBroadcastPresence);
PREP(serverUpdatePresence);
PREP(serverSetClientPresence);
PREP(serverPlayerDisconnected);
PREP(serverTrackGroup);
PREP(serverRefreshGroupFlag);
PREP(serverGroupChanged);
PREP(serverGroupDeleted);
PREP(serverGroupSystemMessage);
PREP(serverDeleteRoom);
PREP(serverUntrackGroup);
PREP(serverExportState);
PREP(serverImportState);
PREP(serverSaveState);
PREP(serverLoadState);

// Client-only
PREP(clientHandlePush);
PREP(clientPushToWeb);
PREP(clientUpdatePresence);
PREP(clientRemoveClient);

// Shared helpers
PREP(getPlayerList);
PREP(generateId);
PREP(assembleMessage);
PREP(assembleParticipant);
PREP(getPlayerByUid);
PREP(getGroupId);
PREP(getGroupMemberUids);
PREP(getPresence);
PREP(getLocalPresence);
PREP(newPush);
PREP(relayToServer);

// Debug-only commands. Never compiled into release builds.
#ifdef __A3_DEBUG__
PREP(debugHandleRequest);
PREP(debugAddFakePlayers);
PREP(debugReset);
PREP(debugInjectMessage);
PREP(debugGroupUnit);
PREP(debugAIGroup);
PREP(debugRoomInfo);
PREP(debugRemoteAccess);
PREP(debugSetAllowEnemyChat);
PREP(debugSetPresence);
PREP(debugSetLocalDisplayMode);
PREP(debugSaveState);
PREP(debugLoadState);
#endif
