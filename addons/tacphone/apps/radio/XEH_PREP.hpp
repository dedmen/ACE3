PREP(assembleAllRadios);
PREP(assembleRadioState);
PREP(commitRevision);
// Debug-only commands. Never compiled into release builds.
#ifdef __A3_DEBUG__
PREP(debugRadioState);
#endif
PREP(encodeRadioId);
PREP(getRadioById);
PREP(getRadioIds);
PREP(onEnded);
PREP(onInterestChanged);
PREP(onPlayerKilled);
PREP(onPlayerRespawned);
PREP(onTfarRadioEvent);
PREP(onTfarTangent);
PREP(onVehicleChanged);
PREP(processBrowserRequest);
PREP(pushRadioState);
PREP(setChannel);
PREP(setFrequency);
PREP(setSpeakers);
PREP(setStereo);
PREP(setVolume);
PREP(srRadioClasses);
PREP(stopTransmit);
PREP(transmit);
PREP(txWatchdog);
