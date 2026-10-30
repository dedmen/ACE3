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

// data\tx\phone_bg_ca.paa is a 1024x1024 texture with a transparent background.
// The visible phone body spans the full width and the vertical band y=257..747 (491px, aspect 2.0855:1).
// The UI has to be placed inside that band, and the texture must never be stretched.
#define TACPHONE_BG_BODY_TOP (257 / 1024)
#define TACPHONE_BG_BODY_HEIGHT (491 / 1024)
#define TACPHONE_BG_BODY_ASPECT (1024 / 491)

// Default width of the HUD element in layout grid units (must match the CfgUIGrids preset)
#define TACPHONE_DEFAULT_W (20 * (((safeZoneW / safeZoneH) min 1.2) / 40))

#define DISPLAY_MODE_CLOSED 0
#define DISPLAY_MODE_HUD 1
#define DISPLAY_MODE_DIALOG 2
#define DISPLAY_MODE_HIDDEN 3

#define IDC_TACPHONE_APP 1337
#define IDC_TACPHONE_BACKGROUND 1338
