// Mission "EachFrame" handler (code object, attached by attach.sqf).
// Ticks every engine frame in 3DEN where the SQF scheduler does not run.
// No spawn/sleep in here: all timing is diag_tickTime, all state is
// uiNamespace.
//
// Two jobs:
//
// 1. Preview retry (3DEN editor world only, gated on is3DEN): arms for
//    2 s after its first tick (starting earlier races the editor init),
//    then retries do3DENAction "MissionPreview" - "MissionPreviewMP"
//    with -preprocDefine=CMD__ACE3DEBUG_MP - every 0.5 s until
//    is3DENPreview.  The MP action first opens the host-server dialog
//    (display3DENHostSettings, idd 132), which this handler confirms
//    with its OK button (idc 1) one tick after it opens.  ondone.sqf
//    (OnMissionPreview) sets the done flag, which stops the retry.
//
// 2. MP lobby state machine (hostConfirmed): display 70
//    (RscDisplayMultiplayerSetup) is the role lobby.  Role phase:
//    role list CA_ValueRoles (idc 109), then OK (idc 1) once enabled -
//    LOCK is never pressed, OK alone starts the mission.
//    After role confirmation the engine opens the briefing as its OWN
//    display (52) with CONTINUE at idc 1; display 70 LINGERS frozen on
//    the role screen behind it (its idc 1 is still the role OK - a
//    no-op once confirmed).  The server may still be loading its
//    mission for a few minutes in between, so phase 3 retries every
//    1 s: 70's idc 1 while the briefing is not up yet, then the
//    briefing's CONTINUE.  World-entry signal is getClientState
//    reaching "BRIEFING READ" (briefing closed, mission playable);
//    displays 52 AND 70 both linger frozen in the world, so no
//    display close is a done signal, and alive/weapon/pos are
//    identical in both states.  A run that is stuck reaches the
//    terminal instead - at role+360 s still on the briefing, or 30 s
//    after role select if the OK control never appeared - which logs a
//    diagnostic line (reason, client state, raw alive/weapon/pos) that
//    classifies the run in the RPT.  Runs in every
//    context the handler is attached to - the 3DEN editor world AND,
//    after the mission loads, the mission context (attach.sqf
//    re-attaches there via the PreInit hook) - because OnMissionPreview
//    fires before the player enters the world, and only the mission-
//    context copy is guaranteed to still tick then.  All state is
//    uiNamespace, so the phase survives the context switch.
//
//    A 30 s heartbeat logs while the machine is active so the RPT
//    shows this handler is alive during the lobby.
private "_tkKey";
_tkKey = "ace3debug_firstTick3den";
if (!is3DEN) then
{
    _tkKey = "ace3debug_firstTickMission";
};
if (!(uiNamespace getVariable [_tkKey, false])) then
{
    uiNamespace setVariable [_tkKey, true];
    diag_log format ["[ace3debug] eachframe: first tick (is3DEN=%1, isServer=%2)", is3DEN, isServer];
};
private "_armedAt";
_armedAt = uiNamespace getVariable ["ace3debug_armedAt", -1];
if (_armedAt < 0) then
{
    uiNamespace setVariable ["ace3debug_armedAt", diag_tickTime + 2];
    diag_log "[ace3debug] eachframe: arming, first attempt in 2 s";
};
if (diag_tickTime < _armedAt) exitWith
{
    // still in the arming window
};
private "_hostConfirmed";
_hostConfirmed = uiNamespace getVariable ["ace3debug_hostConfirmed", false];
//
// 2. MP lobby state machine.
#ifdef CMD__ACE3DEBUG_MP
private "_ph";
_ph = uiNamespace getVariable ["ace3debug_lobbyPhase", 0];
// terminal: stop the machine (phase 6) and log one diagnostic line
// that classifies the run in the RPT; the argument is the reason.
private "_terminal";
_terminal =
{
    uiNamespace setVariable ["ace3debug_lobbyPhase", 6];
    diag_log format ["[ace3debug] lobby: terminal: %1 state=%2 alive=%3 weapon=%4 pos=[%5] d70null=%6 d52null=%7",
        _this,
        getClientState,
        alive player,
        currentWeapon player,
        str ((getPos player) apply {round _x}),
        isNull (findDisplay 70),
        isNull (findDisplay 52)];
};
if (_hostConfirmed && _ph < 5) then
{
    private "_phAt";
    _phAt = uiNamespace getVariable ["ace3debug_lobbyPhaseAt", 0];
    private "_d70";
    _d70 = findDisplay 70;
    if (!isNull _d70) then
    {
        switch (_ph) do
        {
            case 0:
            {
                private "_rl";
                _rl = _d70 displayCtrl 109;
                if (!isNull _rl && (lbSize _rl) > 0) then
                {
                    _rl lbSetCurSel 0;
                    uiNamespace setVariable ["ace3debug_lobbyPhase", 1];
                    uiNamespace setVariable ["ace3debug_lobbyPhaseAt", diag_tickTime];
                    diag_log "[ace3debug] lobby: first role selected";
                }
                else
                {
                    // no (filled) role list: either the display just
                    // opened, or this context attached after the role
                    // phase had already passed (mission context).  Skip
                    // to the Continue retries after 30 s - harmless
                    // no-ops while the role screen is still up.
                    if (uiNamespace getVariable ["ace3debug_lobbyP0At", 0] <= 0) then
                    {
                        uiNamespace setVariable ["ace3debug_lobbyP0At", diag_tickTime];
                    };
                    if (diag_tickTime >= uiNamespace getVariable ["ace3debug_lobbyP0At", 0] + 30) then
                    {
                        uiNamespace setVariable ["ace3debug_lobbyPhase", 3];
                        uiNamespace setVariable ["ace3debug_lobbyRetry", diag_tickTime];
                        diag_log "[ace3debug] lobby: no role list, skipping to Continue retries";
                    };
                };
            };
            // phase 2 is unused: LOCK (idc 118) is never pressed - OK
            // alone starts the mission
            case 1:
            {
                // role selected; press OK (idc 1) the frame it becomes
                // enabled - no fixed delay.  30 s without the control
                // existing at all: straight to the terminal (a wedged
                // dialog must not strand the machine without a
                // diagnostic line); 30 s with the control present but
                // never enabled: press anyway.
                private "_ok";
                _ok = _d70 displayCtrl 1;
                if (isNull _ok && diag_tickTime >= _phAt + 30) exitWith
                {
                    "OK control missing" call _terminal;
                };
                if (!isNull _ok && (ctrlEnabled _ok || diag_tickTime >= _phAt + 30)) then
                {
                    _ok ctrlActivate true;
                    uiNamespace setVariable ["ace3debug_lobbyPhase", 3];
                    uiNamespace setVariable ["ace3debug_lobbyPhaseAt", diag_tickTime];
                    uiNamespace setVariable ["ace3debug_lobbyRetry", diag_tickTime + 1];
                    diag_log format ["[ace3debug] lobby: OK, role confirmed %1", !isNull _ok];
                };
            };
            case 3:
            {
                // role confirmed; the ready phase may be a while away
                // (server still loading its mission).  Retry the
                // continue action every 1 s: 70's OK while the briefing
                // is not up yet, then the briefing's CONTINUE (see
                // below) - the first successful press enters the world.
                //
                // World-entry signal: getClientState flips to
                // "BRIEFING READ" (state 10) when the briefing closes
                // and the mission becomes playable; a run stuck on the
                // briefing stays in the earlier state.  (Probe-verified:
                // in-world = "BRIEFING READ".)  Display 70 closing is
                // NOT the signal: with skipLobby the display lingers
                // frozen in the world, and no other API discriminates
                // (alive/weapon/pos are identical in both states).
                if (getClientState == "BRIEFING READ") exitWith
                {
                    uiNamespace setVariable ["ace3debug_lobbyPhase", 5];
                    diag_log "[ace3debug] lobby: world entered, player in the world";
                };
                if (diag_tickTime >= _phAt + 360) exitWith
                {
                    // stuck run: state is the client state it got stuck
                    // in (e.g. "BRIEFING SHOWN"), the rest is raw
                    "360 s without world entry" call _terminal;
                };
                if (diag_tickTime >= uiNamespace getVariable ["ace3debug_lobbyRetry", 0]) then
                {
                    uiNamespace setVariable ["ace3debug_lobbyRetry", diag_tickTime + 1];
                    // The briefing is its OWN display (52) with CONTINUE
                    // at idc 1.  Display 70 (the lobby) lingers frozen on
                    // the role screen, and its idc 1 is that screen's OK -
                    // pressing it after role confirm is a no-op and left
                    // the briefing up forever.  Press 70's idc 1 only
                    // while the briefing display is not up yet (ready
                    // phase before the briefing appears).
                    private "_bf";
                    private "_btn";
                    _bf = findDisplay 52;
                    if (!isNull _bf) then
                    {
                        _btn = _bf displayCtrl 1;
                    }
                    else
                    {
                        _btn = _d70 displayCtrl 1;
                    };
                    if (!isNull _btn) then
                    {
                        _btn ctrlActivate true;
                    };
                    // 1 s cadence: log only when the pressed target
                    // changes (d70 -> d52), not on every press
                    private "_target";
                    _target = if (isNull _bf) then { "d70" } else { "d52" };
                    if (uiNamespace getVariable ["ace3debug_lobbyRetryLog", ""] != _target) then
                    {
                        uiNamespace setVariable ["ace3debug_lobbyRetryLog", _target];
                        diag_log format ["[ace3debug] lobby: Continue retry %1 %2",
                            _target, !isNull _btn];
                    };
                };
            };
        };
    }
    else
    {
        if (_ph >= 3) then
        {
            // display closed = the player is in the world
            uiNamespace setVariable ["ace3debug_lobbyPhase", 5];
            diag_log "[ace3debug] lobby: display closed, player in the world";
        };
    };
    // heartbeat: proves this handler is ticking while the lobby is up
    if (diag_tickTime >= uiNamespace getVariable ["ace3debug_hb", 0]) then
    {
        uiNamespace setVariable ["ace3debug_hb", diag_tickTime + 30];
        diag_log format ["[ace3debug] lobby: heartbeat phase=%1 is3DEN=%2 d70=%3 is3DENPreview=%4", _ph, is3DEN, !isNull _d70, is3DENPreview];
    };
};
#endif
//
// 1. Preview retry (3DEN editor world only).
private "_done";
_done = uiNamespace getVariable ["ace3debug_done", false];
if (is3DEN && !_done) then
{
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
            // MissionPreviewMP opens the host-server dialog (idd 132)
            // instead of starting; confirm it with the OK button (idc 1).
            private "_host";
            _host = findDisplay 132;
            if (!isNull _host) then
            {
                // wait one tick after the dialog opens so its own
                // onLoad has bound the OK action before we activate it
                private "_seenAt";
                _seenAt = uiNamespace getVariable ["ace3debug_hostSeenAt", -1];
                if (_seenAt < 0) then
                {
                    uiNamespace setVariable ["ace3debug_hostSeenAt", diag_tickTime];
                    diag_log "[ace3debug] eachframe: host-server dialog open";
                };
                if (_seenAt >= 0 && diag_tickTime >= _seenAt + 0.5 && !_hostConfirmed) then
                {
                    uiNamespace setVariable ["ace3debug_hostConfirmed", true];
                    // the lobby state machine above picks up from here
                    uiNamespace setVariable ["ace3debug_mp", true];
                    private "_ok";
                    _ok = _host displayCtrl 1;
                    if (!isNull _ok) then
                    {
                        _ok ctrlActivate true;
                        diag_log "[ace3debug] eachframe: host-server dialog confirmed";
                    };
                };
            }
            else
            {
                do3DENAction _action;
            };
        };
    };
};
