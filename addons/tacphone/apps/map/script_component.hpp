// This file is only for use within ACE, you would not use this when creating 3rd party apps in stand-alone PBO's

#define APPNAME Map
#define COMPONENT_BEAUTIFIED Tacphone App Map

#include "..\script_component.hpp"

// Information interest that makes the game push marker updates to the interested clients
#define INTEREST_MARKERS "ACE_TacPhone_Map.markers"

// Information interest that makes the game push per-frame GPS updates to the interested clients
#define INTEREST_GPS "ACE_TacPhone_Map.gps"

// Seconds between two GPS.Update pushes while the interest is held
#define GPS_UPDATE_INTERVAL 0.1
