// Preview-start logic, shared by the initial attempt and the 3DEN event
// handlers (see register.sqf).  Safe to call repeatedly: no-op when the
// preview already runs.
//
// Note: get3DENActionState "MissionPreview" is useless as a readiness
// check - the action has no state and always reports -1.  The draw
// poller (drawpoll.sqf) retries unconditionally instead.
//
// Keep this to constructs the config-expression precompiler accepts
// (it also applies to files spliced in here): bare 'if ... then {}'
// statements only - no 'else if' chains, no 'exitWith'.
if (is3DENPreview) then
{
    diag_log "[ace3debug] preview already running, skipping";
};
if (!is3DENPreview) then
{
    diag_log "[ace3debug] starting mission preview";
    do3DENAction "MissionPreview";
};
