#include "script_component.hpp"

ADDON = false;

PREP_RECOMPILE_START;
#include "XEH_PREP.hpp"
PREP_RECOMPILE_END;

// Active transmission state: nil, or a hashmap
// [radio, channel, additional, token, client, source, since, seen]
GVAR(tx) = nil;

// Monotonic snapshot counter, bumped by every coalesced push
GVAR(revision) = 0;

// Per-client requested state push floor in ms, stored from the GetState payload
GVAR(pushMsByClient) = createHashMap;

// Per-client options (allowRemoteTransmit, notifyRemoteTransmit), stored from
// the GetState payload, because SQF cannot read host options
GVAR(options) = createHashMap;

// Coalesced push guard: a single deferred push per event burst
GVAR(pushQueued) = false;

// Radio id the player is keying in game through a real handset
// (TFAR_event_OnTangent), "" otherwise. Blocks web transmits while non-empty.
GVAR(inGameTx) = "";

// Self-tangent guard: a programmatic transmit (start or end) fires
// TFAR_event_OnTangent for the player's own unit a few frames later.
// FUNC(transmit)/FUNC(stopTransmit) park the expected self-event as
// [radio id, start <BOOL>, expiry <NUMBER>]; FUNC(onTfarTangent) consumes
// it when the matching event arrives within SELF_TANGENT_WINDOW, so a late
// hitch cannot mark our own transmit as an in-game key press. A real key
// press retires a parked self-release (see FUNC(onTfarTangent)).
GVAR(ownTangent) = [];

// Display name cache per radio id, built by FUNC(assembleRadioState);
// dropped when the interest deactivates.
GVAR(displayNames) = createHashMap;

// [radio ids <ARRAY of STRING>, expiry <NUMBER>] cache of FUNC(getRadioIds)
// for the watchdog's radioGone check, refreshed at most every
// RADIO_IDS_CACHE_TTL seconds.
GVAR(radioIdsCache) = [];

ADDON = true;
