#include "script_component.hpp"
#include "..\defines.hpp"

params ["_display", "_control"];

private _ctrlIDC = ctrlIDC _control;

// Fade old control background
if !(isNil QGVAR(currentRightPanel)) then {
    private _previousCtrlBackground  = _display displayCtrl (GVAR(currentRightPanel) - 1);
    _previousCtrlBackground ctrlSetFade 1;
    _previousCtrlBackground ctrlCommit FADE_DELAY;
};

// Show new control background
private _ctrlBackground = _display displayCtrl (_ctrlIDC - 1);
_ctrlBackground ctrlShow true;
_ctrlBackground ctrlSetFade 0;
_ctrlBackground ctrlCommit FADE_DELAY;

private _searchbarCtrl = _display displayCtrl IDC_rightSearchbar;

if (!(ctrlShown _searchbarCtrl) || {ctrlFade _searchbarCtrl > 0}) then {
    _searchbarCtrl ctrlShow true;
    _searchbarCtrl ctrlSetFade 0;
    _searchbarCtrl ctrlCommit 0;
};

private _fnc_fill_right_Container = {
    params ["_configCategory", "_className", "_isMagazine", ["_isUnique", false, [false]]];

    private _cacheNamespace = _ctrlPanel; //For better readability.
    private _cachedItemInfo = _cacheNamespace getVariable [_configCategory+_className, []];

    if (_cachedItemInfo isEqualTo []) then {//Not in cache. So get info and put into cache.
        private _configPath = configFile >> _configCategory >> _className;

        _cachedItemInfo set [0, getText (_configPath >> "displayName")];
        _cachedItemInfo set [1, getText (_configPath >> "picture")];
        _cachedItemInfo set [2, [getNumber (_configPath >> "itemInfo" >> "mass"), getNumber (_configPath >> "mass")] select _isMagazine];

        _cacheNamespace setVariable [_configCategory+_className, _cachedItemInfo];
    };



    _cachedItemInfo params ["_displayName","_picture", "_mass"];

    private _lbAdd = _ctrlPanel lnbAddRow ["", _displayName, "0"];
    private _columns = count lnbGetColumnsPosition _ctrlPanel;

    _ctrlPanel lnbSetData [[_lbAdd, 0], _x];
    _ctrlPanel lnbSetPicture [[_lbAdd, 0], _picture];
    _ctrlPanel lnbSetValue [[_lbAdd, 0], _mass];
    _ctrlPanel lnbSetValue [[_lbAdd, 2], [0, 1] select (_isUnique)];
    _ctrlPanel lbSetTooltip [_lbAdd * _columns,format ["%1\n%2", _displayName, _x]];
};

// Retrieve compatible mags
private _compatibleItems = [];
private _compatibleMagazines = [[], [], []];
{
    if (_x != "") then {
        private _weaponConfig = (configFile >> "CfgWeapons" >> _x);
        private _index = _forEachIndex;

        {
            {
                if !(isClass (configFile >> "CfgMagazines" >> _x)) then {//magazine group
                    private _magazineGroups = uiNamespace getVariable [QGVAR(magazineGroups),["#CBA_HASH#",[],[],[]]];
                    private _magArray = [_magazineGroups, _x] call CBA_fnc_hashGet;
                    {(_compatibleMagazines select _index) pushBackUnique _x} forEach _magArray;
                } else {
                    (_compatibleMagazines select _index) pushBackUnique _x
                }
            } foreach ([getArray (_weaponConfig >> _x >> "magazines"), getArray (_weaponConfig >> "magazines")] select (_x == "this"));
        } foreach getArray (_weaponConfig >> "muzzles");
    };
} foreach [primaryWeapon GVAR(center), handgunWeapon GVAR(center), secondaryWeapon GVAR(center)];

private _itemsToCheck = [];
private _compatibleMagsCurrentWeapon = [];

private _ctrlPanel = _display displayCtrl IDC_rightTabContent;

switch (GVAR(currentLeftPanel)) do {
    case IDC_buttonPrimaryWeapon : {
        _compatibleMagsCurrentWeapon = _compatibleMagazines select 0;
         _compatibleItems = (primaryWeapon GVAR(center)) call bis_fnc_compatibleItems;
        _itemsToCheck = GVAR(currentItems) select 18;
    };
    case IDC_buttonHandgun : {
        _compatibleMagsCurrentWeapon = _compatibleMagazines select 1;
        _compatibleItems = (handgunWeapon GVAR(center)) call bis_fnc_compatibleItems;
        _itemsToCheck = GVAR(currentItems) select 20;
    };
    case IDC_buttonSecondaryWeapon : {
        _compatibleMagsCurrentWeapon = _compatibleMagazines select 2;
        _compatibleItems = (secondaryWeapon GVAR(center)) call bis_fnc_compatibleItems;
        _itemsToCheck = GVAR(currentItems) select 19;
    };
    case IDC_buttonUniform;
    case IDC_buttonVest;
    case IDC_buttonBackpack : {
        _ctrlPanel = _display displayCtrl IDC_rightTabContentListnBox;
    };
};

_itemsToCheck = _itemsToCheck apply {toLower _x};
_compatibleItems =  _compatibleItems apply {toLower _x};

lbClear (_display displayCtrl IDC_rightTabContentListnBox);
lbClear (_display displayCtrl IDC_rightTabContent);

(_display displayCtrl IDC_rightTabContentListnBox) lbSetCurSel -1;
(_display displayCtrl IDC_rightTabContent) lbSetCurSel -1;

private _leftPanelState = GVAR(currentLeftPanel) in [IDC_buttonPrimaryWeapon, IDC_buttonHandgun, IDC_buttonSecondaryWeapon];

if (_ctrlIDC in [RIGHT_PANEL_ACC_IDCS] && {_leftPanelState}) then {
    private _addEmpty = _ctrlPanel lbadd format [" <%1>",localize "str_empty"];
    _ctrlPanel lbsetvalue [_addEmpty, -1];
};

switch (_ctrlIDC) do {

    case IDC_buttonOptic : {
        if (_leftPanelState) then {
            {
                ["CfgWeapons", _x, _ctrlPanel] call FUNC(addListBoxItem);
            } foreach (_compatibleItems arrayIntersect (((GVAR(virtualItems) select 1) select 0) apply {toLower _x}));
        } else {
            {
                ["CfgWeapons", _x, false] call _fnc_fill_right_Container;
            } foreach ((GVAR(virtualItems) select 1) select 0);
        };
    };

    case IDC_buttonItemAcc : {
        if (_leftPanelState) then {
            {
                ["CfgWeapons", _x, _ctrlPanel] call FUNC(addListBoxItem);
            } foreach (_compatibleItems arrayIntersect (((GVAR(virtualItems) select 1) select 1) apply {toLower _x}));
        } else {
            {
                ["CfgWeapons", _x, false] call _fnc_fill_right_Container;
            } foreach ((GVAR(virtualItems) select 1) select 1);
        };
    };

    case IDC_buttonMuzzle : {
        if (_leftPanelState) then {
            {
                ["CfgWeapons", _x, _ctrlPanel] call FUNC(addListBoxItem);
            } foreach (_compatibleItems arrayIntersect (((GVAR(virtualItems) select 1) select 2) apply {toLower _x}));
        } else {
            {
                ["CfgWeapons", _x, false] call _fnc_fill_right_Container;
            } foreach ((GVAR(virtualItems) select 1) select 2);
        };
    };

    case IDC_buttonBipod : {
        if (_leftPanelState) then {
            {
                ["CfgWeapons", _x, _ctrlPanel] call FUNC(addListBoxItem);
            } foreach (_compatibleItems arrayIntersect (((GVAR(virtualItems) select 1) select 3) apply {toLower _x}));
        } else {
            {
                ["CfgWeapons", _x, false] call _fnc_fill_right_Container;
            } foreach ((GVAR(virtualItems) select 1) select 3);
        };
    };
    case IDC_buttonCurrentMag : {
        if (_leftPanelState) then {
            {
                ["CfgMagazines", _x, _ctrlPanel] call FUNC(addListBoxItem);
            } foreach ((GVAR(virtualItems) select 2) arrayIntersect _compatibleMagsCurrentWeapon);
        };
    };

    case IDC_buttonMag : {
        {
            ["CfgMagazines", _x, true] call _fnc_fill_right_Container;
        } foreach ((GVAR(virtualItems) select 2) arrayIntersect ((_compatibleMagazines select 0) + (_compatibleMagazines select 1) + (_compatibleMagazines select 2)));
    };

    case IDC_buttonMagALL : {
    isNil {"magAll";
        {
            ["CfgMagazines", _x, true] call _fnc_fill_right_Container;
        } foreach (GVAR(virtualItems) select 2);
        };
    };

    case IDC_buttonThrow : {
        {
            ["CfgMagazines", _x, true]  call _fnc_fill_right_Container;
        } foreach (GVAR(virtualItems) select 15);
    };

    case IDC_buttonPut : {
        {
            ["CfgMagazines", _x, true]  call _fnc_fill_right_Container;
        } foreach (GVAR(virtualItems) select 16);
    };

    case IDC_buttonMisc : {
        {
            ["CfgWeapons", _x, false]  call _fnc_fill_right_Container;
        } foreach (GVAR(virtualItems) select 17);
        {
            ["CfgWeapons", _x, false, true]  call _fnc_fill_right_Container;
        } foreach (GVAR(virtualItems) select 18);
    };
};

if (GVAR(currentRightPanel) != _ctrlIDC) then {
    (_display displayCtrl IDC_rightSearchbar) ctrlSetText "";
};

GVAR(currentRightPanel) = _ctrlIDC;

["ace_arsenal_rightPanelFilled", [_display, _ctrlIDC]] call CBA_fnc_localEvent;

// Sorting
private _sortRightCtrl = _display displayCtrl IDC_sortRightTab;

if (lbSize _sortRightCtrl == 3) then {
    _sortRightCtrl lbDelete 2;
};

if (_leftPanelState) then {
    _sortRightCtrl lbDelete 1;
    _sortRightCtrl lbAdd (localize "STR_a3_rscdisplayarsenal_sort_mod");
    _sortRightCtrl lbSetValue [1, 1];
} else {

    _sortRightCtrl lbDelete 1;
    _sortRightCtrl lbAdd "Sort by Weight";
    _sortRightCtrl lbSetValue [1, 1];
    
    _sortRightCtrl lbAdd "Sort by amount";
    _sortRightCtrl lbSetValue [2, 2];
};

[_sortRightCtrl, _sortRightCtrl lbValue (lbCurSel _sortRightCtrl)] call FUNC(sortPanel);

// Add current items in those containers
if (GVAR(currentLeftPanel) in [IDC_buttonUniform, IDC_buttonVest, IDC_buttonBackpack]) then {
    private _container = switch (GVAR(currentLeftPanel)) do {
        case IDC_buttonUniform : {
            (_display displayCtrl IDC_loadIndicatorBar) progressSetPosition (loadUniform GVAR(center));
            GVAR(currentItems) select 15
        };
        case IDC_buttonVest : {
            (_display displayCtrl IDC_loadIndicatorBar) progressSetPosition (loadVest GVAR(center));
            GVAR(currentItems) select 16
        };
        case IDC_buttonBackpack : {
            (_display displayCtrl IDC_loadIndicatorBar) progressSetPosition (loadBackpack GVAR(center));
            GVAR(currentItems) select 17
        };
    };

    for "_l" from 0 to (lbsize _ctrlPanel - 1) do {
        private _class = _ctrlPanel lnbData [_l, 0];
        _ctrlPanel lnbSetText [[_l, 2], if (_class in _container) then {str ({_x == _class} count _container)} else {"0"}];
    };
};

// Select current data if not in a container
if !(_itemsToCheck isEqualTo []) then {
    for "_lbIndex" from 0 to (lbSize _ctrlPanel - 1) do {
        private _currentData = _ctrlPanel lbData _lbIndex;

        if (!(_currentData isEqualTo "") && {_currentData in _itemsToCheck}) exitWith {
            _ctrlPanel lbSetCurSel _lbIndex;
        };
    };
};

if (lbCurSel _ctrlPanel < 0) then {
    _ctrlPanel lbSetCurSel 0;
};
