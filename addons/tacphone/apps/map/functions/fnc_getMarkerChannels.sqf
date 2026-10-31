#include "..\script_component.hpp"
/*
 * Author: Dedmen
 * Collects the marker channels available to the Web UI.
 *
 * Standard channels 0..5 are always returned. Custom channels are returned only
 * when radioChannelInfo reports them as in use, with their real label. The
 * fourth entry is the mapMarkers flag from channelEnabled (Arma 3 2.22+).
 *
 * Return Value:
 * ARRAY of [id, label, custom, mapMarkersEnabled]
 *
 * Public: No
 */

private _channels = [];
private _standardLabels = ["Global", "Side", "Command", "Group", "Vehicle", "Direct"];

{
    private _enabled = channelEnabled _x;
    _channels pushBack [_x, _standardLabels select _x, false, (_enabled param [2, true])];
} forEach [0, 1, 2, 3, 4, 5];

private _customChannelIds = [];

for "_i" from 6 to 15 do {
    _customChannelIds pushBack _i;
};

for "_i" from 26 to 65 do {
    _customChannelIds pushBack _i;
};

{
    private _info = radioChannelInfo _x;

    if ((_info param [5, false]) isEqualTo true) then {
        private _label = _info param [1, ""];
        if (_label == "") then {
            _label = format ["Channel %1", _x];
        };

        private _enabled = channelEnabled _x;
        _channels pushBack [_x, _label, true, (_enabled param [2, true])];
    };
} forEach _customChannelIds;

_channels
