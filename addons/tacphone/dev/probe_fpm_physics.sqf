// Live probe: 70 s of 2 Hz logging from the SQF side - the player's vehicle
// and every test plane within 5 km (type, altitude, speed, is-it-the-player's
// vehicle), to watch the FPM test's flight phase while it runs.
private _log = [];
private _t0 = CBA_missionTime;
private _i = 0;
while {_i < 140} do {
    private _veh = vehicle player;
    private _planes = nearestObjects [player, ["C_Plane_01", "B_Plane_Fighter_01_Stealth_F"], 5000];
    _log pushBack [
        floor ((CBA_missionTime - _t0) * 10) / 10,
        typeOf _veh,
        (_veh isEqualTo player),
        floor ((getPosASL _veh) select 2),
        floor (speed _veh * 10) / 10,
        _planes apply { [typeOf _x, floor ((getPosASL _x) select 2), floor (speed _x * 10) / 10, (_x isEqualTo _veh)] }
    ];
    _i = _i + 1;
    sleep 0.5;
};
_log
