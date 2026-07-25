#include "script_component.hpp"

#include "initKeybinds.inc.sqf"





// Start the WebServer host, this handles external webbrowser (second-screen, phone, tablet) access to the in-game TacPhone

addMissionEventHandler ["ExtensionCallback", {
	params ["_name", "_function", "_data"];

	if (_name != "ArmaWebHost") exitWith {};

	if (_function == "GetFile") exitWith {
		// _data has filename, we should return it and pass the filename again

		private _fileName = _data;
		if (_fileName == "/") then {
            // This is a file that the browser will not send us pbo prefix'ed
            _fileName = QPATHTOF(websources/index.html);
        };

		private _content = loadFile _fileName;
		systemChat str [_function, _data, count _content];

		"arma_webhost" callExtension ["FileContent", [_data, _content]];
	};

	if (_function == "Request") exitWith {
		// _data has filename, we should return it and pass the filename again
		private _request = fromJSON _data;

		// { s: "Websocket client info", k: "keystring", d: {...} }
		private _sender = _request deleteAt "s";
		private _data = _request get "d";

        // _data is { "a": "AppName", "c": "CommandName", ... }
        private _appTarget = _data get "a";
        private _appInfo = GVAR(AppInfo) getOrDefaultCall [_appTarget, {createHashMap}]; //#TODO log error if not found
        private _processor = _appInfo getOrDefaultCall ["requestprocessor", {"UNKNOWN HANDLER in request process"}]; //#TODO log error if not found

        private _result = _data call _processor; // Forward to that app's specific processor

		// We need to wrap the result back into { k: "keystring", d: _result }. Easy to just re-use the hashmap we already have
		_request set ["d", _result];

		"arma_webhost" callExtension ["SendTo", [_sender, toJSON _request]];
	};

}];

// Start web host for external browser access
"arma_webhost" callExtension ["StartServer", [8001]];

systemChat "Webhost started";
