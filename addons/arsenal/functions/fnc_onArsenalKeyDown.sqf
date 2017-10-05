#include "script_component.hpp"
#include "..\defines.hpp"
#include "\A3\ui_f\hpp\defineDIKCodes.inc"

params ["", "_args"];
_args params ["_display", "_keyPressed", "_shiftState", "_ctrlState", "_altState"];

switch true do { 
    // Close button
    case (_keyPressed == DIK_ESCAPE): {
        _display closeDisplay 2;
    };
    // Hide button
    case (_keyPressed == DIK_BACKSPACE): {
        [_display] call FUNC(arsenalButtonHide);
    };
    // Export button
    case (_keyPressed == DIK_C): {
        if (_ctrlState) then  {
            [_display] call FUNC(arsenalButtonExport);
        };
    };
    // Import button
    case (_keyPressed == DIK_V): {
        if (_ctrlState) then {
            [_display] call FUNC(arsenalButtonImport);
        };
    };
    // Switch vision mode
    case (_keyPressed in (actionkeys "nightvision")): {
        private _currentVisionMode = missionNamespace getVariable [QGVAR(visionMode), -1];
        _currentVisionMode = (_currentVisionMode + 1) % 3;
        missionnamespace setvariable [QGVAR(visionMode), _currentVisionMode];

        switch _currentVisionMode do {
            //--- Normal
            case 0: {
                camusenvg false;
                false setCamUseTi 0;
            };
            //--- NVG
            case 1: {
                camusenvg true;
                false setCamUseTi 0;
            };
            //--- TI
            default {
                camusenvg false;
                true setCamUseTi 0;
            };
        };

        playsound ["RscDisplayCurator_visionMode",true];
    };
};

true