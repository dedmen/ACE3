PREP(buildAnimPayload);
PREP(buildCargo);
PREP(buildCrew);
PREP(buildStatePayload);
// Debug-only commands. Never compiled into release builds.
#ifdef __A3_DEBUG__
PREP_SUBDIR(debug,debugAddCargo);
PREP(debugVehicleInfo);
PREP_SUBDIR(debug,debugPrepareVehicle);
#endif
PREP(doAirdrop);
PREP(doControl);
PREP(doSlingLoad);
PREP(getCapabilities);
PREP(getVehicleInfo);
PREP(onInterestChanged);
PREP(onPlayerRespawned);
PREP(onSeatSwitched);
PREP(onVehicleChanged);
PREP(processBrowserRequest);
PREP(pushAirdrop);
PREP(pushAnim);
PREP(pushCargo);
PREP(pushCrew);
PREP(pushState);
