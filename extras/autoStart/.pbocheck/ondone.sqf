// OnMissionPreview - the preview started.  Stop the poller.
diag_log "[ace3debug] mission preview started";
uiNamespace setVariable ["ace3debug_done", true];
private "_idx";
_idx = uiNamespace getVariable ["ace3debug_eachframeIdx", -1];
if (_idx >= 0) then
{
    removeMissionEventHandler ["EachFrame", _idx];
    diag_log "[ace3debug] EachFrame poller removed";
};
