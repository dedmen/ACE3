class EGVAR(tacphone,apps) {
    class ACE_TacPhone_Vehicle {
        scope = 2;
        icon = "\A3\ui_f\data\map\markers\nato\n_air.paa"; // Reserved: panel icons come from GetTacPhoneIcon() in the web app
        EGVAR(tacphone,file) = QPATHTOF(data\ace_tacphone_vehicle.js); // The file that websource build will output
        EGVAR(tacphone,devFile) = "src\main.tsx"; // Path, relative to the app folder, which contains the main entry point (what will be imported into the main UI)
        EGVAR(tacphone,requestProcessor) = QFUNC(processBrowserRequest); // Name of script function that processes requests for this app
    };
};
