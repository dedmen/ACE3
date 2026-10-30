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

#define PROFILE_X (profilenamespace getVariable ['IGUI_grid_ACE_tacPhone_X', 0])
#define PROFILE_Y (profilenamespace getVariable ['IGUI_grid_ACE_tacPhone_Y', 0])
#define PROFILE_W (profilenamespace getVariable ['IGUI_grid_ACE_tacPhone_W', 0.3])
#define PROFILE_H (profilenamespace getVariable ['IGUI_grid_ACE_tacPhone_H', 0.2])

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
				x = QUOTE(PROFILE_X);
				y = QUOTE(PROFILE_Y);
				w = QUOTE(PROFILE_W);
				h = QUOTE(PROFILE_H);
			};

			class AppSection: TacPhoneWebBrowserReference
			{
				idc = IDC_TACPHONE_APP;
				x = QUOTE(PROFILE_X + 0.04 * PROFILE_W);
				y = QUOTE(PROFILE_Y + 0.05 * PROFILE_H);
				w = QUOTE(0.92 * PROFILE_W);
				h = QUOTE(0.82 * PROFILE_H);
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

