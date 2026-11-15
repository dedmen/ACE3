class CfgPatches
{
    class ace3debug
    {
        units[] = {};
        weapons[] = {};
        requiredVersion = 1.58;
        requiredAddons[] = {"3DEN"};
        is3DENmod = 1;
    };
};

// Auto-start the mission preview when 3DEN opens a mission.
//
// 3DEN does not compile addon CfgFunctions (there is no mission load), so
// the scripts are compiled manually from the addon files (the PBO prefix
// 'ace3debug' is the in-game path of its files).
//
// The SQF scheduler does not run in the editor - spawned scripts never
// execute and sleep is not allowed.  Mission event handlers DO tick in
// 3DEN, so the mission "EachFrame" handler is the "timer" (it must be
// a compiled code object - a string body never ticks):
//   init / display-load -> register.sqf (once, when the world is loaded):
//                             first preview attempt, 3DEN event handlers,
//                             attach.sqf (EachFrame poller, code object)
//   XEH PreInit (CBA-driven, the editor-ready moment) -> attach.sqf:
//                             re-attach in case the display-load attach
//                             was too early (idempotent)
//   EachFrame (every engine frame) -> eachframe.sqf:
//                             preview retry (do3DENAction every 0.5 s,
//                             editor world only) + MP lobby state
//                             machine (role -> OK once enabled, then
//                             the briefing Continue on display 52)
//   OnMissionPreview -> ondone.sqf: confirmation log, done flag (the
//                             poller keeps running - the lobby machine
//                             still has to press Continue)
//
// Keep the event-handler strings to constructs the config precompiler
// accepts: plain statements, compile preprocessFileLineNumbers, call.
class Cfg3DEN
{
    class EventHandlers
    {
        class ace3debug
        {
            init = "diag_log '[ace3debug] Cfg3DEN init fired'; reg = compile preprocessFileLineNumbers 'ace3debug\register.sqf'; call reg;";
        };
    };
};

// Editor-ready hook: CBA XEH runs the PreInit handlers in 3DEN once the
// editor is fully ready (fnc_initDisplay3DEN watchdog -> CBA_fnc_preInit).
// attach.sqf is idempotent, so this is a no-op when the display-load
// attach already happened.
class Extended_PreInit_EventHandlers
{
    class ace3debug
    {
        init = "diag_log '[ace3debug] XEH PreInit fired'; p = compile preprocessFileLineNumbers 'ace3debug\attach.sqf'; call p;";
    };
};

// Backup hook (fires whenever the editor display loads, even if init was
// missed or fired before the mission world was loaded): same
// registration; register.sqf is idempotent.
class Extended_DisplayLoad_EventHandlers
{
    class Display3DEN
    {
        ace3debug = "diag_log '[ace3debug] Display3DEN loaded'; reg2 = compile preprocessFileLineNumbers 'ace3debug\register.sqf'; call reg2;";
    };
};


