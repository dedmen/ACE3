#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Forwards one already encoded transport message to the in-game web UI.
 *
 * The relay and the debug webhost extension base64-encode the game-bound
 * payload and prefix it ("RELAY:", "WEBHOST:" or "WEBHOST_DISCONNECT:"), so the
 * string is plain ASCII and can be embedded in ExecJS unchanged. SQF must not
 * base64-encode or JSON-parse transport payloads.
 *
 * Arguments:
 * 0: Transport message <STRING> (already prefixed, ASCII safe)
 *
 * Return Value:
 * True when the in-game browser received the message <BOOL>
 *
 * Example:
 * ["WEBHOST_DISCONNECT:LOCAL_123"] call ace_tacphone_fnc_forwardTransportMessage
 *
 * Public: No
 */

params ["_data"];

private _control = uiNamespace getVariable [QGVAR(appSection), controlNull];
if (isNull _control) exitWith { false };

_control ctrlWebBrowserAction ["ExecJS", format ["window.TacPhone.networking.OnTransportMessage('%1')", _data]];

true
