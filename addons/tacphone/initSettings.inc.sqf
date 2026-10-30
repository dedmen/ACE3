private _category = LSTRING(tacphoneCategory);

[
    QGVAR(remoteEnabled),
    "CHECKBOX",
    [LSTRING(remoteEnabled_name), LSTRING(remoteEnabled_desc)],
    _category,
    true,
    0
] call CBA_fnc_addSetting;

[
    QGVAR(remoteHost),
    "EDITBOX",
    [LSTRING(remoteHost_name), LSTRING(remoteHost_desc)],
    _category,
    "tacphone.arma3.io",
    0
] call CBA_fnc_addSetting;
