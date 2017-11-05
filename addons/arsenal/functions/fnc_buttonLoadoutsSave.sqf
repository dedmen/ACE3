/*
 * Author: Alganthe
 * Save selected loadout.
 *
 * Arguments:
 * 0: Arsenal display <DISPLAY>
 * 1: Button control <CONTROL>
 *
 * Return Value:
 * None
 *
 * Public: No
*/
#include "script_component.hpp"
#include "..\defines.hpp"

params ["_display", "_control"];

if !(ctrlEnabled _control) exitWith {};

private _editBoxCtrl = _display displayCtrl IDC_textEditBox;
private _editBoxContent = ctrlText _editBoxCtrl;

if (_editBoxContent == "") exitWith {
    [(findDisplay IDD_ace_arsenal), format ["The name box is empty!", _editBoxContent]] call FUNC(message); // TBL
};

private _data = [+(profileNamespace getVariable QGVAR(saved_loadouts)), +(GVAR(defaultLoadoutsList))] select (GVAR(currentLoadoutsTab) == IDC_buttonDefaultLoadouts && {is3DEN});
private _contentPanelCtrl = _display displayCtrl IDC_contentPanel;
private _cursSelRow = lnbCurSelRow _contentPanelCtrl;

private _loadoutName = _contentPanelCtrl lnbText [_cursSelRow, 1];
private _curSelLoadout = _contentPanelCtrl getVariable (_loadoutName + str GVAR(currentLoadoutsTab));
private _loadout = getUnitLoadout GVAR(center);

private _sameNameLoadoutsList = _data select {_x select 0 == _editBoxContent};

private _similarSharedLoadout = (profileName + _editBoxContent) in GVAR(sharedLoadoutsVars);
if (_similarSharedLoadout) exitWith {
    [(findDisplay IDD_ace_arsenal), format ["You are sharing a loadout with this name", _editBoxContent]] call FUNC(message); // TBL
};

switch (GVAR(currentLoadoutsTab)) do {
    case IDC_buttonMyLoadouts:{

        for "_dataIndex" from 0 to 10 do {
            switch (_dataIndex) do {

                case 0;
                case 1;
                case 2;
                case 8: {

                    if (count (_loadout select _dataIndex) > 0) then {

                        private _weapon = (_loadout select _dataIndex) select 0;
                        if (_weapon != "") then {

                            private _baseWeapon = _weapon call BIS_fnc_baseWeapon;
                            if (_weapon != _baseWeapon) then {
                                (_loadout select _dataIndex) set [0, _baseWeapon];
                            };
                        };
                    };
                };

                case 3;
                case 4;
                case 5: {
                    if (count (_loadout select _dataIndex) > 0) then {
                        private _containerContents = (_loadout select _dataIndex) select 1;

                        if (count _containerContents > 0) then {

                            {
                                if (count _x == 2 && {!((_x select 0) isEqualType "")}) then {

                                    private _weapon = (_x select 0) select 0;
                                    if (_weapon != "") then {

                                        private _baseWeapon = _weapon call BIS_fnc_baseWeapon;
                                        if (_weapon != _baseWeapon) then {
                                            (_x select 0)set [0, _baseWeapon];
                                        };
                                    };
                                };
                            } foreach _containerContents;
                        };
                    };
                };
            };
        };

        if (count _sameNameLoadoutsList == 0) then {
            _data pushBack [_editBoxContent, _loadout];
        } else {
            _data set [_data find (_sameNameLoadoutsList select 0), [[_editBoxContent, _loadoutName] select (_loadoutName isEqualTo _editBoxContent), _loadout]];
        };

        // Delete "old" loadout row
        for '_i' from 0 to (((lnbsize _contentPanelCtrl) select 0) - 1) do {
            if ((_contentPanelCtrl lnbText [_i, 1]) == _editBoxContent) exitwith {_contentPanelCtrl lnbDeleteRow _i};
        };

        private _newRow = _contentPanelCtrl lnbAddRow ["",_editBoxContent];

        _contentPanelCtrl lnbSetPicture [[_newRow, 2], getText (configFile >> "cfgWeapons" >> ((_loadout select 0) select 0) >> "picture")];
        _contentPanelCtrl lnbSetPicture [[_newRow, 3], getText (configFile >> "cfgWeapons" >> ((_loadout select 1) select 0) >> "picture")];
        _contentPanelCtrl lnbSetPicture [[_newRow, 4], getText (configFile >> "cfgWeapons" >> ((_loadout select 2) select 0) >> "picture")];
        _contentPanelCtrl lnbSetPicture [[_newRow, 5], getText (configFile >> "cfgWeapons" >> ((_loadout select 3) select 0) >> "picture")];
        _contentPanelCtrl lnbSetPicture [[_newRow, 6], getText (configFile >> "cfgWeapons" >> ((_loadout select 4) select 0) >> "picture")];
        _contentPanelCtrl lnbSetPicture [[_newRow, 7], getText (configFile >> "cfgVehicles" >> ((_loadout select 5) select 0) >> "picture")];
        _contentPanelCtrl lnbSetPicture [[_newRow, 8], getText (configFile >> "cfgWeapons" >> (_loadout select 6) >> "picture")];
        _contentPanelCtrl lnbSetPicture [[_newRow, 9], getText (configFile >> "cfgGlasses" >> (_loadout select 7) >> "picture")];

        _contentPanelCtrl setVariable [_editBoxContent + str GVAR(currentLoadoutsTab), _loadout];

        _contentPanelCtrl lnbSort [1, false];

        // Select newly saved loadout
        for '_i' from 0 to (((lnbsize _contentPanelCtrl) select 0) - 1) do {
            if ((_contentPanelCtrl lnbText [_i, 1]) == _editBoxContent) exitwith {_contentPanelCtrl lnbSetCurSelRow _i};
        };

        profileNamespace setVariable [QGVAR(saved_loadouts), _data];

        private _savedLoadout = (_data select {_x select 0 == _editBoxContent}) select 0;
        [QGVAR(onLoadoutSave), [_data find _savedLoadout, _savedLoadout]] call CBA_fnc_localEvent;
    };

    case IDC_buttonDefaultLoadouts:{

        if (is3DEN) then {

            private _sameNameLoadoutsList = _data select {_x select 0 == _editBoxContent};

            for "_dataIndex" from 0 to 10 do {
                switch (_dataIndex) do {

                    case 0;
                    case 1;
                    case 2;
                    case 8: {

                        if (count (_loadout select _dataIndex) > 0) then {

                            private _weapon = (_loadout select _dataIndex) select 0;
                            if (_weapon != "") then {

                                private _baseWeapon = _weapon call BIS_fnc_baseWeapon;
                                if (_weapon != _baseWeapon) then {
                                    (_loadout select _dataIndex) set [0, _baseWeapon];
                                };
                            };
                        };
                    };

                    case 3;
                    case 4;
                    case 5: {
                        if (count (_loadout select _dataIndex) > 0) then {
                            private _containerContents = (_loadout select _dataIndex) select 1;

                            if (count _containerContents > 0) then {

                                {
                                    if (count _x == 2 && {!((_x select 0) isEqualType "")}) then {

                                        private _weapon = (_x select 0) select 0;
                                        if (_weapon != "") then {

                                            private _baseWeapon = _weapon call BIS_fnc_baseWeapon;
                                            if (_weapon != _baseWeapon) then {
                                                (_x select 0)set [0, _baseWeapon];
                                            };
                                        };
                                    };
                                } foreach _containerContents;
                            };
                        };
                    };
                };
            };

            if (count _sameNameLoadoutsList == 0) then {
                GVAR(defaultLoadoutsList) pushBack [_editBoxContent, _loadout];
            } else {
                GVAR(defaultLoadoutsList) set [GVAR(defaultLoadoutsList) find (_sameNameLoadoutsList select 0), [[_editBoxContent, _loadoutName] select (_loadoutName isEqualTo _editBoxContent), _loadout]];
            };

            for '_i' from 0 to (((lnbsize _contentPanelCtrl) select 0) - 1) do {
                if ((_contentPanelCtrl lnbText [_i, 1]) == _editBoxContent) exitwith {_contentPanelCtrl lnbDeleteRow _i};
            };

            private _newRow = _contentPanelCtrl lnbAddRow ["",_editBoxContent];

            _contentPanelCtrl lnbSetPicture [[_newRow, 2], getText (configFile >> "cfgWeapons" >> ((_loadout select 0) select 0) >> "picture")];
            _contentPanelCtrl lnbSetPicture [[_newRow, 3], getText (configFile >> "cfgWeapons" >> ((_loadout select 1) select 0) >> "picture")];
            _contentPanelCtrl lnbSetPicture [[_newRow, 4], getText (configFile >> "cfgWeapons" >> ((_loadout select 2) select 0) >> "picture")];
            _contentPanelCtrl lnbSetPicture [[_newRow, 5], getText (configFile >> "cfgWeapons" >> ((_loadout select 3) select 0) >> "picture")];
            _contentPanelCtrl lnbSetPicture [[_newRow, 6], getText (configFile >> "cfgWeapons" >> ((_loadout select 4) select 0) >> "picture")];
            _contentPanelCtrl lnbSetPicture [[_newRow, 7], getText (configFile >> "cfgVehicles" >> ((_loadout select 5) select 0) >> "picture")];
            _contentPanelCtrl lnbSetPicture [[_newRow, 8], getText (configFile >> "cfgWeapons" >> (_loadout select 6) >> "picture")];
            _contentPanelCtrl lnbSetPicture [[_newRow, 9], getText (configFile >> "cfgGlasses" >> (_loadout select 7) >> "picture")];

            _contentPanelCtrl setVariable [_editBoxContent + str GVAR(currentLoadoutsTab), _loadout];

            _contentPanelCtrl lnbSort [1, false];

            // Select newly saved loadout
            for '_i' from 0 to (((lnbsize _contentPanelCtrl) select 0) - 1) do {
                if ((_contentPanelCtrl lnbText [_i, 1]) == _editBoxContent) exitwith {_contentPanelCtrl lnbSetCurSelRow _i};
            };

            set3DENMissionAttributes [[QGVAR(DummyCategory), QGVAR(DefaultLoadoutsListAttribute), GVAR(defaultLoadoutsList)]];

            private _savedLoadout = (_data select {_x select 0 == _editBoxContent}) select 0;
            [QGVAR(onLoadoutSave), [_data find _savedLoadout, _savedLoadout]] call CBA_fnc_localEvent;
        } else {

            if (count _sameNameLoadoutsList == 0) then {
                _data pushBack [_editBoxContent, _curSelLoadout];
            } else {
                _data set [_data find (_sameNameLoadoutsList select 0), [[_editBoxContent, _loadoutName] select (_loadoutName isEqualTo _editBoxContent), _curSelLoadout]];
            };

            profileNamespace setVariable [QGVAR(saved_loadouts), _data];
        };
    };

    case IDC_buttonSharedLoadouts :{

        _loadout = (GVAR(sharedLoadoutsNamespace) getVariable ((_contentPanelCtrl lnbText [_cursSelRow, 0]) + (_contentPanelCtrl lnbText [_cursSelRow, 1]))) select 2;

        if (count _sameNameLoadoutsList == 0) then {
            _data pushBack [_editBoxContent, _loadout];
        } else {
            _data set [_data find (_sameNameLoadoutsList select 0), [[_editBoxContent, _loadoutName] select (_loadoutName isEqualTo _editBoxContent), _loadout]];
        };

        profileNamespace setVariable [QGVAR(saved_loadouts), _data];
    };
};
[(findDisplay IDD_ace_arsenal), format ["Loadout '%1' was saved", _editBoxContent]] call FUNC(message); // TBL