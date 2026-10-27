class RscText;

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
};

class TacPhoneWebBrowser: RscText
{
    type = 106; // CT_WEBBROWSER
    idc = 1337;
    x = 0; // Full screen from corner to corner
    y = 0;
    w = 1;
    h = 1;
    url = "file://z/ace/addons/tacphone/data/index.html";
};


class TacPhoneWebBrowserReference: RscText
{
    type = 108; // CT_CONTROL_REF
    idc = 1337;
    x = 0; // Full screen from corner to corner
    y = 0;
    w = 1;
    h = 1;
};
