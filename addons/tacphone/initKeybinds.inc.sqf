[["ACE3 Equipment",LLSTRING(tacphoneCategory)], QGVAR(openPhoneKey), LLSTRING(openPhoneKey),
{
    if !("ACE_Tacphone" in (ACE_player call EFUNC(common,uniqueItems))) exitWith {};
    [DISPLAY_MODE_DIALOG] call FUNC(openDisplay);
},
{false},
[0, [false, false, false]], false, 0] call CBA_fnc_addKeybind; // (empty default key)
