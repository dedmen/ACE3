// 3DEN "OnModeChange" callback — logs and retries the preview start.
// (The editor switches modes when the scenario/workspace becomes ready,
// which is when the MissionPreview action becomes available.)
diag_log "[ace3debug] OnModeChange fired";
call compile preprocessFileLineNumbers 'ace3debug\preview.sqf';
