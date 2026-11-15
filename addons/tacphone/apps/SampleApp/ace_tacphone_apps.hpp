class EGVAR(tacphone,apps) {
    // The class name is the routing key and may be any valid config class name,
    // but every app in this repo uses the ACE_TacPhone_<Name> form.
    class SampleApp {
        scope = 2;
        icon = "\A3\ui_f\data\map\markers\nato\c_ship.paa"; // Reserved: panel icons come from GetTacPhoneIcon() in the web app
        EGVAR(tacphone,file) = QPATHTOF(data\ace_tacphone_sampleapp.js); // The file that the websource build outputs
        EGVAR(tacphone,devFile) = "src\main.tsx"; // Entry point relative to the websource app folder
        EGVAR(tacphone,requestProcessor) = QFUNC(processBrowserRequest); // Request handler for this app
    };
};
