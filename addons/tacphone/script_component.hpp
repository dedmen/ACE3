#define COMPONENT tacphone
#define COMPONENT_BEAUTIFIED Tacphone
#include "\z\ace\addons\main\script_mod.hpp"

// #define DEBUG_MODE_FULL
// #define DISABLE_COMPILE_CACHE
// #define ENABLE_PERFORMANCE_COUNTERS

#ifdef DEBUG_ENABLED_TACPHONE
    #define DEBUG_MODE_FULL
#endif

#ifdef DEBUG_SETTINGS_TACPHONE
    #define DEBUG_SETTINGS DEBUG_SETTINGS_TACPHONE
#endif

#include "\z\ace\addons\main\script_macros.hpp"

#define PHONE_WIDTH 1.5
#define PHONE_HEIGHT 1

#define DISPLAY_MODE_CLOSED 0
#define DISPLAY_MODE_HUD 1
#define DISPLAY_MODE_DIALOG 2
#define DISPLAY_MODE_HIDDEN 3

#define IDC_TACPHONE_APP 1337
#define IDC_TACPHONE_BACKGROUND 1338
