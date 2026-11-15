// Called synchronously from config.cpp (Cfg3DEN init and/or the
// Display3DEN display-load hook).  Idempotent: the full registration
// runs only once per editor session, and only once the mission world is
// loaded (init can fire before that; the display-load hook covers it).
//
// The SQF scheduler does not run in the editor, but mission event
// handlers do tick: the mission "EachFrame" handler is the "timer" that
// retries the preview start.  It must be a compiled code object - a
// string body never ticks in 3DEN (eachframe.sqf is compiled here).
private "_registered";
_registered = uiNamespace getVariable ["ace3debug_registered", false];
if (_registered) then
{
    diag_log "[ace3debug] register: already registered, skipping";
};
if (!_registered && worldName != "") then
{
    uiNamespace setVariable ["ace3debug_registered", true];
    diag_log format ["[ace3debug] registering 3DEN event handlers (world=%1)", worldName];
    private "_preview";
    _preview = compile preprocessFileLineNumbers 'ace3debug\preview.sqf';
    add3DENEventHandler ['OnMissionLoad', _preview];
    add3DENEventHandler ['OnWorkspacePartSwitch', _preview];
    add3DENEventHandler ['OnModeChange', compile preprocessFileLineNumbers 'ace3debug\modechange.sqf'];
    add3DENEventHandler ['OnSubmodeChange', compile preprocessFileLineNumbers 'ace3debug\submode.sqf'];
    add3DENEventHandler ['OnMissionPreview', compile preprocessFileLineNumbers 'ace3debug\ondone.sqf'];
    call compile preprocessFileLineNumbers 'ace3debug\attach.sqf';
};
if (!_registered && worldName == "") then
{
    diag_log "[ace3debug] register: world not loaded yet, deferring to next hook";
};
