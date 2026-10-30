#include "script_component.hpp"

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
		// The websocket file server needs a file's contents. Translate it into the normal request
		// flow so the "main" GetFile command can be used by web apps as well.
		private _fileName = _data;

		private _request = createHashMapFromArray [
			["a", "main"],
			["c", "GetFile"],
			["path", _fileName]
		];

		// The extension waits for "FileContent" keyed by the original (untranslated) filename
		[_request, "local", {
			params ["_result", "_args"];
			_args params ["_fileName"];

			"arma_webhost" callExtension ["FileContent", [_fileName, _result]];
		}, [_fileName]] call FUNC(dispatchRequest);
	};

	if (_function == "Request") exitWith {
		// _data has the JSON request, we should return the result and pass the keystring again
		private _request = fromJSON _data;

		if (isNil "_request") exitWith {
			diag_log ["Failed to parse JSON message", _data];
		};

		diag_log ["WSrequest", _request];

		// { s: "Websocket client info", k: "keystring", d: {...} }
		private _sender = _request deleteAt "s";
		private _clientData = _request get "d";

		[_clientData, _sender, {
			params ["_result", "_args"];
			_args params ["_sender", "_request"];

			diag_log ["WSrequest result", _result];

			// We need to wrap the result back into { k: "keystring", d: _result }. Easy to just re-use the hashmap we already have
			_request set ["d", _result];

			"arma_webhost" callExtension ["SendTo", [_sender, toJSON _request]];
		}, [_sender, _request]] call FUNC(dispatchRequest);
	};

	if (_function == "Disconnect") exitWith {
		// A websocket client went away, drop every information interest it held.
		// _data is the websocket connection id
		[_data] call FUNC(interestClearClient);
	};

}];

// Start web host for external browser access
private _webhostResult = "arma_webhost" callExtension ["StartServer", [8001]];

if ((_webhostResult#0) isEqualTo "OK") then {
    diag_log "[TacPhone] Webhost started";
} else {
    diag_log format ["[TacPhone] Webhost failed to start: %1", _webhostResult];
    systemChat format ["TacPhone webhost failed to start: %1", _webhostResult];
};


// The TacPhone must always be open, for external WebBrowser to be able to request data from it, that's why we add it in a invisible layer
call FUNC(loadPhoneBackground);
