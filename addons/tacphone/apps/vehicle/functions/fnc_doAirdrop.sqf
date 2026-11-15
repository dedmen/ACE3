#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Airdrops one ACE cargo item from the vehicle. The gates are re-checked
 * here, because the web only hides its buttons; then the single-drop guard
 * is set, the in-game progress bar starts (cargo's fnc_startUnload shape)
 * and the actual drop runs on finish through cargo's own
 * ace_cargo_paradropItem event (loaded-list removal, detach, parachute,
 * effects). The phone mirrors the drop via the Vehicle.Airdrop pushes.
 *
 * Arguments:
 * 0: Vehicle <OBJECT>
 * 1: Cargo item id <STRING> (netId of the object entry, or the classname string entry)
 *
 * Return Value:
 * ARRAY [true, itemId] when the drop started (or ran immediately),
 * [false, "machine error string"] when rejected
 *
 * Example:
 * [vehicle player, "123"] call ace_tacphone_vehicle_fnc_doAirdrop
 *
 * Public: No
 */

params ["_vehicle", "_cargoId"];

// Re-read the inventory: the list may have changed since the phone rendered it
private _loaded = _vehicle getVariable ["ace_cargo_loaded", []];
private _index = _loaded findIf {
    // Object entries match by netId, classname string entries by themselves
    (if (_x isEqualType objNull) then { netId _x isEqualTo _cargoId } else { _x isEqualTo _cargoId })
};
if (_index < 0) exitWith { [false, "unknown item"] };

private _item = _loaded select _index;
private _itemId = if (_item isEqualType objNull) then { netId _item } else { _item };

// Airdrop is aircraft-only; ground vehicles are read-only
if (!(_vehicle isKindOf "Air")) exitWith { [false, "airdrop not supported"] };

// Single-drop guard: only one in-flight drop at a time
if (!isNil QGVAR(airdropActive)) exitWith { [false, "airdrop in progress"] };

// The drop gates (SQF acos returns degrees), re-checked server-side: level
// flight and altitude. There is deliberately no speed/reverse gate - a
// helicopter flying or falling backwards can still drop cargo. The progress
// bar's condition block below carries the same expressions, so a drop started
// here can only fail that bar for the same reason.
if ((acos ((vectorUp _vehicle) select 2)) > 30) exitWith { [false, "unlevel flight"] };
if (((getPos _vehicle) select 2) < 25) exitWith { [false, "not high enough"] };

private _duration = [_item, true] call ace_cargo_fnc_getDelayItem;

GVAR(airdropActive) = _itemId;

["inProgress", _itemId, _duration] call FUNC(pushAirdrop);

// Zero-time drop: no progress bar, drop immediately (ACE's own zero-delay path)
if (_duration <= 0) exitWith {
    ["ace_cargo_paradropItem", [_item, _vehicle]] call CBA_fnc_localEvent;

    GVAR(airdropActive) = nil;
    ["dropped", _itemId] call FUNC(pushAirdrop);

    [true, _itemId]
};

// Same shape as cargo's fnc_startUnload: the bar starts one frame later
// (delayed so nothing in this frame stops it), non-blocking (dialog false =
// cutRsc bar, ESC cancels), and the condition carries the same gate
// expressions as the entry re-check above (no speed gate) - the phone's
// canAirdrop in fnc_buildAnimPayload must agree with it. The
// callbacks only see what the bar passes them ([args, elapsed, total,
// errorCode]), never this scope's locals, so _itemId rides along in _args.
private _itemName = [_item, true] call ace_cargo_fnc_getNameItem;
private _onFinish = {
    // The args are [item, vehicle, itemId]
    private _args = _this select 0;
    _args params ["_item", "_vehicle", "_itemId"];

    // The event wants the [item, vehicle] pair, the same cargo's own bar uses
    ["ace_cargo_paradropItem", [_item, _vehicle]] call CBA_fnc_localEvent;

    GVAR(airdropActive) = nil;
    ["dropped", _itemId] call FUNC(pushAirdrop);
};
private _onFail = {
    _this params ["_args", "", "", "_errorCode"];
    private _vehicle = _args select 1;
    private _itemId = _args select 2;

    GVAR(airdropActive) = nil;
    // errorCode 3 is the bar's per-frame gate failing; report which gate, in the
    // same order and expressions as the condition block (the fall-through is
    // unreachable: both evaluate the same two gates on the same frame).
    // Anything else (ESC, the player left the bar, the display closed) is a
    // plain abort.
    private _reason = "aborted";
    if (_errorCode == 3) then {
        _reason = if ((acos ((vectorUp _vehicle) select 2)) > 30) then { "unlevel flight" } else {
            if (((getPos _vehicle) select 2) < 25) then { "not high enough" } else { "aborted" }
        };
    };
    ["cancelled", _itemId, 0, _reason] call FUNC(pushAirdrop);
};

[EFUNC(common,progressBar), [
    _duration,
    [_item, _vehicle, _itemId],
    _onFinish,
    _onFail,
    format [localize "STR_ACE_Tacphone_Vehicle_AirdropProgress", _itemName, getText (configOf _vehicle >> "displayName")],
    {
        (_this select 0) params ["", "_vehicle"];

        if ((acos ((vectorUp _vehicle) select 2)) > 30) exitWith {false}; // check flight level
        if (((getPos _vehicle) select 2) < 25) exitWith {false}; // check height

        true
    },
    ["isNotSwimming", "isNotInside"],
    false
]] call CBA_fnc_execNextFrame;

// The reply reaches the phone while the drop is in progress; the in-game bar
// is the authoritative in-game visual
[true, _itemId]
