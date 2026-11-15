// 3DEN "OnSubmodeChange" callback — logs and retries the preview start.
diag_log "[ace3debug] OnSubmodeChange fired";
call compile preprocessFileLineNumbers 'ace3debug\preview.sqf';
