// This file is only for use within ACE, you would not use this when creating 3rd party apps in stand-alone PBO's

#define APPNAME Radio
#define COMPONENT_BEAUTIFIED Tacphone App Radio

#include "..\script_component.hpp"

// Information interest that makes the game push radio state to the interested clients
#define INTEREST_RADIOS "ACE_TacPhone_Radio.radios"

// Seconds without a keepalive before the watchdog ends a transmission
#define TX_KEEPALIVE_TIMEOUT 6

// Seconds between two watchdog ticks while a transmission is active
#define TX_WATCHDOG_INTERVAL 0.5

// Lifetime of the parked self-tangent guard in seconds. Long enough for a
// frame hitch to deliver the self-event (a slip only costs one keepalive
// nack), short enough that a real in-game PTT release is never swallowed by
// a stale entry.
#define SELF_TANGENT_WINDOW 5

// Seconds between two kit re-enumerations in the watchdog; a shorter check
// cadence than TX_WATCHDOG_INTERVAL would cost a full TFAR radios list per
// tick while a transmission is active.
#define RADIO_IDS_CACHE_TTL 2

// Upper bound of the per-client requested state push floor, in milliseconds
#define MAX_PUSH_MS 2000
