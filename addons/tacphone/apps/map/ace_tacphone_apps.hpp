class EGVAR(tacphone,apps) {
    class Map {
        scope = 2;
        icon = "\A3\ui_f\data\map\markers\nato\c_ship.paa"; // Image TBD
        GVAR(file) = QPATHTOF(data\ace_tacphone_map.js); // The file that websource build will output
        GVAR(devFile) = QPATHTOF(src\main.tsx); // Path, relative to websource folder, which contains the main entry point (what will be imported into the main UI)
    }
};
