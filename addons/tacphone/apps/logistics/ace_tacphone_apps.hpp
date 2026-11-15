class EGVAR(tacphone,apps) {
    class ACE_TacPhone_Logistics {
        scope = 2;
        icon = "\A3\ui_f\data\map\markers\nato\c_ship.paa"; // Reserved: panel icons come from GetTacPhoneIcon() in the web app
        EGVAR(tacphone,file) = QPATHTOF(data\ace_tacphone_logistics.js); // The file that the websource build outputs
        EGVAR(tacphone,devFile) = "src\main.tsx"; // Entry point relative to the websource app folder
        EGVAR(tacphone,requestProcessor) = QFUNC(processBrowserRequest); // Request handler for this app
    };
};
