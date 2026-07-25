class EGVAR(tacphone,apps) {
    class ACE_TacPhone_Map {
        scope = 2;
        icon = "\A3\ui_f\data\map\markers\nato\c_ship.paa"; // Image TBD
        EGVAR(tacphone,file) = QPATHTOF(data\ace_tacphone_map.js); // The file that websource build will output
        EGVAR(tacphone,devFile) = "src\main.tsx"; // Path, relative to websource folder, which contains the main entry point (what will be imported into the main UI)
        EGVAR(tacphone,requestProcessor) = QFUNC(processBrowserRequest); // Name of script function that processes requests for this app
    };
};
