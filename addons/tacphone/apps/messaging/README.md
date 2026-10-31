# Tacphone App: Messaging (game side)

Server-authoritative backend of the Messenger app. The web UI lives in
`websource/MessagingApp`; the wire protocol is `websource/MessagingApp/src/protocol.ts`.

## Files

| Path | Purpose |
| --- | --- |
| `config.cpp`, `ace_tacphone_apps.hpp` | App registration (routing key `Messaging`). |
| `script_component.hpp` | App macros, display-mode/presence constants, protocol constants. |
| `XEH_preStart.sqf`, `XEH_preInit.sqf`, `XEH_postInit.sqf` | Compile functions, create the server database, register CBA handlers. |
| `functions/fnc_processBrowserRequest.sqf` | Page request processor (local `Hello`/`SetClientPresence`, everything else relayed). |
| `functions/fnc_client*.sqf` | Request relay, server push forwarding, local presence, client cleanup. |
| `functions/fnc_server*.sqf` | Server database, rooms, messages, presence, sync, persistence. |
| `functions/fnc_debug*.sqf` | Debug-only commands (`#ifdef __A3_DEBUG__`). |

## Data flow

```
page --request--> fnc_processBrowserRequest
                     |-- Hello / SetClientPresence: answer locally
                     `-- everything else: fnc_relayToServer
                             |-- isServer: fnc_serverHandleRequest directly
                             `-- else: CBA server event ace_tacphone_Messaging_clientRequest
                                           -> fnc_serverHandleRequest
                                                 `-- pushes: CBA target event
                                                     ace_tacphone_Messaging_serverPush
                                                     -> fnc_clientHandlePush
                                                     -> fnc_clientPushToWeb (local + ws clients)
```

Every push carries `a: "Messaging"`, `c` and `now` (server mission time).

## State (server only)

- `GVAR(serverRooms)`: room id -> room record.
- `GVAR(serverRoomsByPlayer)`: player uid -> `HashMap<room id, room record>`.
- `GVAR(serverPlayerClients)`: player uid -> `HashMap<client id, visible>`.
- `GVAR(serverPlayerPresence)`: player uid -> `available` / `minimized` / `offline`.
- `GVAR(serverMessageCounter)`, `GVAR(serverRoomCounter)`.

A room record (and its `messages` array) is stored once and referenced from every
participant's map. Direct room id `dm:<lower uid>:<higher uid>`; group room id
`grp:<counter>_<random>`.

## Contract details not covered by `protocol.ts`

- **Invites** are normal `Message.New` messages whose `objects` contains one
  object with `kind: "messaging.room_invite"`, `version: 1` and
  `data: { roomId, roomName, inviteKey }` plus a `preview`. The message is stored
  in the room and pushed both to room participants and directly to invited
  players who are not participants yet. After joining, the same message id is
  part of the room sync, so the page can deduplicate by id.
- **Removal**: `Room.Upsert` is sent to the remaining participants, and the same
  push with an extra `removed: true` flag is sent to removed players so their
  page can drop the room.
- **Group ids** are `"<SIDE>:<groupId>"` (for example `"WEST:Alpha 1-1"`) because
  Arma group names are only unique per side. `GroupListEntry.id` round-trips.
- **Forwarding** stores `forwarded` exactly as described in `api.ts`.

## Presence

- The in-game page client is `"local"`, its visibility follows the TacPhone
  display mode (HUD/DIALOG = visible, CLOSED/HIDDEN = minimized).
- External page clients report their own visibility with `SetClientPresence`.
- `available` = any client visible, `minimized` = clients but none visible,
  `offline` = no client (for example after `HandleDisconnect`).
- `Presence.Changed` is pushed to players that share at least one room.

## Persistence (disabled)

`fnc_serverExportState`, `fnc_serverImportState`, `fnc_serverSaveState` and
`fnc_serverLoadState` implement a versioned `missionProfileNamespace` key but
nothing calls them automatically. `GVAR(serverPersistenceEnabled) = false`.

TODO:
- Decide when to save (round end, mission end, periodic), schema migration,
  size limits, and whether state survives mission switches.
- The page is not told when a debug reset removes its rooms; there is no
  `Room.Remove` push in the protocol yet.
- Group colours are not available yet; use the future group member colour
  system for participant `groupColor`.

## Debug commands (`#ifdef __A3_DEBUG__`)

`Messaging.Debug.AddFakePlayers`, `.Reset`, `.InjectMessage`,
`.SetAllowEnemyChat`, `.SetPresence`, `.SetLocalDisplayMode`, `.SaveState`,
`.LoadState`, `.Status`.

Fake players are server-side records with their own side, group, colour and
presence; they work in the player list, room creation, messages, forwarding,
invites and presence broadcasts. Release builds do not compile these functions.

## Build

The page bundle is built in `websource/MessagingApp` (see its README):

```powershell
npm run build -w ace-tacphone-messaging
Copy-Item MessagingApp\dist\ace_tacphone_messaging.js ..\apps\messaging\data\ace_tacphone_messaging.js
```

Then run `hemtt build --no-bin` from the ACE3 root. The app is registered through
`ace_tacphone_apps.hpp` (class `Messaging`) and the PBO ships
`apps\messaging\data\ace_tacphone_messaging.js`.
