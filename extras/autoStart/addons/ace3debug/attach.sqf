// Attach the mission "EachFrame" poller (eachframe.sqf).  A handler
// attached at display-load time never ticks (the mission event context
// is not live yet), so this is called again from the XEH PreInit hook,
// which force-replaces any stale early handler.  Verified: a handler
// attached after the editor is ready ticks immediately.
//
// Attaches in EVERY mission context: the 3DEN editor world (preview
// retry + host-dialog confirm) AND, in the MP preview, the loaded
// mission (the PreInit hook fires there too).  The mission-context
// copy is required because OnMissionPreview fires before the player
// enters the world, and the lobby state machine's ready-phase
// Continue retry must still tick then.  The preview retry is gated on
// is3DEN and the done flag inside eachframe.sqf, so the mission-
// context copy can never retry do3DENAction.
//
// Ready marker for the launcher.  This hook fires in every mission
// context: the 3DEN editor world AND the loaded preview/MP mission.
// In the 3DEN local-MP preview the mission context is a single listen
// server (PostInit logs isServer=true, hasInterface=true), so the old
// "client mission loaded" (!isServer) marker could never fire and the
// launcher timed out on a healthy run.  The launcher matches the
// "mission ready" line below instead (fires only in a real mission
// context, not the 3DEN editor world).
diag_log format ["[ace3debug] PreInit context: is3DEN=%1, isServer=%2", is3DEN, isServer];
if (!is3DEN) then
{
    diag_log "[ace3debug] mission ready: mission context loaded";
};
// Re-arm the 2 s window in eachframe.sqf for the new handler instance.
uiNamespace setVariable ["ace3debug_armedAt", -1];
private "_old";
_old = uiNamespace getVariable ["ace3debug_eachframeIdx", -1];
if (_old >= 0) then
{
    removeMissionEventHandler ["EachFrame", _old];
    diag_log format ["[ace3debug] attach: removed stale handler #%1", _old];
};
private "_poller";
_poller = compile preprocessFileLineNumbers 'ace3debug\eachframe.sqf';
private "_idx";
_idx = addMissionEventHandler ["EachFrame", _poller];
uiNamespace setVariable ["ace3debug_eachframeIdx", _idx];
diag_log format ["[ace3debug] attach: EachFrame handler #%1 attached", _idx];
