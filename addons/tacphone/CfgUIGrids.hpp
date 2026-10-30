class CfgUIGrids {
    class IGUI {
        class Presets {
            class Arma3 {
                class Variables {
                    grid_ACE_tacPhone[] = {
                        {
                            "(safeZoneX + safeZoneW - 10 * (((safeZoneW / safeZoneH) min 1.2) / 40))",
                            "(safeZoneY + safeZoneH - 8 * ((((safeZoneW / safeZoneH) min 1.2) / 1.2) / 25))",
                            "(10 * (((safeZoneW / safeZoneH) min 1.2) / 40))",
                            "(8 * ((((safeZoneW / safeZoneH) min 1.2) / 1.2) / 25))"
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
                preview = QPATHTOF(data\tx\icon_phone_ca.paa);
                saveToProfile[] = {0,1,2,3};
                canResize = 1;
            };
        };
    };
};
