PREP_SUBDIR(shared,processBrowserRequest);
PREP_SUBDIR(shared,relayToServer);
PREP_SUBDIR(shared,assembleRequestInfo);
PREP_SUBDIR(shared,getPlayerByUid);

// Server-only
PREP_SUBDIR(server,serverHandleRequest);
PREP_SUBDIR(server,serverCreateRequest);
PREP_SUBDIR(server,serverSetRequestState);
PREP_SUBDIR(server,serverSetRole);
PREP_SUBDIR(server,serverRoomAccess);
PREP_SUBDIR(server,serverPushRequest);
PREP_SUBDIR(server,serverPushState);
PREP_SUBDIR(server,serverPushRole);
PREP_SUBDIR(server,serverPushAll);
PREP_SUBDIR(server,serverPruneRequests);
PREP_SUBDIR(server,serverPlayerDisconnected);

// Client-only
PREP_SUBDIR(client,clientHandlePush);
PREP_SUBDIR(client,clientPushToWeb);

// Debug-only commands. Never compiled into release builds.
#ifdef __A3_DEBUG__
PREP_SUBDIR(debug,debugCreateTestRequest);
PREP_SUBDIR(debug,debugSetRole);
PREP_SUBDIR(debug,debugReset);
#endif
