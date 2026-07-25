#include "script_component.hpp"

ADDON = false;

PREP_RECOMPILE_START;
#include "XEH_PREP.hpp"
PREP_RECOMPILE_END;

#include "initSettings.inc.sqf"

GVAR(AppInfo) = createHashMap; // Stores list of all apps, and information on how to load them and where to pass requests to

// Just a dummy for our request dispatch logic
GVAR(AppInfo) set ["main", createHashMapFromArray [
    ["requestprocessor", FUNC(processBrowserRequest)]
]];

private _appConfigs = "getNumber (_x >> 'scope') > 0" configClasses (configFile >> QGVAR(apps));
_appConfigs append ("getNumber (_x >> 'scope') > 0" configClasses (missionConfigFile >> QGVAR(apps))); // allow for loading apps from description.ext

{
    private _appInfo = createHashMap;

    _appInfo set ["icon", getText (_x >> "icon")];
    _appInfo set ["file", getText (_x >> QGVAR(file))];
    _appInfo set ["devfile", getText (_x >> QGVAR(devFile))];
    _appInfo set ["requestprocessor", missionNamespace getVariable [getText (_x >> QGVAR(requestProcessor)), {"UNKNOWN HANDLER"}]];
    private _appName = configName _x;
    GVAR(AppInfo) set [_appName, _appInfo]
} forEach _appConfigs;


ADDON = true;
