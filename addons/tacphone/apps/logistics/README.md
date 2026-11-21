# Tacphone App: Logistics (game side)

Server-authoritative backend of the Logistics app: a shared supply-request
queue with per-player roles, progress states and a Messenger chat room per
request. The web UI lives in `websource/ACE_TacPhone_Logistics`; the design
is `websource/plans/PLAN_LOGISTICS.md`.

The queue and the player roles are server-authoritative: every player sees
the same public queue, the server knows the logistics workers (so they are
auto-joined into every request's Messenger room), and the queue survives any
single client closing their phone.

## Files

| Path | Purpose |
| --- | --- |
| `script_component.hpp` | App macros: routing key `LOGISTICS_APP`, interest `LOGISTICS_INTEREST`, queue cap, progress-state constants, `REQUIRE_SENDER` handler guard. |
| `ace_tacphone_apps.hpp`, `CfgEventHandlers.hpp` | App registration (class `ACE_TacPhone_Logistics`). |
| `XEH_preStart.sqf`, `XEH_preInit.sqf`, `XEH_postInit.sqf` | Compile functions, create the server registry, register the CBA handlers and the server `HandleDisconnect` event handler. |
| `functions/shared/fnc_processBrowserRequest.sqf` | Page request processor; pure relay, every command replies `{ok: true, pending: true}`. |
| `functions/shared/fnc_relayToServer.sqf` | Direct `fnc_serverHandleRequest` call on the server, `CBA_fnc_serverEvent` with `QGVAR(clientRequest)` otherwise. |
| `functions/shared/fnc_assembleRequestInfo.sqf` | Record → push/snapshot payload (pure). |
| `functions/shared/fnc_getPlayerByUid.sqf` | UID → player lookup (copy of the Messaging version). |
| `functions/server/fnc_serverHandleRequest.sqf` | Server dispatch, `Debug.*` inside `#ifdef __A3_DEBUG__`; rejections surface as the `Error` push. |
| `functions/server/fnc_serverCreateRequest.sqf` | Validate, build the record, create + open the Messenger room, store, push. |
| `functions/server/fnc_serverSetRequestState.sqf` | Single state-change path (progress states and `cancelled`): role check, history entry, upsert push. |
| `functions/server/fnc_serverSetRole.sqf` | Role map update; on `worker` adds the player to every open request room; role push. |
| `functions/server/fnc_serverRoomAccess.sqf` | The single Messaging-internals boundary (see below). |
| `functions/server/fnc_serverPruneRequests.sqf` | Keeps the newest `LOGISTICS_CLOSED_HISTORY_CAP` (25) closed records; deletes and pushes as `Logistics.Request.Remove` every older one. |
| `functions/server/fnc_serverPushRequest.sqf`, `fnc_serverPushState.sqf`, `fnc_serverPushRole.sqf` | Ungated broadcast pushes (built here, delivered through `fnc_serverPushAll`). |
| `functions/server/fnc_serverPushAll.sqf` | The only server→page delivery: one `QGVAR(serverPush)` `CBA_fnc_targetEvent` per player. |
| `functions/client/fnc_clientHandlePush.sqf`, `fnc_clientPushToWeb.sqf` | Client leg of the push: the target-event handler forwards to the local in-game page. |
| `functions/server/fnc_serverPlayerDisconnected.sqf` | Drops the role, pushes `Logistics.Role.Changed` with role `"left"`; the player's requests stay. |
| `functions/debug/fnc_debug*.sqf` | Debug-only commands (`#ifdef __A3_DEBUG__`). |

## Data flow

```
page --request--> fnc_processBrowserRequest (client)
                      `-- fnc_relayToServer
                              |-- isServer: fnc_serverHandleRequest directly
                              `-- else: CBA server event QGVAR(clientRequest)
                                           -> fnc_serverHandleRequest
                                                  `-- fnc_serverPushAll: one
                                                       QGVAR(serverPush) target
                                                       event per player
                                                         -> fnc_clientHandlePush
                                                            (that player's machine)
                                                         -> fnc_clientPushToWeb
                                                         -> fnc_sendCommandToPhone
                                                            (the local hub broadcasts
                                                             to this machine's page
                                                             and every external
                                                             client; the web
                                                             filters per player)
```

Every push carries `a: "ACE_TacPhone_Logistics"`. Pushes are **ungated
broadcasts** (the messaging precedent): the queue is event-driven and the
payloads small, and the interest is held by the pages on the machines that
host them — a dedicated server never sees it, so an interest early-out would
silently drop every push in a dedicated-server multiplayer mission. The web
module still acquires `ACE_TacPhone_Logistics.requests` while a panel is
mounted (page-local; it will gate any future demand-driven work).

## Trust boundary

The relay identity is client-supplied. `fnc_relayToServer` claims the
sender's UID through the public CBA event `QGVAR(clientRequest)`, and CBA
`serverEvent` does not carry the calling machine, so a client able to call
the relay event (a modified page or a custom SQF caller) can act as another
player: the server resolves the claimed UID through
`fnc_getPlayerByUid` and applies the command in that player's name. Remote
clients are paired before they can reach the mission, which matches the rest
of TacPhone; roles are not protected from a modified client. This is a
documented limitation, not a fix — verifying the sender would require
moving the relay to a `remoteExec` path that carries
`remoteExecutedOwner`.

## State (server only)

- `GVAR(serverRequests)`: request id (`"L-" + counter`) → request record
  (`id`, `description`, `location {kind, marker, position [x, y]}`,
  `requesterUid`, `requesterName`, `created`, `state`, `history`, `roomId`).
- `GVAR(serverRequestCounter)`; `GVAR(serverRoles)`: uid → `"worker"`
  (absent = `"player"`).

Retention: the queue cap limits open requests only. Closed (done/cancelled)
records are retained at the newest `LOGISTICS_CLOSED_HISTORY_CAP` (25); after
each close `fnc_serverPruneRequests` prunes the older ones (numeric id order)
and pushes each as `Logistics.Request.Remove`.

Times are UTC epoch seconds stored as **strings** (SQF floats cannot hold
large epochs exactly); the web renders them in the viewer's local time.

## Protocol

Requests (all answer `{ok: true, pending: true}`; rejections arrive as the
`Error` push, same shape as the Messaging one):

| `c` | Fields | Result |
| --- | --- | --- |
| `GetLogisticsState` | — | `Logistics.State` snapshot push |
| `CreateRequest` | `description` (≤ 500), `location {kind, marker, position}` (kind `position`\|`marker`, 2-number position, marker ≤ 128 — malformed payloads are rejected with a specific `Error`), `created` (epoch-seconds string, blanked when not), `clientToken` (≤ 64, echoed top-level in the create's upsert for the dialog's correlation) | `Logistics.Request.Upsert` push |
| `SetRequestState` | `requestId`, `state` (five progress values; workers only) | upsert push, `Error` push on rejection |
| `CancelRequest` | `requestId` (requester or any worker) | upsert with `state: "cancelled"`, `Error` push on rejection |
| `SetRole` | `role: "player" \| "worker"` | `Logistics.Role.Changed` push (an unchanged role answers `{ok: true}` without a push) |

Pushes:

| `c` | Payload |
| --- | --- |
| `Logistics.State` | `{ requests: [...], roles: {...} }` — snapshot after `GetLogisticsState` (or a debug reset) |
| `Logistics.Request.Upsert` | `{ request: {...} }` — creation or any state/history change |
| `Logistics.Request.Remove` | `{ id }` — a closed request pruned past the retention cap (25) |
| `Logistics.Role.Changed` | `{ uid, role ("player"\|"worker"\|"left"), name }` — `name` is reserved (computed and sent, but the web UI reads only `uid` and `role`) |
| `Error` | `{ request, message, requestId? }` — a relayed command was rejected |

Rejection strings: `"request gone"`, `"already closed"`, `"workers only"`,
`"not your request"`, `"queue full"` (cap `LOGISTICS_QUEUE_CAP` = 100 open)
and the create-request payload errors.

## Messenger coupling

`fnc_serverRoomAccess.sqf` is the only file allowed to touch Messaging
internals. It creates the request's `group` room (name `"Logistics <id>"`),
makes it public through `serverSetRoomPublic` (the requester is the room
creator) so any same-side player can join from the queue with an empty
invite key, and auto-joins the current workers. Every guard degrades to
"request without a (public) room": a missing Messaging app or a failed
create/`SetRoomPublic` logs one `diag_log` warning and `roomId` stays `""`.
When a player switches to `worker`, `fnc_serverSetRole` reuses the
`"addWorker"` path for every open request room; finished and cancelled
rooms are never touched. An unchanged `SetRole` (e.g. the re-asserted
stored option on reconnect) is a no-op: no room scan, no push — the stored
web option is a per-device preference and the server role follows the last
accepted `SetRole`.

## Debug commands (`#ifdef __A3_DEBUG__`)

`Debug.CreateTestRequest`, `Debug.SetRole`, `Debug.Reset`. Each is additionally
gated by the server-side `ace_tacphone_allowDebug` option, like the Map and
Messaging debug commands.

- `Debug.CreateTestRequest` — deterministic test request for the sender:
  description `"Debug test request"`, position kind at the sender's rounded
  position plus the optional `offset: [dx, dy]` (default `[0, 0]`), created
  through the normal `CreateRequest` path.
- `Debug.SetRole` — server-side role setter for the sender, or for `uid` /
  `name` when the server cannot resolve the player (Messaging fake players
  in the live suite).
- `Debug.Reset` — deletes every request's Messenger room, clears the queue,
  roles and counter, then pushes the empty `Logistics.State` snapshot. No
  per-request `Logistics.Request.Remove` is sent: the snapshot replaces each
  page's queue wholesale. A blank `Error` push (`message: ""`) follows, which
  the web module treats as "clear": it dismisses every page's error banner, so
  a reset leaves no test-induced banner behind.

Release builds do not compile these functions.

## External wiring

All done (2026-11-06): `config.cpp`, the root `websource/package.json`
workspace + `build` / `build:debug` / `build:apps(:debug)` +
`test:logistics` / `test:logistics-ui` entries, the `copy-data.mjs` bundle
copy, the `build-all.mjs` / `test-all.mjs` app entries, the
`Logistics` stringtable container (plan section 9) and the Map-side
`pickPosition({ allowMarkers: true })` (plan section 8). The test suite
lives in `websource/ACE_TacPhone_Logistics/test/` (unit tier in
`npm run test:unit`, live protocol suite in `npm run test:logistics`,
stubbed-game UI suite in `npm run test:logistics-ui`).
