// The game's CfgNotifications::Default is declared as an external base child
// class (skeleton) so the templates below can inherit its fields (including
// sound) by simple name; the game config fills the skeleton at merge time.
class CfgNotifications
{
    class Default;

    class GVAR(NotifyInfo) : Default
    {
        title = "%1";
        description = "%2";
        iconPicture = "%3";
        priority = 0;
        duration = 5;
        color[] = {
            "(profilenamespace getvariable ['IGUI_TEXT_RGB_R',0])",
            "(profilenamespace getvariable ['IGUI_TEXT_RGB_G',1])",
            "(profilenamespace getvariable ['IGUI_TEXT_RGB_B',1])",
            "(profilenamespace getvariable ['IGUI_TEXT_RGB_A',0.8])"
        };
    };

    class GVAR(NotifySuccess) : Default
    {
        title = "%1";
        description = "%2";
        iconPicture = "%3";
        priority = 0;
        duration = 5;
        color[] = {0.55,0.85,0.35,1};
    };

    class GVAR(NotifyAlert) : Default
    {
        title = "%1";
        description = "%2";
        iconPicture = "%3";
        priority = 0;
        duration = 7;
        color[] = {1,0.75,0.25,1};
    };
};
