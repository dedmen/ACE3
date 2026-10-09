#include "script_component.hpp"

#include "initKeybinds.inc.sqf"

// This must be postInit, because we try to load its processor function, and that is set in preInit

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


// Start the WebServer host, this handles external webbrowser (second-screen, phone, tablet) access to the in-game TacPhone

addMissionEventHandler ["ExtensionCallback", {
	params ["_name", "_function", "_data"];

	if (_name != "ArmaWebHost") exitWith {};

	if (_function == "GetFile") exitWith {
		// _data has filename, we should return it and pass the filename again

		private _fileName = _data;
		if (_fileName == "/" || _fileName == "") then {
            // This is a file that the browser will not send us pbo prefix'ed
            _fileName = QPATHTOF(data/index.html);
        };

        systemChat str ["pre", _fileName];
        _fileName = _fileName regexReplace ["\//g", "\\"];
        systemChat str ["post", _fileName];
		private _content = loadFile _fileName;
		systemChat str [_function, _data, count _content];

		"arma_webhost" callExtension ["FileContent", [_data, _content]];
	};

	if (_function == "Request") exitWith {
		// _data has filename, we should return it and pass the filename again
		private _request = fromJSON _data;

        diag_log ["WSrequest", _request];

		// { s: "Websocket client info", k: "keystring", d: {...} }
		private _sender = _request deleteAt "s";
		private _data = _request get "d";

        // _data is { "a": "AppName", "c": "CommandName", ... }
        private _appTarget = _data get "a";
        private _appInfo = GVAR(AppInfo) getOrDefaultCall [_appTarget, {createHashMap}]; //#TODO log error if not found
        private _processor = _appInfo getOrDefaultCall ["requestprocessor", {"UNKNOWN HANDLER in request process"}]; //#TODO log error if not found

        private _result = _data call _processor; // Forward to that app's specific processor

        if (_result isEqualType scriptNull) exitWith {
            // The script sent a promise as result, we don't yet have the data to send back
            _result continueWith [{
                _thisArgs params ["_sender", "_request"];

                diag_log ["WSrequest result", _this];

                // We need to wrap the result back into { k: "keystring", d: _result }. Easy to just re-use the hashmap we already have
                _request set ["d", _this];

                "arma_webhost" callExtension ["SendTo", [_sender, toJSON _request]];
            }, [_sender, _request]];
        };

        diag_log ["WSrequest result", _result];

		// We need to wrap the result back into { k: "keystring", d: _result }. Easy to just re-use the hashmap we already have
		_request set ["d", _result];

		"arma_webhost" callExtension ["SendTo", [_sender, toJSON _request]];
	};

}];

// Start web host for external browser access
"arma_webhost" callExtension ["StartServer", [8001]];

systemChat "Webhost started";
