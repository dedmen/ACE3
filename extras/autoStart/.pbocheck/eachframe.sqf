// Mission "EachFrame" handler (code object, attached by attach.sqf).
// Ticks every engine frame in 3DEN where the SQF scheduler does not run.
//
// Arms for 2 s after its first tick before the first preview attempt -
// starting the preview earlier races the editor's own init and freezes
// the preview mission boot.  attach.sqf re-arms on every re-attach.
//
// Retries the preview action every 0.5 s (diag_tickTime) until it
// succeeds: "MissionPreviewMP" when the game was started with
// -preprocDefine=CMD__ACE3DEBUG_MP (multiplayer preview, local dedicated
// server), otherwise "MissionPreview".  ondone.sqf (OnMissionPreview)
// sets the done flag and removes the handler.
private "_t";
_t = (uiNamespace getVariable ["ace3debug_ticks", 0]) + 1;
uiNamespace setVariable ["ace3debug_ticks", _t];
if (_t <= 3) then
{
    diag_log format ["[ace3debug] eachframe: tick %1", _t];
};
private "_done";
_done = uiNamespace getVariable ["ace3debug_done", false];
if (_done) exitWith
{
    // preview started; ondone.sqf removes this handler
};
private "_armedAt";
_armedAt = uiNamespace getVariable ["ace3debug_armedAt", -1];
if (_armedAt < 0) then
{
    uiNamespace setVariable ["ace3debug_armedAt", diag_tickTime + 2];
    diag_log "[ace3debug] eachframe: arming, first attempt in 2 s";
};
if (diag_tickTime < uiNamespace getVariable ["ace3debug_armedAt", 0]) exitWith
{
    // still in the arming window
};
private "_now";
_now = diag_tickTime;
if (_now >= uiNamespace getVariable ["ace3debug_next", 0]) then
{
    uiNamespace setVariable ["ace3debug_next", _now + 0.5];
    private "_a";
    _a = (uiNamespace getVariable ["ace3debug_attempts", 0]) + 1;
    uiNamespace setVariable ["ace3debug_attempts", _a];
    // chosen by the -preprocDefine=CMD__ACE3DEBUG_MP startup parameter
    // (see tools/arma_launch.py --mp)
    #ifdef CMD__ACE3DEBUG_MP
    private "_action";
    _action = "MissionPreviewMP";
    #else
    private "_action";
    _action = "MissionPreview";
    #endif
    if (_a <= 3) then
    {
        diag_log format ["[ace3debug] eachframe: attempt %1, is3DENPreview=%2, action=%3", _a, is3DENPreview, _action];
    };
    if (!is3DENPreview) then
    {
        do3DENAction _action;
    };
};
