PREP(assembleMarkerInfo);
PREP(createMarker);
// Debug-only commands. Never compiled into release builds.
#ifdef __A3_DEBUG__
PREP(debugFindWaterVehicle);
PREP(debugPrepareBoat);
PREP(debugPrepareWaterVehicle);
#endif
PREP(getMarkerChannels);
PREP(getPlayerTravelMode);
PREP(getVehiclePerformance);
PREP(onGpsUpdate);
PREP(onGpsVehicleChanged);
PREP(onInterestChanged);
PREP(onMarkerCreated);
PREP(onMarkerDeleted);
PREP(onMarkerPlaced);
PREP(onMarkerPosChanged);
PREP(processBrowserRequest);
