#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Synchronously increments the radio-state revision and returns the new
 * value. Every radio-state change (a web write, a TFAR event, death, a
 * vehicle change) commits before assembling the reply or push snapshot, so
 * an accepted write's reply already carries the new revision.
 * FUNC(pushRadioState) only broadcasts the current value and never
 * increments; an interest change (no radio-state change) does not commit.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * New revision <NUMBER>
 *
 * Example:
 * call ace_tacphone_radio_fnc_commitRevision
 *
 * Public: No
 */

GVAR(revision) = GVAR(revision) + 1;
GVAR(revision)
