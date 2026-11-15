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
                                                     -> fnc_clientPushToWeb (hub broadcasts)
```

Every push carries `a: "Messaging"`, `c` and `now` (server mission time).

## State (server only)

- `GVAR(serverRooms)`: room id -> room record.
- `GVAR(serverRoomsByPlayer)`: player uid -> `HashMap<room id, room record>`.
- `GVAR(serverPlayerClients)`: player uid -> `HashMap<client id, visible>`.
  Client ids are `"local"` (the in-game phone) plus one id per external page;
  the in-game relay hub tags forwarded requests `__sourceClient`, which the
  SQF dispatch resolves as that id (see `websource/AGENTS/remote.md`).
- `GVAR(serverPlayerPresence)`: player uid -> `available` / `minimized` / `offline`.
- `GVAR(serverPlayerByUid)`: player uid -> player object (O(1) lookup cache for
  `fnc_getPlayerByUid`; created lazily, entries drop on `HandleDisconnect`).
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
- **Message caps**: `SendMessage` rejects `content` above
  `MESSAGING_MAX_MESSAGE_CONTENT` characters and `objects` above
  `MESSAGING_MAX_MESSAGE_OBJECTS` entries or a `str` form over
  `MESSAGING_MAX_OBJECTS_SIZE` (all in `script_component.hpp`). Types are
  the web's to validate; only the caps are checked server-side. The caps sit
  above the web client's 96 KiB self-limit, so legitimate traffic never
  trips them.
- **AddParticipants** to a direct room flips it to a group room before the
  targets resolve (group tracking only accepts group rooms), and every newly
  added player receives the room's full history, the same way a joiner does.
- **Re-creating** an existing direct room re-adds the creator with their
  `creator` flag intact (`fnc_serverStoreRoom` derives it from the record's
  `createdBy`).
- **Public rooms**: a `group` room with an empty `inviteKey` is public; the
  record itself is unchanged and every room payload (`Room.Upsert`,
  `ChatState.Room`) carries the derived `isPublic`
  (`kind == "group" && inviteKey == ""`). `CreateRoom` accepts
  `room.public: true` (group rooms only; a direct room keeps its random key).
  `SetRoomPublic { roomId, public }` is creator-only and group-only:
  `public: true` clears the key, `public: false` regenerates one in the
  existing format (invites sent earlier stop working). `GetPublicRooms`
  answers pending; the list arrives as a targeted `PublicRooms.State` push
  (the full side-filtered list) after the request and after every mutation
  that changes what a side can see: create, toggle, join, add/remove
  participants, group join/leave and delete. A request whose sender
  disconnected mid-relay is answered with an `Error` push instead of a list
  for a dead side. The push buckets the registered players by side in one
  pass, and the per-side list build shares one participant-cache scope per
  server run. A room is listed for a player
  only if every participant is on the player's side (the exact `JoinRoom`
  group rule), so a public room with mixed-side participants (only possible
  with `allowEnemyChat`) is listed for no side while staying usable to its
  members. `JoinRoom` is unchanged: an empty or missing key matches a public
  room and the group side check still runs.

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

The export/import round-trip restores the participant group fields and
re-tracks every exported group that still exists in-game (event handlers
reinstalled, current members re-added, members that joined in-game after the
export picked up). A group that no longer exists — or has no unit left —
cannot be re-tracked and its members' group fields are cleared. Import
validation rejects malformed entries, bad participant pairs and duplicate
room ids before the live rooms are replaced.

TODO:
- Decide when to save (round end, mission end, periodic), schema migration,
  size limits, and whether state survives mission switches.
- Group colours are not available yet; use the future group member colour
  system for participant `groupColor`.

## Debug commands (`#ifdef __A3_DEBUG__`)

`Messaging.Debug.AddFakePlayers`, `.Reset`, `.InjectMessage`, `.GroupUnit`,
`.AIGroup`, `.RoomInfo`, `.SetAllowEnemyChat`, `.SetPresence`, `.SetRoomPublic`,
`.SaveState`, `.LoadState`, `.Status`.

`Messaging.Debug.Reset` tells open pages before it clears: every participant
of every room gets a `Room.Upsert` push with `removed: true`, so a page drops
its rooms instead of keeping stale conversations until a re-sync.

Fake players are server-side records with their own side, group, colour and
presence; they work in the player list, room creation, messages, forwarding,
invites and presence broadcasts. Release builds do not compile these functions.

`Debug.RoomInfo` carries `inviteKey` and the derived `isPublic` flag, and
`Debug.SetRoomPublic` toggles a room's public state without the creator check,
so the test suite can toggle rooms it did not create.

## Build

The page bundle is built in `websource/MessagingApp` (see its README):

```powershell
npm run build -w ace-tacphone-messaging
Copy-Item MessagingApp\dist\ace_tacphone_messaging.js ..\apps\messaging\data\ace_tacphone_messaging.js
```

Then run `hemtt build --no-bin` from the ACE3 root. The app is registered through
`ace_tacphone_apps.hpp` (class `Messaging`) and the PBO ships
`apps\messaging\data\ace_tacphone_messaging.js`.
