// OnMissionPreview - the preview (server side) started.  Set the done
// flag: the preview retry in eachframe.sqf stops (it is also gated on
// is3DEN, so the mission-context copy never retries it).
//
// Do NOT remove the handler here: in the MP preview the mission loads
// into a new context, attach.sqf re-attaches the poller there, and its
// lobby state machine still has to press the ready-phase Continue
// button (idc 1 on display 70) for the player to enter the world -
// that happens minutes AFTER OnMissionPreview (observed: preview
// started 17:11:02, player entered the world after the Continue
// press).  The machine stops itself (phase 5) once display 70 closes.
diag_log "[ace3debug] mission preview started";
uiNamespace setVariable ["ace3debug_done", true];
