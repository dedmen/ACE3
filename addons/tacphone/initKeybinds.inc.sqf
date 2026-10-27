[["ACE3 Equipment",LLSTRING(tacphoneCategory)], QGVAR(openPhoneKey), LLSTRING(openPhoneKey),
{
    //#TODO Migrate this to canopen fnc
    if (("ACE_Tacphone" in items ace_player)) then {
        call FUNC(loadPhoneForeground)
    };
},
{false},
[0, [false, false, false]], false, 0] call CBA_fnc_addKeybind; // (empty default key)
