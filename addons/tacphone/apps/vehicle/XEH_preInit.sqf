#include "script_component.hpp"

ADDON = false;

PREP_RECOMPILE_START;
#include "XEH_PREP.hpp"
PREP_RECOMPILE_END;

GVAR(wheelsBrake) = false;

// ACE cargo is optional; without it the cargo payload, capability and airdrop
// all stay off, and the app works as before.
GVAR(hasCargoAddon) = isClass (configFile >> "CfgPatches" >> "ace_cargo");

// Single-drop guard: the id of the in-flight drop, nil when no drop is running
GVAR(airdropActive) = nil;

ADDON = true;
