/*
 * ace_frag.cpp
 * Author: Dedmen
 * Implements fragmentation using Intercept
 */
#include "fragManager.hpp"

int __cdecl intercept::api_version() {
    return 1;
}

static client::EHIdentifierHandle addPfhRoundCallbackHandle;
static std::string addPfhRoundCallbackScript;
static client::EHIdentifierHandle settingsInitializedCallbackHandle;
static std::string settingsInitializedCallbackScript;
static client::EHIdentifierHandle firedCallbackHandle;
static std::string firedCallbackScript;
static client::EHIdentifierHandle masterPFHHandle;
static fragManager manager;

void intercept::post_start() {
    sqf::set_variable(sqf::ui_namespace(), "ace_frag_interceptPlugin", sqf::compile_final("true"));
    std::tie(addPfhRoundCallbackScript, addPfhRoundCallbackHandle) = client::generate_custom_callback([](game_value args) -> game_value {
        if (args.size() < 3) return {}; //invalid
        manager.addPfhRound(args[0], args[1], args[0]);
        return {};//ret nil
    });

    std::tie(firedCallbackScript, firedCallbackHandle) = client::generate_custom_callback([](game_value args) -> game_value {
        manager.fired(args);
        return {};//ret nil
    });

    std::tie(settingsInitializedCallbackScript, settingsInitializedCallbackHandle) = client::generate_custom_callback([](game_value args) -> game_value {

        bool enabled = sqf::get_variable(sqf::mission_namespace(), "ace_frag_enabled");
        if (!enabled) return {};//ret nil
        auto CBA_fnc_addEventHandler = sqf::get_variable(sqf::mission_namespace(), "CBA_fnc_addEventHandler");
        
        auto firedFunc = sqf::compile("_this append [_vehicle, _gunner, _turret];"+firedCallbackScript);
        sqf::call(CBA_fnc_addEventHandler, { "ace_firedPlayer", firedFunc });
        sqf::call(CBA_fnc_addEventHandler, { "ace_firedNonPlayer", firedFunc });
        sqf::call(CBA_fnc_addEventHandler, { "ace_firedPlayerVehicle", firedFunc });
        sqf::call(CBA_fnc_addEventHandler, { "ace_firedNonPlayerVehicle", firedFunc });

        masterPFHHandle = client::addMissionEventHandler<client::eventhandlers_mission::EachFrame>([]() {
            manager.masterPFH();
        });

        return {};//ret nil
    });
}

void intercept::pre_init() {
    sqf::set_variable(sqf::mission_namespace(), "ace_frag", true);
    //Function called from external source fnc_bi_moduleProjectile
    sqf::set_variable(sqf::mission_namespace(), "ace_frag_fnc_addPfhRound", sqf::compile_final(addPfhRoundCallbackScript));
    auto CBA_fnc_addEventHandler = sqf::get_variable(sqf::mission_namespace(), "CBA_fnc_addEventHandler");

    sqf::call(CBA_fnc_addEventHandler, { "ace_settingsInitialized", sqf::compile(settingsInitializedCallbackScript) });
}


void intercept::post_init() {
    sqf::set_variable(sqf::mission_namespace(), "ace_frag", true);
    //Function called from external source fnc_bi_moduleProjectile
    sqf::set_variable(sqf::mission_namespace(), "ace_frag_fnc_addPfhRound", sqf::compile_final(addPfhRoundCallbackScript));
}
