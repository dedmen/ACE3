// This file is only for use within ACE, you would not use this when creating 3rd party apps in stand-alone PBO's

#define APPNAME Logistics
#define COMPONENT_BEAUTIFIED Tacphone App Logistics

#include "..\script_component.hpp"

// Routing key of every request and push. Matches the app class in
// ace_tacphone_apps.hpp and the web APP_NAME.
#define LOGISTICS_APP "ACE_TacPhone_Logistics"

// Information interest that makes the game produce queue pushes. Held while a
// Logistics panel is mounted.
#define LOGISTICS_INTEREST "ACE_TacPhone_Logistics.requests"

// Safety cap for open (not done/cancelled) requests, guarding against a
// runaway client.
#define LOGISTICS_QUEUE_CAP 100

// Retention cap for closed (done/cancelled) requests: the newest
// LOGISTICS_CLOSED_HISTORY_CAP closed records are kept, older ones are
// pruned and pushed as Logistics.Request.Remove.
#define LOGISTICS_CLOSED_HISTORY_CAP 25

// Request progress states, matching LogisticsState in
// ACE_TacPhone_Logistics/src/types.ts.
#define LOGISTICS_STATE_QUEUED "queued"
#define LOGISTICS_STATE_PACKING "packing"
#define LOGISTICS_STATE_WAITING_DELIVERY "waiting_delivery"
#define LOGISTICS_STATE_DELIVERING "delivering"
#define LOGISTICS_STATE_DONE "done"
#define LOGISTICS_STATE_CANCELLED "cancelled"

// Request-handler guard, inlined at the call site.

// Exits the handler with {ok: false, error: "No player"} when the request
// sender is not a valid unit.
#define REQUIRE_SENDER(_sender) \
    if (isNull (_sender)) exitWith { createHashMapFromArray [["ok", false], ["error", "No player"]] }
