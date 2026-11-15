class EGVAR(tacphone,apps) {
    class ACE_TacPhone_Radio {
        scope = 2;
        icon = "\A3\ui_f\data\map\markers\nato\o_hq.paa";
        EGVAR(tacphone,file) = QPATHTOF(data\ace_tacphone_radio.js); // The file that the websource build outputs
        EGVAR(tacphone,devFile) = "src\main.tsx"; // Entry point relative to the websource app folder
        EGVAR(tacphone,requestProcessor) = QFUNC(processBrowserRequest); // Request handler for this app
    };
};
