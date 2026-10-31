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

[
    QGVAR(messagingAllowEnemyChat),
    "CHECKBOX",
    [LSTRING(messagingAllowEnemyChat_name), LSTRING(messagingAllowEnemyChat_desc)],
    _category,
    false,
    1
] call CBA_fnc_addSetting;
