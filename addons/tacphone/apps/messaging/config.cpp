#include "script_component.hpp"

class CfgPatches {
    class ADDON {
        name = COMPONENT_NAME;
        units[] = {};
        weapons[] = {};
        requiredVersion = REQUIRED_VERSION;
        requiredAddons[] = {};
        author = ECSTRING(common,ACETeam);
        authors[] = {"dedmen"};
        url = ECSTRING(main,URL);
        VERSION_CONFIG;
    };
};

#include "ace_tacphone_apps.hpp"
#include "CfgEventHandlers.hpp"
//#include "gui.hpp"



class RscText;
class GVAR(ui): RscText
{
    type = 106; // CT_WEBBROWSER
    idc = 1337;
    x = 0; // Full size
    y = 0;
    w = 1;
    h = 1;
    url = "file://z/ace/addons/tacphone/apps/messaging/data/index.html"; //#TODO QPATHTOF? But we need file:// prefix
};