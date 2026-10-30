class Extended_PreStart_EventHandlers {
    class ADDON {
        init = QUOTE(call COMPILE_SCRIPT(XEH_preStart));
    };
};

class Extended_PreInit_EventHandlers {
    class ADDON {
        init = QUOTE(call COMPILE_SCRIPT(XEH_preInit));
    };
};

class Extended_PostInit_EventHandlers {
    class ADDON {
        init = QUOTE(call COMPILE_SCRIPT(XEH_postInit));
        clientInit = QUOTE(call COMPILE_SCRIPT(XEH_clientInit));
    };
};

// Keep the layout editor's height for the phone in sync with the height the HUD actually draws
class Extended_DisplayUnload_EventHandlers {
    class RscDisplayOptionsLayout {
        ADDON = QUOTE([] call FUNC(syncGridHeight));
    };
};
