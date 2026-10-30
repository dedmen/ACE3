class RscText;
class RscPicture;
class RscDisplayEmpty;

class TacPhoneWebBrowserReference: RscText
{
    type = 108; // CT_CONTROL_REF
    idc = 1337;
    x = 0; // Full screen from corner to corner
    y = 0;
    w = 1;
    h = 1;
};

#define PROFILE_W (profilenamespace getVariable ['IGUI_grid_ACE_tacPhone_W', TACPHONE_DEFAULT_W])
// The grid element describes the phone body, not the square texture. Deriving the height from the
// width keeps the background texture at its native aspect ratio no matter how the user resizes it.
#define PROFILE_H (PROFILE_W * (safeZoneW / safeZoneH) * TACPHONE_BG_BODY_HEIGHT)
#define PROFILE_X (profilenamespace getVariable ['IGUI_grid_ACE_tacPhone_X', safeZoneX + safeZoneW - 21 * (((safeZoneW / safeZoneH) min 1.2) / 40)])
#define PROFILE_Y (profilenamespace getVariable ['IGUI_grid_ACE_tacPhone_Y', safeZoneY + safeZoneH - ((((safeZoneW / safeZoneH) min 1.2) / 1.2) / 25) - PROFILE_H])

// The background texture is square and the phone body is a horizontal band inside it
#define BG_IMAGE_W (PROFILE_W)
#define BG_IMAGE_H (PROFILE_W * (safeZoneW / safeZoneH))
#define BG_IMAGE_X (PROFILE_X)
#define BG_IMAGE_Y (PROFILE_Y - TACPHONE_BG_BODY_TOP * BG_IMAGE_H)

class RscTitles
{
	class GVAR(BackgroundBrowser)
	{
		idd = 13371337;
		fadein = 0; // Required parameters for RscTitles
		fadeout = 0;
		duration = 1e+011;

		onLoad = QUOTE(uiNamespace setVariable [ARR_2(QQGVAR(backgroundPhoneDisplay), _this select 0)]); // Store our Display in a variable so we can access it from script

		class controls
		{
			class Texture: RscText
			{
				type = 106; // CT_WEBBROWSER
				idc = 1337;
                x = 0; // Full screen from corner to corner
                y = 0;
                w = 1;
                h = 1;
                url = "file://z/ace/addons/tacphone/data/index.html";
                fade = 1; // fade out == alpha 0% == invisible
			};
		};
	};

	class GVAR(HUDDisplay)
	{
		idd = -1;
		movingEnable = 1;
		duration = 9999999;
		fadein = 0;
		fadeout = 0;
		onLoad = QUOTE(uiNamespace setVariable [ARR_2(QQGVAR(HUDDisplay),(_this select 0))]);

		class controls
		{
			class Background: RscPicture
			{
				idc = IDC_TACPHONE_BACKGROUND;
				text = QPATHTOF(data\tx\phone_bg_ca.paa);
				x = QUOTE(BG_IMAGE_X);
				y = QUOTE(BG_IMAGE_Y);
				w = QUOTE(BG_IMAGE_W);
				h = QUOTE(BG_IMAGE_H);
			};

			class AppSection: TacPhoneWebBrowserReference
			{
				idc = IDC_TACPHONE_APP;
				// Inset by the rounded corner radius so the rectangular browser stays inside the phone body
				x = QUOTE(PROFILE_X + 0.015 * PROFILE_W);
				y = QUOTE(PROFILE_Y + 0.03 * PROFILE_H);
				w = QUOTE(0.97 * PROFILE_W);
				h = QUOTE(0.94 * PROFILE_H);
			};
		};
	};
};

class GVAR(InteractiveDialog): RscDisplayEmpty
{
	idd = -1;
	movingEnable = 1;
	onLoad = QUOTE(uiNamespace setVariable [ARR_2(QQGVAR(InteractiveDialog),(_this select 0))]);
	onUnload = QUOTE([] call FUNC(dialogClosedEH));
};

