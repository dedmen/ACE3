class CfgUIGrids {
    class IGUI {
        class Presets {
            class Arma3 {
                class Variables {
                    grid_ACE_tacPhone[] = {
                        {
                            "(safeZoneX + safeZoneW - 21 * (((safeZoneW / safeZoneH) min 1.2) / 40))",
                            "(safeZoneY + safeZoneH - ((((safeZoneW / safeZoneH) min 1.2) / 1.2) / 25) - (20 * (((safeZoneW / safeZoneH) min 1.2) / 40) * (safeZoneW / safeZoneH) * (491 / 1024)))",
                            "(20 * (((safeZoneW / safeZoneH) min 1.2) / 40))",
                            "(20 * (((safeZoneW / safeZoneH) min 1.2) / 40) * (safeZoneW / safeZoneH) * (491 / 1024))"
                        },
                        "(((safeZoneW / safeZoneH) min 1.2) / 40)",
                        "((((safeZoneW / safeZoneH) min 1.2) / 1.2) / 25)"
                    };
                };
            };
        };

        class Variables {
            class grid_ACE_tacPhone {
                displayName = COMPONENT_NAME;
                description = "ACE TacPhone";
                // Cropped to the phone body (1024x512, 2:1) so the layout editor preview
                // lines up with where the HUD actually draws the phone.
                preview = QPATHTOF(data\tx\preview_phone_ca.paa);
                saveToProfile[] = {0,1,2,3};
                canResize = 1;
            };
        };
    };
};
