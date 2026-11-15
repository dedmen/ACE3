// Attach the mission "EachFrame" poller.  A handler attached at
// display-load time never ticks (the mission event context is not live
// yet), so this is called again from the XEH PreInit hook, which
// force-replaces any stale early handler.  Verified: a handler attached
// after the editor is ready ticks immediately.  CBA fires PreInit
// multiple times, so never re-attach after the preview has started
// (ondone.sqf removes the poller then).
private "_done";
_done = uiNamespace getVariable ["ace3debug_done", false];
if (_done) exitWith
{
    diag_log "[ace3debug] attach: preview already started, not attaching";
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
