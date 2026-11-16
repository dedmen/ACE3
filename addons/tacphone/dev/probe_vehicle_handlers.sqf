// Live probe: locate the vehicle app's compiled handler table.
private _candidates = [
    "ace_tacphone_vehicle_browserRequestHandlers",
    "ace_tacphone_Vehicle_browserRequestHandlers",
    "ace_tacphone_vehicle_vehicle_browserRequestHandlers"
];
private _found = [];
{
    if (!isNil _x) then {
        _found pushBack _x;
    };
} forEach _candidates;
_found
