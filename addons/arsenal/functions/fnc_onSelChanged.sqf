#include "script_component.hpp"
#include "..\defines.hpp"

params ["_control", "_curSel"];

private _display = ctrlParent _control;
if (_curSel < 0) exitwith {};

private _item = [_control lnbData [_curSel, 0], _control lbData _curSel] select !(ctrlType _control == 102);

private _fnc_itemInfo = {
    params ["_itemCfg"];

    private _ctrlInfo = _display displayCtrl IDC_infoBox;

    if (isClass _itemCfg) then {

        _ctrlInfo ctrlSetFade 0;
        _ctrlInfo ctrlCommit FADE_DELAY;

        _ctrlInfoName = _display displayctrl IDC_infoName;
        _ctrlInfoName ctrlSetText (param [1, [_control lbtext _curSel ,_control lnbtext [_curSel,1]] select (ctrltype _control == 102)]);

        _ctrlInfoAuthor = _display displayctrl IDC_infoAuthor;
        _ctrlInfoAuthor ctrlSetText "";
        [_itemCfg,_ctrlInfoAuthor] call bis_fnc_overviewauthor;

    } else {
        LOG("no item");
        _ctrlInfo ctrlSetFade 1;
        _ctrlInfo ctrlCommit FADE_DELAY;
    };
};

switch (GVAR(currentLeftPanel)) do { 

    case IDC_buttonPrimaryWeapon : {
        private _baseWeapon = ((GVAR(currentItems) select 0) call bis_fnc_baseWeapon);

        if ((GVAR(currentItems) select 0) != _item && {_baseWeapon != _item}) then {
            {
                GVAR(center) removeMagazines _x;
            } foreach getArray (configfile >> "cfgweapons" >> _baseWeapon >> "magazines");

            if (_item == "") then {

                GVAR(center) removeWeapon (primaryWeapon GVAR(center));
                GVAR(currentItems) set [18, []];
                GVAR(currentItems) set [0, _item];
            } else {

                private _compatibleItems = _item call bis_fnc_compatibleItems;
                [GVAR(center), _item, 4] call bis_fnc_addweapon;

                private _newAccs = [];
                {
                    if (_x in _compatibleItems) then {
                        GVAR(center) addPrimaryWeaponItem _x;
                        _newAccs pushBack _x;
                    };
                } foreach (GVAR(currentItems) select 18);

                GVAR(currentItems) set [18, _newAccs];
                GVAR(currentItems) set [0, _item];
            };
        };
        call FUNC(showItem);
        [(configFile >> "CfgWeapons" >> _item)] call _fnc_itemInfo;
    };
    case IDC_buttonHandgun : {
        private _baseWeapon = ((GVAR(currentItems) select 2) call bis_fnc_baseWeapon);

        if ((GVAR(currentItems) select 2) != _item && {_baseWeapon != _item}) then {
            {
                GVAR(center) removeMagazines _x;
            } foreach getArray (configfile >> "cfgweapons" >> _baseWeapon >> "magazines");

            if (_item == "") then {

                GVAR(center) removeWeapon (handgunWeapon GVAR(center));
                GVAR(currentItems) set [20, []];
                GVAR(currentItems) set [2, _item];
            } else {

                private _compatibleItems = _item call bis_fnc_compatibleItems;
                [GVAR(center), _item, 3] call bis_fnc_addweapon;

                private _newAccs = [];
                {
                    if (_x in _compatibleItems) then {
                        GVAR(center) addHandgunItem _x;
                        _newAccs pushBack _x;
                    };
                } foreach (GVAR(currentItems) select 20);

                GVAR(currentItems) set [20, _newAccs];
                GVAR(currentItems) set [2, _item];
            };
        };
        call FUNC(showItem);
        [(configFile >> "CfgWeapons" >> _item)] call _fnc_itemInfo;
    };
    case IDC_buttonSecondaryWeapon : {
        private _baseWeapon = ((GVAR(currentItems) select 1) call bis_fnc_baseWeapon);

        if ((GVAR(currentItems) select 1) != _item && {_baseWeapon != _item}) then {
            {
                GVAR(center) removeMagazines _x;
            } foreach getArray (configfile >> "cfgweapons" >> _baseWeapon >> "magazines");

            if (_item == "") then {

                GVAR(center) removeWeapon (secondaryWeapon GVAR(center));
                GVAR(currentItems) set [19, []];
                GVAR(currentItems) set [1, _item];
            } else {

                private _compatibleItems = _item call bis_fnc_compatibleItems;
                [GVAR(center), _item, 1] call bis_fnc_addweapon;

                private _newAccs = [];
                {
                    if (_x in _compatibleItems) then {
                        GVAR(center) addSecondaryWeaponItem _x;
                        _newAccs pushBack _x;
                    };
                } foreach (GVAR(currentItems) select 19);

                GVAR(currentItems) set [19, _newAccs];
                GVAR(currentItems) set [1, _item];
            };
        };
        call FUNC(showItem);
        [(configFile >> "CfgWeapons" >> _item)] call _fnc_itemInfo;
    };
    case IDC_buttonHeadgear : {
        if (_item == "") then {
            removeHeadgear GVAR(center);
            GVAR(currentItems) set [3, _item];
        } else {
            GVAR(center) addHeadgear _item;
            GVAR(currentItems) set [3, _item];
        };
        call FUNC(showItem);
        [(configFile >> "CfgWeapons" >> _item)] call _fnc_itemInfo;
    };
    case IDC_buttonUniform : {
        if (_item == "") then {

            removeuniform GVAR(center);
            GVAR(currentItems) set [15, []];
            GVAR(currentItems) set [4, _item];
        } else {

            GVAR(center) forceAddUniform _item;

            while {count uniformitems GVAR(center) > 0} do {
                GVAR(center) removeitemfromuniform (uniformitems GVAR(center) select 0);
            }; //--- Remove default config contents

            {GVAR(center) addItemtoUniform _x} foreach (GVAR(currentItems) select 15);
            GVAR(currentItems) set [4, _item];

            [GVAR(center), ""] call bis_fnc_setUnitInsignia;
            [GVAR(center), GVAR(currentInsignia)] call bis_fnc_setUnitInsignia;
        };
        call FUNC(showItem);
        [(configFile >> "CfgWeapons" >> _item)] call _fnc_itemInfo;
    };
    case IDC_buttonVest: {
        if (_item == "") then {

            removeVest GVAR(center);
            GVAR(currentItems) set [16, []];
            GVAR(currentItems) set [5, _item];
        } else {

            GVAR(center) addVest _item;
            while {count vestItems GVAR(center) > 0} do {
                GVAR(center) removeItemFromVest (VestItems GVAR(center) select 0);
            }; //--- Remove default config contents
            {GVAR(center) addItemToVest _x} foreach (GVAR(currentItems) select 16);

            GVAR(currentItems) set [5, _item];
        };
        call FUNC(showItem);
        [(configFile >> "CfgWeapons" >> _item)] call _fnc_itemInfo;
    };
    case IDC_buttonBackpack : {
        if (_item == "") then {

            removeBackpack GVAR(center);
            GVAR(currentItems) set [17, []];
            GVAR(currentItems) set [6, _item];
        } else {

            removeBackpack GVAR(center);
            GVAR(center) addBackpack _item;
            while {count backpackItems GVAR(center) > 0} do {
                GVAR(center) removeItemFromBackpack (VestItems GVAR(center) select 0);
            }; //--- Remove default config contents
            {GVAR(center) addItemToBackpack _x} foreach (GVAR(currentItems) select 17);

            GVAR(currentItems) set [6, _item];
        };
        call FUNC(showItem);
        [(configFile >> "CfgVehicles" >> _item)] call _fnc_itemInfo;
    };
    case IDC_buttonGoggles : {
        if (_item == "") then {
            removeGoggles GVAR(center);
            GVAR(currentItems) set [7, _item];
        } else {
            GVAR(center) addGoggles _item;
            GVAR(currentItems) set [7, _item];
        };
        call FUNC(showItem);
        [(configFile >> "CfgGlasses" >> _item)] call _fnc_itemInfo;
    };
    case IDC_buttonNVG : {
        if (_item == "") then {
            GVAR(center) unlinkItem (GVAR(currentItems) select 8);
            GVAR(currentItems) set [8, _item];
        } else {
            GVAR(center) linkItem _item;
            GVAR(currentItems) set [8, _item];
        };
        call FUNC(showItem);
        [(configFile >> "CfgWeapons" >> _item)] call _fnc_itemInfo;
    };
    case IDC_buttonBinoculars : {
        if (_item == "") then {
            GVAR(center) removeWeapon (binocular GVAR(center));
            GVAR(currentItems) set [9, _item];
        } else {
            GVAR(center) addWeapon _item;
            GVAR(currentItems) set [9, _item];
            call FUNC(showItem);
            ADDBINOCULARSMAG
        };
        call FUNC(showItem);
        [(configFile >> "CfgWeapons" >> _item)] call _fnc_itemInfo;
    };
    case IDC_buttonMap : {
        if (_item == "") then {
            GVAR(center) unlinkItem (GVAR(currentItems) select 10) select 0;
            GVAR(currentItems) set [10, _item];
        } else {
            GVAR(center) linkItem _item;
            GVAR(currentItems) set [10, _item];
        };
        call FUNC(showItem);
        [(configFile >> "CfgWeapons" >> _item)] call _fnc_itemInfo;
    };
    case IDC_buttonCompass : {
        if (_item == "") then {
            GVAR(center) unlinkItem (GVAR(currentItems) select 11) select 0;
            GVAR(currentItems) set [11, _item];
        } else {
            GVAR(center) linkItem _item;
            GVAR(currentItems) set [11, _item];
        };
        call FUNC(showItem);
        [(configFile >> "CfgWeapons" >> _item)] call _fnc_itemInfo;
    };
    case IDC_buttonRadio : {
        if (_item == "") then {
            GVAR(center) unlinkItem (GVAR(currentItems) select 12) select 0;
            GVAR(currentItems) set [12, _item];
        } else {
            GVAR(center) linkItem _item;
            GVAR(currentItems) set [12, _item];
        };
        call FUNC(showItem);
        [(configFile >> "CfgWeapons" >> _item)] call _fnc_itemInfo;
    };
    case IDC_buttonWatch : {
        if (_item == "") then {
            GVAR(center) unlinkItem (GVAR(currentItems) select 13);
            GVAR(currentItems) set [13, _item];
        } else {
            GVAR(center) linkItem _item;
            GVAR(currentItems) set [13, _item];
        };
        call FUNC(showItem);
        [(configFile >> "CfgWeapons" >> _item)] call _fnc_itemInfo;
    };
    case IDC_buttonGPS : {
        if (_item == "") then {
            GVAR(center) unlinkItem (GVAR(currentItems) select 14) select 0;
            GVAR(currentItems) set [14, _item];
        } else {
            GVAR(center) linkItem _item;
            GVAR(currentItems) set [14, _item];
        };
        call FUNC(showItem);
        [(configFile >> "CfgWeapons" >> _item)] call _fnc_itemInfo;
    };
    case IDC_buttonFace : {
        private _face = [_item, "Default"] select (_item == "");

        GVAR(center) setFace _face;
        GVAR(currentFace) = _face;
        call FUNC(showItem);
        [(configFile >> "CfgFaces" >> _item)] call _fnc_itemInfo;
    };
    case IDC_buttonVoice : {
        GVAR(center) setSpeaker _item;
        GVAR(currentVoice) = _item;
        call FUNC(showItem);
        [(configFile >> "CfgVoice" >> _item)] call _fnc_itemInfo;
    };
    case IDC_buttonInsigna : {
        [GVAR(center), _item] call bis_fnc_setUnitInsignia;
        GVAR(currentInsignia) = _item;
        call FUNC(showItem);
        [(configFile >> "CfgUnitInsignia" >> _item)] call _fnc_itemInfo;
    };
};