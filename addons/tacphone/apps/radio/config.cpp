#include "script_component.hpp"

class CfgPatches {
    class ADDON {
        name = COMPONENT_NAME;
        units[] = {};
        weapons[] = {};
        requiredVersion = REQUIRED_VERSION;
        requiredAddons[] = {"ace_tacphone", "tfar_core"};
        author = ECSTRING(common,ACETeam);
        authors[] = {"Dedmen"};
        url = ECSTRING(main,URL);
        skipWhenMissingDependencies = 1;
        VERSION_CONFIG;
    };
};

#include "ace_tacphone_apps.hpp"
#include "CfgEventHandlers.hpp"
