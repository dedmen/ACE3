#include "script_component.hpp"

// This must be postInit, because we try to load its processor function, and that is set in preInit

private _appConfigs = "getNumber (_x >> 'scope') > 0" configClasses (configFile >> QGVAR(apps));
_appConfigs append ("getNumber (_x >> 'scope') > 0" configClasses (missionConfigFile >> QGVAR(apps))); // allow for loading apps from description.ext

{
    private _appInfo = createHashMap;

    _appInfo set ["icon", getText (_x >> "icon")];
    _appInfo set ["file", getText (_x >> QGVAR(file))];
    _appInfo set ["devfile", getText (_x >> QGVAR(devFile))];
    // Optional: stringtable of an app that ships in a different add-on. Empty
    // means "share the host add-on's stringtable".
    _appInfo set ["stringtable", getText (_x >> QGVAR(stringtable))];
    _appInfo set ["requestprocessor", missionNamespace getVariable [getText (_x >> QGVAR(requestProcessor)), {"UNKNOWN HANDLER"}]];
    // Runtime module dependencies declared as nested classes:
    //   class EGVAR(tacphone,dependencies) {
    //       class some_library { name = "some-library"; file = "..." };
    //   };
    // configClasses returns definition order, and that order is the load order.
    private _depConfig = _x >> QGVAR(dependencies);
    private _deps = [];

    if (isClass _depConfig) then {
        {
            private _depName = getText (_x >> "name");
            private _depFile = getText (_x >> "file");

            if (_depName == "") then {
                _depName = configName _x;
            };

            if (_depFile == "") then {
                diag_log format ["[TacPhone] App dependency %1 has no file and was skipped", _depName];
            } else {
                _deps pushBack createHashMapFromArray [
                    ["name", _depName],
                    ["file", _depFile]
                ];
            };
        } forEach ("true" configClasses _depConfig);
    };

    _appInfo set ["dependencies", _deps];

    private _appName = configName _x;
    GVAR(AppInfo) set [_appName, _appInfo]
} forEach _appConfigs;


// The LAN webhost extension is debug-only. Release builds use the native relay.
#ifdef __A3_DEBUG__
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
		// The extension sends "WEBHOST:" + base64 of the framed {s,k,d} JSON.
		// SQF forwards it unchanged; the in-game web UI owns routing and replay.
		[_data] call FUNC(forwardTransportMessage);
	};

	if (_function == "Disconnect") exitWith {
		// A websocket client went away, drop every information interest it held and
		// tell the ui so it can remove the LAN peer.
		[_data] call FUNC(interestClearClient);

		[QGVAR(clientDisconnected), [_data]] call CBA_fnc_localEvent;

		[format ["WEBHOST_DISCONNECT:%1", _data]] call FUNC(forwardTransportMessage);
	};

	if (_function == "Log") exitWith {
		// The extension has no console in the Arma process. Buffer the entry and
		// push it into the in-game browser, which shows warnings/errors and writes
		// everything to its dev console.
		private _entry = fromJSON _data;
		if (!(_entry isEqualType createHashMap)) exitWith {};

		private _log = GVAR(hostLog);
		_log pushBack _entry;
		if ((count _log) > 50) then { _log deleteAt 0 };

		[createHashMapFromArray [
			["a", "main"],
			["c", "Host.Log"],
			["level", _entry getOrDefault ["level", "info"]],
			["message", _entry getOrDefault ["message", ""]],
			["time", _entry getOrDefault ["time", ""]]
		]] call FUNC(sendCommandToPhone);
	};

}];

// Start web host for external browser access (debug builds only)
private _webhostResult = "arma_webhost" callExtension ["StartServer", [8001]];

if ((_webhostResult#0) isEqualTo "OK") then {
    diag_log "[TacPhone] Webhost started";
} else {
    diag_log format ["[TacPhone] Webhost failed to start: %1", _webhostResult];
    systemChat format ["TacPhone webhost failed to start: %1", _webhostResult];
};
#endif


// Close the native relay when the mission ends. WebSocket handles are null after
// a savegame load, and an armed relay must not stay online silently.
addMissionEventHandler ["Ended", {
    ["RemoteAccess.Stop", createHashMap] call FUNC(remoteAccess);
}];

// The TacPhone must always be open, for external WebBrowser to be able to request data from it, that's why we add it in a invisible layer
call FUNC(loadPhoneBackground);
