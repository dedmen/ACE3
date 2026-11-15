// Live probe: level helicopter, nose +X, forward 10 m/s at 120 m ATL.
// Sample the three gate expressions for 3 s (the drop takes 2.5 s).
private _p = getPosATL player;
private _heli = createVehicle ["B_Heli_Transport_01_F", getPos player, [], 0, "FLY"];
private _teleport = [_p select 0, _p select 1, 120];
_heli setPosATL _teleport;
private _dir = [1, 0, 0];
private _up = [0, 0, 1];
_heli setVectorDirAndUp [_dir, _up];
private _vel = [10, 0, 0];
_heli setVelocity _vel;
private _rows = [];
private _t0 = CBA_missionTime;
private _i = 0;
while {_i < 30} do {
    private _t = CBA_missionTime - _t0;
    private _upV = vectorUp _heli;
    private _level = acos (_upV select 2);
    private _alt = (getPos _heli) select 2;
    private _spd = speed _heli;
    _rows pushBack [floor (_t * 10) / 10, floor (_level * 10) / 10, floor (_alt * 10) / 10, floor (_spd * 10) / 10];
    _i = _i + 1;
    sleep 0.1;
};
deleteVehicle _heli;
_rows
