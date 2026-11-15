# Map app — TacPhone App Code Audit

_2026-11-15 · full pass (supersedes the 2026-11-14 light pass) · 26 game-side files (~920 lines) + 76 web source files (~23,600 lines incl. SCSS) + 28 test files (~10,000 lines, audited as behavioral spec), cross-checked against the core framework dispatcher, the interest registry, and the ACE markers event contract_

The 2026-11-14 pass covered leak/hot-path/lifecycle checks only and explicitly
skipped the routing internals, terrain pipeline internals, and GpsHud. This pass
reads every file in scope line-by-line across ten parallel workstreams (SQF,
protocol cross-check, map core + terrain pipeline, routing engine, route
computation, GPS module, marker state, marker UI, and both test suites).
Findings B1–B13 were independently re-verified against the current tree before
publication; B14–B15 are a3ref-verified workstream reports.

Categories: **B** = bug (confirmed defect), **O** = opportunity (performance /
robustness / maintainability), **C** = consistency (protocol drift, doc drift,
dead code).

## 1. Findings

### 1.1 Bugs

**B1 — Cancelled/superseded plan leaves `calculating` set; Calculate button can lock permanently** (verified)
`src/MapGps/GpsRoutes.ts:235-237` sets `calculating = true` and `status = 'analyzing'`, but both cancellation exits return before the reset at :261 (`isCancelled()` at :257-258, `reason === 'cancelled'` at :273-274). A generation bump from `startSharedRoute` (which never clears `calculating`) therefore strands the flag: tap Calculate, then start a shared route, and the panel's Calculate/Recalculate button (`GpsOverlay.tsx:672` `disabled={... || state.calculating}`) stays disabled. Same root cause via `setTerrain` (GpsModule.ts:524-525), which resets `calculating` but not `status`, so a plan started before terrain arrives shows "Analyzing…" forever. Fix: reset both flags at every generation-bump site that does not start a successor plan.

**B2 — Post-arrival auto-clear wipes waypoints added within 10 s of arriving** (verified)
`src/MapGps/GpsNavigation.ts:393-400`: the `arrivalTimer` unconditionally runs `planning = false; clearWaypoints()` after `ARRIVAL_CLEAR_MS`. `addWaypoint` (GpsModule.ts:563-575) and `setPlanning` do not call `navigation.cancelArrivalClear()` (the other four call sites are :596, :685, :708, :904). Arrive, then tap the map to start a new route within 10 s: the new waypoints, planned route and planning mode are all destroyed, and the Arrived badge vanishes. Fix: capture `routeRevision` in `completeArrival` and skip the clear when it changed, or cancel the timer from `addWaypoint`.

**B3 — Follow re-center uses magnitude wrap instead of signed wrap; wrong snap-back across north** (verified)
`src/MapGps/GpsCamera.ts:53-55`: `Math.abs(normalizeDegrees(heading - lastCenterHeading)) > 5`. With `lastCenterHeading = 3`, `heading = 359`, the true difference is 4° but the expression yields `|356|` → re-centers on every fix after the pan-suspension expires — visible jitter when turning across north. Fix: use `normalizeSigned` (already used in `TurnInstructions.ts:22-25`).

**B4 — `sliceLegsFrom` off-by-one at deduped leg boundaries → backwards loop in shared-route repaths** (verified)
`src/MapGps/RouteSplice.ts:31-53`: `buildRouteGeometry` records `legStarts[i]` before adding the leg's points, then dedupes a shared boundary vertex — so the first segment of a deduped leg is attributed to the *previous* leg by `findLegIndex` (:56-66). Trace: legs A=[A0,A1], B=[A1,B1], C=[B1,C1] → `legStarts=[0,2,3]`; the player on flattened segment 1 (geometrically B's first edge) resolves to leg A; `sliceLegsFrom` drops leg A's tail, keeps leg B *whole*, and silently loses `prepend` → result route backtracks B1→A1→B1 (km-scale on road-graph legs). Same defect, smaller form, in `drawRoute`'s ahead-fade (GpsRoutes.ts:496-501). Exact-waypoint cuts (`acceptAdvisor`, GpsModule.ts:855-871) are self-consistent, so Start/accept are unaffected. Fix: when a leg's first point is deduped, record `legStarts[i] = count - 1`.

**B5 — Road-class bias applied backwards — search prefers tracks/trails over main roads** (verified)
`src/MapGps/RoutePlanner.ts:71-85` declares the factors main 0.65 / road 0.7 / track 1.25 / rail 1.4 / trail 1.7 with the comment "lower means the class is preferred", and :995 multiplies: `preferRoads ? speed * roadPreferenceFactor(kind) : speed`. Since cost ∝ 1/speed, the "follow roads" search's effective speeds are trail ≈1.7×base > track 1.25× > main 0.65× — the inverse of the stated intent. The safety net at :592-596 (prefer the unbiased path if it uses >100 m more road within 10 %+60 s) covers most cases but not a genuinely faster trail alternative. Fix: divide by the factor (or invert the table) so main roads get the boosted speed.

**B6 — `RoadNetwork.buildAdjacency` never clears; stale edges accumulate on every plan** (verified)
`src/roads/RoadNetwork.ts:744-758` pushes into `this.adjacency` without clearing it, and `snapToSegment` (:333) rebuilds after a runtime segment split on every plan. The pre-split full-length edges from every previous state stay in the Map forever: unbounded growth across a long panel session, and A* expands the redundant stale edges every search. Routes stay geometrically valid (stale chords are still on-road), so this is a leak + search overhead, not a wrong path. Fix: `this.adjacency.clear()` at the top of `buildAdjacency`.

**B7 — `TerrainGrid.segmentCost` double-counts endpoints; invalidates the "never flatten through forest" invariant** (verified)
`src/routing/TerrainGrid.ts:371-398`: the loop runs `step = 0..steps` (steps+1 iterations) adding `stepDistance / speed` with `stepDistance = distance/steps` — total cost is `distance/speed × (1 + 1/steps)`. A straight grid edge (steps = 2) is inflated ×1.5, a diagonal ×1.33. In `simplifyGridPath` (:357), `originalCost` (sum of inflated grid edges) is ~33–50% above true while the direct-candidate cost is nearly exact, so `directCost <= originalCost * 1.05 + 1e-6` accepts a straight line that is up to ~30–40% slower in reality — exactly the road-detour-through-forest flattening the :343-344 comment says must never happen. Fix: `step < steps`.

**B8 — `SpeedModel.legSpeed`: sub-crawl climb returns a fixed faster speed and skips the surface multiplier** (workstream-verified)
`src/routing/SpeedModel.ts:244-247`: when `vClimb < CRAWL_SPEED` the code returns `CRAWL_SPEED` (0.5) computed *before* `surfaceMultiplier(kind)` at :250. A 2000 kg / 40 kW vehicle off-road at ~0.55 rise/run: vClimb ≈ 0.30 m/s → code returns 0.5 (≈2.7× faster than the force model) and bypasses the ×0.45 off-road factor (true ≈ 0.14). The comment ("not drivable") contradicts the code, and the floor is inconsistent with the `Math.max(1.5, …)`/`Math.max(0.5, …)` floors applied later. Fix: return `CRAWL_SPEED * surfaceMultiplier(kind)` (floor intent) or 0 = blocked (comment intent).

**B9 — The 120 s pick safety timeout never exits pick-mode UI** (verified)
`src/MapPick.ts:77` schedules `settle(null)`, and `settle` (:126-139) only resolves the pending promises — there is no component hook. In `Map.tsx` only `clearPickMode()` (:635-645, called from `settlePick`/`cancelPick`) clears `state.pick`, the crosshair and `pickActive`. After the timeout every caller gets `null`, but the banner stays, the crosshair persists, and — per AGENTS/map.md — all marker interactions remain suspended (taps swallowed at `handlePickTap`). The unit test (test/unit/map-pick.unit.mjs:112-123) only asserts the promise resolves `null`, so it cannot catch this. Fix: observe settle in the component (e.g. `promise.finally(() => { if (!this.mapPick.isActive()) this.clearPickMode(); })`) or give `MapPick` an `onSettle` option.

**B10 — Polyline edit: cancel during an in-flight save loses the cancel** (verified)
`src/MapMarkers/MarkerModule.ts:684-707`: `savePolylineEdit` applies the edited geometry locally immediately (`updatePolylineData` → `applyPolylineGeometry`) and sets `edit.saving = true`, but `cancelPolylineEdit` (:701-707) does not check `saving` — Escape drops the session and `setEditingPolyline(null)` while the request is in flight. The game echo then arrives with `isEditing === false` and re-applies the edited geometry: "cancel" still lands the moved polyline and `edit.original` is never restored. Fix: refuse/defer cancel while `saving`; on settle, restore the original if the user cancelled.

**B11 — `gameInfo.whenReady()` is the one readiness input with no timeout** (workstream-verified)
`src/MapMarkers/MarkerLayers.ts:390-448`: all three game requests use `requestWithTimeout` (10 s) explicitly so `focusMarker()` "must never hang" (:432), but the `gameInfoPromise` in the `Promise.all` has none. If the host's `gameInfo` never settles, channel layers are never configured, `whenMarkersLoaded` stays pending (focusMarker hangs), and every `Marker.Upsert` piles into the 512-cap queue (:1660-1673). Fix: wrap in the same timeout with the existing singleplayer-fallback shape.

**B12 — Cross-panel radio-group collision in the layer switcher** (workstream-verified)
`src/MapMarkers/MarkerLayerSwitcherSection.tsx:61`: `name="marker-active-channel"` is hardcoded and document-global. Multiple Map panels (or Map + GPS read-only view) stay mounted simultaneously (every tabset tab stays mounted per AGENTS.md), so all panels' radios form one group: clicking a channel radio in panel A silently unchecks panel B's active-channel radio, which then shows no active channel until an unrelated store update re-renders it. Fix: make the name instance-unique.

**B13 — Edit dialog silently swaps marker type when the type list arrives late** (workstream-verified)
`src/MapMarkers/MarkerCreateDialog.tsx:290-294`: in edit mode, if `GetMarkerTypes` resolves after the dialog opened, `selectedType` jumps to `markerTypes[0].className` without user input; `submit()` always sends `type`, so the marker's type changes without consent. Fix: in edit mode keep the initial value (disable submit until the list contains it); apply the fallback only in create mode.

**B14 — GPS vehicle-change handlers are lost after a player respawn** (a3ref-verified)
`functions/fnc_onInterestChanged.sqf:86-93`: `GetInMan`/`GetOutMan` handlers are installed only at interest activation and removed on deactivation. A mid-mission respawn replaces `player` with a new object while the interest stays held, so no `GPS.VehicleChanged` push ever fires again until the panel cycles the interest, and the old EHs linger on the corpse object — travel-mode updates silently stop after death. Fix: re-arm via a `Respawn`/`Init` mission handler while the GPS interest is held, or detect the `player` change inside `onGpsUpdate`.

_**Note (raised, rejected):** an originally raised finding — `createMarkerLocal` return unchecked, phantom `Marker.Upsert` on a name collision — was rejected: marker names are unique, so the collision path is unreachable. Not counted._

_**Note (raised, rejected):** an originally raised finding — no client gating on `CreateMarker`/`DeleteMarker`, reachable from any relay/LAN client — was rejected as a finding: TacPhone has no client-to-client security boundary by design; every relay/LAN client has the same full permissions as the in-game browser (same trust model as the logistics relay, see PLAN_LOGISTICS.md). Not counted._

**B15 — `exitWith` inside `if` fails to break the angle scan (debug-only)** (a3ref-verified)
`functions/debug/fnc_debugPrepareBoat.sqf:44-47`: per the verified semantics (AGENTS/sqf.md:144-148), the `exitWith` exits only the `if`, so the `for "_angle"` loop keeps running and every further deep-water candidate re-runs the full 6-ring × 36-angle shore search, overwriting `_water`/`_shore` until the next radius step's guard stops it — the boat ends up at the *last* matching angle, not the first, with tens of thousands of extra `surfaceIsWater`/`getTerrainHeight` calls in the worst case. Same pattern (minor) at :38. Fix: set a flag inside and `exitWith` at the for-body level.

### 1.2 Opportunities

GPS / route computation:
- **O1** — O(n) full-polyline rescans on every GPS fix: `pointAtDistance` recomputes `polylineLength` per call (TurnInstructions.ts:70, 111-128); `nextRoadJunction` does up to 32 `nextManeuver` passes (JunctionTracker.ts:62-87) → ~2×10⁴ pointAtDistance calls/fix worst case, driven at 10–30 Hz from `GpsNavigation.updateNavigation` (:40-107). Fix: prefix-sum length cache per `routeGeometry`.
- **O2** — `drawRoute()` fully rebuilds route features every 5 m travelled (GpsNavigation.ts:69-71; GpsRoutes.ts:467-522; `sliceLegsFrom` spreads every leg) — at 20 m/s that is a rebuild ~4–5×/s. Coarsen the threshold (e.g. 20 m) or diff the affected segment.
- **O3** — Shared-route repaths are not serialized: the shared branch of `recalculateRemaining` reads `generation` without bumping it and never sets `calculating` (GpsRoutes.ts:283-338); two overlapping connector plans can double-apply (frequency capped by the 15 s repath cooldown).
- **O4** — Two full road-graph A* per non-fastest ground plan (biased then unbiased, RoutePlanner.ts:561-597) with `ROAD_MAX_SNAP_M = 8000` (:69) allowing multi-km connectors.
- **O5** — `encodeSharedRoute` can never share walk/water-heavy routes: `baseTolerance` is 0 for those modes (SharedRoute.ts:388-399), so all 8 simplification passes are identical and a >6000-point route fails `too-large` regardless of char budget. Fix: resample by distance for oversized walk/water legs.
- **O6** — Advisor prompt goes stale if the player passes its target waypoint: `evaluate` keeps a shown prompt until answered (TransportModeAdvisor.ts:179-182); `acceptAdvisor` (GpsModule.ts:855-871) then cuts at a waypoint now behind the player and the new route backtracks to it.
- **O7** — Lazy road-network build is check-then-build with no shared promise (RoutePlanner.ts:861-878): concurrent plans each re-parse the roads SVG.
- **O8** — Manual `setMode` on a planned-but-not-navigating route never re-plans (GpsModule.ts:547-549 recalculates only `if (this.activeRoute && this.navigating)`), inconsistent with `applyTravelMode` (:1103).
- **O9** — Pending shared-route preview lost on StrictMode remount (dev-only; GpsOverlay.tsx:302-306 consumes the ref in a layout effect that runs on the first, destroyed mount).

Map core / terrain pipeline:
- **O10** — `effectiveTileCacheSize()` floors at 8 tiles (MapOptions.ts:105-111); the desktop default (512 px, option 48) ends up with 8, while a 1920×1080 viewport shows ~12–16 tiles/layer → constant cache churn. A viewport-aware floor would cut repeated raster work.
- **O11** — `TerrainMasks.buildRasters` checks `isCancelled()` after every `rasterFor` except the final one (TerrainMasks.ts:341-347); a cancelled route still pays the last decode + rasterize.
- **O12** — `attachRenderer` re-registers on every registry change if `registerObjectRenderer` returns falsy (MessagingBridge.ts:326-337; GPS twin :549-558): key the idempotency guard on `registeredApi === api` alone.
- **O13** — Fly-to/pick highlight accent is computed once in `componentDidMount` (Map.tsx:71-84); a mid-session display-variant switch leaves a stale-colored glow until remount (the comment says it follows the variant).
- **O14** — StrictMode double-mount fires two concurrent `LoadGameTerrain` requests (Map.tsx:308-335); the stale response is discarded correctly, but the game side gets two requests on every dev mount.

Routing engine:
- **O15** — `RoadNetwork` construction is O(E²) endpoint pairing + O(E·S) endpoint projections with no spatial index (RoadNetwork.ts:607-682); `nearestNode` is a linear scan (:169-183) although `nodeGrid` exists. Map-load/first-plan latency, worst on large road layers.
- **O16** — Per-edge `cellCenter` array allocation in the grid A* hot loop (TerrainGrid.ts:172-176, called at :236, :250, :257-258, :290) — ~11 small arrays per expanded cell; compute inline or reuse a scratch.
- **O17** — `RoadSvgParser.number()` returns 0 for a missing token (RoadSvgParser.ts:44-48): a truncated SVG command yields a vertex at world origin and a phantom road to the map corner. Bail out of the subpath instead.

Markers:
- **O18** — `knownMarkerNames` grows unbounded and is never pruned on `Marker.Delete` (MarkerNotifications.ts:24, 112-117): long sessions with marker churn grow it forever, and a recreated marker reusing a name gets no toast.
- **O19** — O(n) registry scans on the pointer-move hot path: `getRegisteredFeature`/`isRegisteredFeature`/`findRegistryKey` linear-scan the `channel:name` registry (MarkerLayers.ts:1068-1088, 1867-1875) → O(features × markers) per move with hundreds of markers. Add a bare-name index.
- **O20** — Per-frame allocation churn in the marker style function: `new Text(...)` per labeled marker and `baseStyle.clone()` per shadowed/elevated marker on every render (MarkerStyles.ts:138, 165-191). Cache and mutate.
- **O21** — `console.warn` per upsert for unknown marker types (MarkerStyles.ts:243-246); release builds keep `warn` → sustained console spam. Warn once per type.
- **O22** — `tintedIconCache` of full PNG data URLs is unbounded and survives dialog close (MarkerCreateDialog.tsx:57, 119); dragging the custom color input adds an entry per intermediate color. Cap (LRU ~64) or clear on unmount — the OL icon cache next door is capped at 256 for exactly this reason (MarkerStyles.ts:21).
- **O23** — `terrainHeightCache` is unbounded (TerrainHeightApi.ts:71) and `resolveTerrainHeights` has no in-flight request dedupe (:92-128) — concurrent callers refetch the same position.
- **O24** — `MarkerChannelStore.attach` silently overwrites a live module with no guard (MarkerChannelStore.ts:40-52); unreachable today, fragile if the store is ever shared.
- **O25** — Icon-marker create failure is console-only (MarkerModule.ts:458-460): the dialog closes and nothing happens, while a failed polyline save does notify (:735-745).
- **O26** — `GetMarkerTypes` failure leaves the swatch grid empty and the preview fallback white while the game renders `Default` black (MarkerModule.ts:574-576, 811-840) — preview and actual marker diverge with no user signal.
- **O27** — Dialog Escape is suppressed by a `SelectMenu` opened in *another* panel (MarkerCreateDialog.tsx:330-331 queries `document`); scope the query to the dialog's subtree.
- **O28** — `colorAlpha` does not clamp (MarkerStyles.ts:29-33) unlike its twin in PolylineDrawing.ts:140-152; and `applyAlphaToColor` (:63-74) silently drops the alpha factor for named CSS colors, so an inactive-channel polyline with a named color would lose its dimming.
- **O29** — `setPoints` silently drops non-finite coordinates (PolylineDrawing.ts:274-281); callers assume 1:1 with the loaded vertex count, so a partially-invalid payload would save fewer vertices than displayed. Reject or log the drop.

### 1.3 Consistency

Protocol drift (SQF ↔ web — no breaking drift found; all names/types/orderings agree, see §2):
- **C1** — `vehicleClass` is sent in both travel-mode surfaces (`fnc_getPlayerTravelMode.sqf:46`) but never read by production web (`VehicleChange.ts:68-76`); declared only in `TravelModeState` (GpsTypes.ts:40) with zero other references. Wire it in or drop it.
- **C2** — `engineHealth` is parsed by web (`VehicleChange.ts:36`, typed at RouteTypes.ts:27) but never sent by `fnc_getVehiclePerformance.sqf:26-45`. Phantom protocol field.
- **C3** — `GetMarkerChannels` entry `custom` is sent (`fnc_getMarkerChannels.sqf:21,44`), parsed (Channels.ts:22,83), never consumed.
- **C4** — `GetMarkerTypes` brush `texture`/`drawBorder` stored (MarkerLayers.ts:710-711) but brush rendering is explicitly deferred (:1709-1711) and nothing else reads them.
- **C5** — Marker-tuple `brush` is sent (`fnc_assembleMarkerInfo.sqf:30`) and stored (MarkerLayers.ts:1718) but `createFeatureStyle` ignores it (MarkerStyles.ts:200) — the field rides every push for every marker.
- **C6** — `getTerrainHeight` is the one camelCase command; every other Map command is PascalCase (`fnc_processBrowserRequest.sqf:42` vs :28, :39, :48, :52, :83, :94, :146; web mirrors the mismatch).
- **C7** — Size encoding differs by surface: `"w,h"` string in the marker tuple (`fnc_assembleMarkerInfo.sqf:31`, parsed at MarkerLayers.ts:185-201) vs number in `GetMarkerTypes` (`fnc_processBrowserRequest.sqf:101`).
- **C8** — `DeleteMarker`'s `{deleted, name}` reply (`fnc_processBrowserRequest.sqf:154-158`) and `SetGpsUpdateRate`'s `{ok, hz}` reply (`fnc_setGpsUpdateRate.sqf:39`) are built but never read (MarkerApi.ts:171-175; GpsUpdateRateSync.ts:21-27 — fire-and-forget by design; the SQF docblock still presents the reply as contract).

SQF:
- **C9** — `requiredAddons[] = {}` in `config.cpp:9` deviates from sibling apps (e.g. radio declares `ace_tacphone` + `skipWhenMissingDependencies`); the map sub-addon depends on `ace_tacphone` at runtime and silently does nothing loaded alone.
- **C10** — `ace_tacphone_apps.hpp:4` keeps a ship icon (`c_ship.paa`) marked "Reserved"; the core still reads it into `AppInfo` — dead, misleading config.
- **C11** — All 12 function docblocks use the wrong case in the example call (`ace_tacphone_map_fnc_…` vs the actual `ace_tacphone_Map_fnc_…` global) — copy-pasted examples fail; SQF names are case-sensitive.
- **C12** — Stale `//#TODO hashmap syntax once HEMTT supports it` (fnc_onMarkerCreated.sqf:35, fnc_onMarkerPosChanged.sqf:32, fnc_onMarkerDeleted.sqf:24) while `createHashMapFromArray` is already used freely (fnc_createMarker.sqf:89).
- **C13** — Interest CBA handlers registered in `XEH_postInit.sqf:5-10` without stored ids / re-init guard; harmless today (idempotent transitions), doubles if the registry ever survives a repeated postInit.

Web core:
- **C14** — `MAP_SERVICE_NAME = 'map'` (MessagingBridge.ts:37) duplicates `MAP_SERVICE` exported by api.ts:261 in the same file's import set; import instead so the literals can't drift.
- **C15** — `PriorityMap.ts:22-27` comment claims the OL rank "stays around -1e6..1e6"; the actual OL 10.9 formula yields ~±3e5 for this map. `RANK_WEIGHT = 1e8` still dominates; the comment just overstates the margin.
- **C16** — `TerrainLayerPipeline.ts:193-196` doc says the view is left untouched, but the only caller (`Map.rebuildTerrainLayers`, Map.tsx:1053-1064) always replaces it first.
- **C17** — `main.tsx:31-33`: the `localization.onDidChange` subscription is never unsubscribed; harmless in production, re-registers the stale schema on every dev HMR re-init.

Routing engine:
- **C18** — Snap cap is 60 m in code (RoadNetwork.ts:42 `MAX_SNAP_M`) but "capped at 30 m" in AGENTS/map.md:267.
- **C19** — Follow zoom is 20 s in code (FollowZoom.ts:10) but "one minute of travel ahead" in AGENTS/map.md:260 and the GpsCamera.ts:95-98 doc.
- **C20** — `classifyRoad(paint, width)` is called with `strokeWidth` while the stored width is `strokeWidth - 2` (RoadSvgParser.ts:132, 200-201); the 10/6/3 thresholds sit 2 m off the stored-width semantics.
- **C21** — `debugGridFor(request, context)` ignores `request` entirely (`void request;`, TerrainGrid.ts:650-654).
- **C22** — Junction identity keys round both coords to whole metres (JunctionTracker.ts:36-38): two distinct junction nodes <1 m apart share a key; the "stable node position" guarantee in the header comment is slightly overstated.

Route computation:
- **C23** — Stale comment: "planRoute keeps the previous route on failure" (GpsRoutes.ts:356-357) — it clears it (:275-278).
- **C24** — Any non-cancelled planner failure is labelled `no-path`, including real exceptions (GpsRoutes.ts:276; RoutePlanner.ts:490 returns `reason: 'error'`).
- **C25** — Shared-route payload `distance`/`eta` are the *pre-simplification* totals while legs are simplified per pass (SharedRoute.ts:450-451): preview distance can exceed the geometry a receiver actually starts.
- **C26** — AGENTS/map.md says road snapping "within 500 m / up to 1500 m" and "biases road edges by 0.8×"; code has `ROAD_MAX_SNAP_M = 8000` and factors 0.65–1.7 (and inverted — see B5).

GPS UI:
- **C27** — `GpsModule.stale` is never set true (only false assignments at :692, :837, GpsRoutes.ts:268, :332, :461), yet the "route is stale" warning renders on it (GpsHud.tsx:111, GpsOverlay.tsx:627-631) and is part of the test-hook contract (MapTestHooks.ts:213). Dead UI.
- **C28** — ~160 lines of dead CSS in GpsStyles.module.scss (`.compass*`, `.playerMarker`, `.routeArrow`, `.modeToggle/.modeRow/.modeButton*` — leftovers from a DOM-drawn player marker and mode row that moved to the options panel).
- **C29** — "dev-only" comment overstates the gate (GpsModule.ts:384-386): `installMapTestHooks` also installs on release builds when `gameInfo.debug` is true (MapTestHooks.ts:526-547).
- **C30** — Voice guidance strings are hardcoded English (GpsNavigation.ts:321-322, :363); the "test implementation" comment notwithstanding, they ship.

Markers:
- **C31** — Channel-layer `change:visible` listeners are never unlistened on layer removal (MarkerLayers.ts:593 vs :611-613, where `destroy()` does clear); orphaned closure until GC — a lifecycle-symmetry gap in the module that owns every other teardown.
- **C32** — `MarkerLayers.clearAll()` has zero call sites (MarkerLayers.ts:1925-1944).
- **C33** — AGENTS/map.md:163-164 claims edits send only changed fields; the dialog always sends label/type/color/dir/size (MarkerCreateDialog.tsx:455-463, MarkerOverlay.tsx:294-302).
- **C34** — Dead statements: `markerRegistry.set` of the just-read value (MarkerLayers.ts:637), `channel ?? 0` with a non-nullable `channel` (:1057), and an empty `if (shadow) {}` block (MarkerStyles.ts:154-158).

Marker UI:
- **C35** — `Total ${formatDistance(total)}` hardcoded in English (PolylineMeasurements.ts:439); no stringtable key exists.
- **C36** — `customColor` prop is dead in both call sites (ColorSwatchPicker.tsx:35-36, 88-90; passed as `parseMarkerColor(selectedColor) ? selectedColor : undefined` at MarkerCreateDialog.tsx:580 and PolylineDrawControls.tsx:136): the "reopens on the last custom color" behavior never happens.
- **C37** — `DEGREES_PER_HALF_TURN = 360` (PolylineMeasurements.ts:63) is a full circle; the duplicate `DEGREES_PER_CIRCLE = 360` at :45 should be reused.
- **C38** — `parsePreviewColor` falls back to white for named CSS colors (MarkerCreateDialog.tsx:60-77) while `isBlackMarkerColor` explicitly anticipates `'black'` (MarkerColorUtils.ts:134) — preview shows white, map renders black.
- **C39** — `var` + loose `!=` + commented-out `var textSize` in an otherwise `const/let`/`===` codebase (MarkerStyles.ts:122-138).

Tests:
- **C40** — `gps-payload.unit.mjs` action contract is self-referential: it builds `action` from its own literal and asserts it against itself (test/unit/gps-payload.unit.mjs:34-39, 110-129); the real producer `buildGpsRouteChatObject` (MessagingBridge.ts:473-502) is never imported, so a bridge rename would still pass. The header's "fails loudly" claim is false for the action.
- **C41** — test/README.md drift: the "adding a unit module" section prescribes the obsolete `loadAppModule` import pattern (every unit test imports `.ts` directly; the only `loadAppModule` use is a deliberate negative test); the layout tree omits `map-pick.unit.mjs` and `gps-update-rate-sync.unit.mjs` (both registered in the runner); it references the nonexistent `TERRAIN_TILE_SIZE` (real: `DEFAULT_TERRAIN_TILE_SIZE_MOBILE/DESKTOP`); the scenario table omits `gps-water-interactive`.
- **C42** — Unit coverage gaps (seams exist): `VehicleChangeDebouncer` (VehicleChange.ts:80-135 — its header says it is injectable "so the unit tier can test it"), `GpsFormat.formatSpeed`/`formatDuration`, `TerrainHeights` async sampling (`sample` chunking, `cache: false`, `sampleGrid`, `samplePath`), `RoadNetwork.snapToSegment`, and the junction/transition limit paths (JunctionTracker.ts:62 32-bend bound; TurnInstructions.ts:202-204 over-range nulls).

## 2. Protocol cross-check

Every command name, request field, response field, tuple position, and numeric
unit was checked on both sides; **no breaking drift found**.

| Surface | SQF side | Web side | Status |
|---|---|---|---|
| Envelope `a`/`c` | fnc_onGpsUpdate.sqf:27-28 | MessageRouter routes on `c` | ✓ |
| Interests `ACE_TacPhone_Map.gps`/`.markers` | script_component.hpp:9,12 | GpsModule.ts:100, MarkerOverlay.tsx:38 | ✓ |
| `GetAllMarkers` 12-tuple | fnc_assembleMarkerInfo.sqf:21-34 | MarkerLayers.ts:44, 1732 | ✓ |
| `GetMarkerChannels` | fnc_getMarkerChannels.sqf:21,44 | Channels.ts:70-87 | ✓ (C3) |
| `getTerrainHeight` | fnc_processBrowserRequest.sqf:45-46 | TerrainHeightApi.ts:48-63 | ✓ (C6) |
| `GetPlayerTravelMode` + 16-key `performance` | fnc_getPlayerTravelMode.sqf:26-48 | GpsModule.ts:1053-1065, VehicleChange.ts | ✓ (C1, C2) |
| `SetGpsUpdateRate` | fnc_setGpsUpdateRate.sqf:25-39 | GpsUpdateRateSync.ts:21-27 | ✓ (C8) |
| `CreateMarker` / `DeleteMarker` | fnc_processBrowserRequest.sqf:83-93, 146-159 | MarkerApi.ts:10-72, 170-175 | ✓ (C7, C8) |
| `GetMarkerTypes` | fnc_processBrowserRequest.sqf:94-145 | MarkerLayers.ts:686-713 | ✓ (C4) |
| `GPS.Update` push | fnc_onGpsUpdate.sqf:29-33 | GpsModule.ts:1126-1152 | ✓ |
| `GPS.VehicleChanged` push | fnc_onGpsVehicleChanged.sqf:31-33 | GpsModule.ts:362-364, VehicleChange.ts | ✓ (C1) |
| `Marker.Upsert` / `Marker.Delete` pushes | fnc_onMarker*.sqf | MarkerLayers.ts:378, 381 | ✓ (C5) |

Units all consistent: metres (world coords; `getTerrainHeight` m MSL),
`speed` km/h with web fallback `speed/3.6` (cross-checked in
gps-protocol.test.mjs:244-246), `velocity` m/s, azimuth degrees
clockwise from north on both sides (`getDir`/`getCameraViewDirection` ↔
`atan2(vx, vy)` + 0–360 slider normalization), `hz` clamped to {10, 30} on
the web and 1–60 on the game, alpha 0..1 both sides.

## 3. Verified clean

Explicitly checked, nothing found:

- **A\*** (AStar.ts): MinHeap push/pop, lazy deletion via `closed` set, goal test on pop, admissible heuristic in every mode, `null` on unreachable/cancelled/cap, non-finite/negative edge costs skipped.
- **TerrainGrid**: row/col indexing and edge bounds (no wraparound), diagonal corner-cutting, start==goal, cancellation bounded every 1024 expansions; penalty direction multiplies speed correctly.
- **Bearing/leg math**: `normalizeSigned` wraps correctly; `pointAtDistance` clamps and hits endpoints; `legStartDistances`/`legIndexAtDistance`/`findLegIndexForSegment` mutually consistent; no division-by-zero or NaN reaching the HUD.
- **State machines**: `JunctionTracker` (pending replace/suppress, taken-set, along jumps) and `DeviationTracker` (timer start/stop, monotonic counter, repath cooldown) — no stuck states; `WaterCorridor` run-index invariants and island/end-in-water guards; `TerrainHeights` bilinear consistency, NaN→null, LRU eviction.
- **Cancellation**: generation tokens threaded into rasters, height sampling and A*; `plan()` never throws; shared-route decode validates version/finiteness/bounds/6000-pt cap.
- **PriorityMap direction**: verified against the installed OpenLayers 10.9 tile queue (min-heap; lower priority dequeues first) — terrain at rank 0 correctly wins; tile blob URLs revoked on both `onload` and `onerror`; pipeline `epoch`/`disposed` checks stop stale-generation decodes.
- **Lifecycle symmetry**: `Map.tsx` (every mount resource has a paired cleanup; `terrainLoadToken` invalidates in-flight terrain), `GpsModule` (all 6 map listeners + 6 DOM listeners + 4 timers + interest + renderer refcount released), `MarkerModule` (10 registrations removed, idempotent `destroyed` flag), `MarkerLayers` (promises always settle including on destroy; upsert queue bounded at 512; registry keyed `channel:name` survives create/move/delete/recreate without duplicates; channel visibility state machine incl. always-visible channels 0/1/3/5).
- **StrictMode idempotency**: app loading, interest acquire/release refcounted, test-hook registration identity-guarded, `theme.palette()` frozen.
- **SQF**: all five push paths early-out on `getInterestClients` before assembly; EH add/remove symmetry with stored ids; GPS rate gate 1–60 Hz with persisted interval; a3ref-verified semantics (`createMarkerLocal` 4-arg + collision → `""`, `deleteMarker` global, `radioChannelInfo` fields, `channelEnabled[2]`); `lint_sqf` on every reconstructed function body: 0 errors; ACE markers event payloads (`ace_markers_markerPlaced`, `ace_markers_setMarkerPosLocal`) match the `params` used; custom channel ranges 6–15/26–65 correct; 256-char text cap.
- **Test suites**: all eight GPS unit files re-derived against source (every threshold, formula, constant and edge case consistent); marker/polyline/terrain unit assertions and browser-scenario selectors/testids statically verified against current source; no test asserts behavior the source no longer has.

## 4. Out of scope

- `data/ace_tacphone_map.js` gzip bundle and web `node_modules`/`dist` — generated artifacts.
- Core framework files (`addons/tacphone/functions/*`, root `XEH_postInit.sqf`) — read for the dispatch/interest cross-check only.
- Live suites requiring a running game: `gps-interactive`, `gps-water-interactive` (human in a vehicle), the Playwright marker/polyline/map browser scenarios, and `benchmark/` (opt-in). Their protocol surface and debug-hook shape were checked statically and are current.
- Whether the relay host coalesces the duplicate StrictMode `LoadGameTerrain` (governs O14's real impact).
- Whether `GetMarkerTypes`/`CfgMarkerColors` can actually produce named CSS colors (bounds C38/O28).

## 5. Audit log

- **2026-11-15** — Full pass. Ten parallel workstreams: SQF game side (a3ref-verified), protocol cross-check, map core + terrain pipeline, routing engine, route computation core, GPS module, marker state, marker UI, GPS test suite, marker test suite. Result: 15 B, 29 O, 42 C. Findings B1–B13 independently re-verified by the lead against the current tree; B14–B15 are a3ref-verified workstream reports. Two raised findings were rejected and are noted, not counted: no client gating on marker-mutating commands (TacPhone has no client-to-client security boundary by design) and the `createMarkerLocal` name-collision path (marker names are unique). The 2026-11-14 light pass (leak/hot-path/lifecycle only) is superseded.
