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

// Seconds between two Vehicle.Anim pushes while the interest is held.
#define ANIM_UPDATE_INTERVAL 0.2

// Seconds between two Vehicle.State pushes while the interest is held.
#define STATE_UPDATE_INTERVAL 0.05
