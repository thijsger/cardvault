using Toybox.Lang;
using Toybox.Application.Storage;
using Toybox.Math;

// Koppeling met de CardVault-webapp/server. Het horloge heeft een vaste,
// eenmalig gegenereerde koppelcode; de webapp stuurt kaarten naar die code,
// het horloge haalt ze op.
module Sync {

    // Pas dit aan naar jouw Render-URL na deploy (zonder schuine streep aan het eind).
    const SERVER_URL = "https://cardvault.onrender.com";

    const CODE_CHARS = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"; // zonder I,O,0,1 (verwarrend)

    // Vaste koppelcode voor dit toestel (4 tekens), eenmalig aangemaakt.
    (:glance)
    function deviceCode() as Lang.String {
        var c = Storage.getValue("deviceCode");
        if (c != null && c.toString().length() == 4) {
            return c.toString();
        }
        var code = "";
        for (var i = 0; i < 4; i++) {
            var idx = (Math.rand() % CODE_CHARS.length()).abs();
            code += CODE_CHARS.substring(idx, idx + 1);
        }
        Storage.setValue("deviceCode", code);
        return code;
    }

    (:glance)
    function pullUrl() as Lang.String {
        return SERVER_URL + "/api/pull?code=" + deviceCode();
    }
}
