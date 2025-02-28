PREP(createApp);
PREP(createContact);
PREP(handleAppMessage);
PREP(insertMessagesToState);
PREP(onClose);

if (isServer) then {
    PREP(serverHandleNewMessage);
};