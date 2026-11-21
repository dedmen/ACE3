// This file is only for use within ACE, you would not use this when creating 3rd party apps in stand-alone PBO's

#define APPNAME Vehicle
#define COMPONENT_BEAUTIFIED Tacphone App Vehicle

#include "..\script_component.hpp"

// Information interest that makes the game push 5 Hz instrument updates to the interested clients
#define INTEREST_ANIM "ACE_TacPhone_Vehicle.anim"

// Information interest that makes the game push 20 Hz attitude updates to the interested clients
#define INTEREST_STATE "ACE_TacPhone_Vehicle.state"

// Information interest that makes the game push cargo inventory updates to the interested clients
#define INTEREST_CARGO "ACE_TacPhone_Vehicle.cargo"

// Information interest that makes the game push 5 Hz top-down sling scope updates to the interested clients
#define INTEREST_SLING "ACE_TacPhone_Vehicle.sling"

// Seconds between two Vehicle.Anim pushes while the interest is held.
#define ANIM_UPDATE_INTERVAL 0.2

// Seconds between two Vehicle.State pushes while the interest is held.
#define STATE_UPDATE_INTERVAL 0.05

// Seconds between two Vehicle.Sling pushes while the interest is held.
#define SLING_UPDATE_INTERVAL 0.2

// Maximum 3D distance (heli position to object position) the sling scan
// (scope payload and Hook pick) reaches. Capped well below the old 100 m so
// the scope stays an aiming aid for the hook, not a wide-area radar of what
// flies below. The view radii (20/40/50 m) mirror this cap.
#define SLING_SCAN_RADIUS 50

// Maximum sling scope targets, nearest first.
#define SLING_MAX_TARGETS 10

// The pilot-hook reach around the helicopter (its position = the scope
// centre): cargo beyond either limit is not hookable. 2D: horizontal
// distance heli-to-cargo. HEIGHT: how far the cargo top may sit BELOW the
// position (the hook hangs straight down). ABOVE: how far above the position
// the cargo top may be and still count - a vehicle parked under a grounded
// helicopter (a car roof ~2 m above the skids), which the engine's own
// canSlingLoad accepts.
#define SLING_ATTACH_2D 5
#define SLING_ATTACH_HEIGHT 10
#define SLING_ATTACH_ABOVE 5
