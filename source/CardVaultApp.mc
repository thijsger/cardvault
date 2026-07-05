using Toybox.Application;
using Toybox.Application.Storage;
using Toybox.WatchUi;
using Toybox.Lang;
using Toybox.Communications;

class CardVaultApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state as Lang.Dictionary?) as Void {
        // TEMPORARY: demo cards for promo screenshots (English). Altijd forceren
        // zodat de simulator-opslag ze niet overslaat.
        SettingsParser.reloadFromText(
            "barcode|Supermarket|Loyalty card|orange|card|9501101530003|CODE128|Stores\n" +
            "totp|GitHub|you@mail.com|dkgray|lock|JBSWY3DPEHPK3PXP|SHA1:6:30|2FA\n" +
            "qr|Concert ticket|Hall 4|purple|ticket|https://cardvault.app/t/9F2A|QR|Tickets\n" +
            "barcode|Gym|Membership|blue|card|9780201379624|CODE128|Sport\n" +
            "totp|Google|you@gmail.com|red|lock|JBSWY3DPEHPK3PXP|SHA1:6:30|2FA\n" +
            "barcode|Library|Card no.|green|book|ABC-1234567|CODE128|Other");
    }

    // Haalt stil kaarten op voor de koppelcode; nieuwe verschijnen vanzelf.
    function autoSync() as Void {
        Communications.makeWebRequest(
            Sync.pullUrl(),
            {},
            {
                :method => Communications.HTTP_REQUEST_METHOD_GET,
                :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_TEXT_PLAIN
            },
            method(:onSyncData)
        );
    }

    function onSyncData(code as Lang.Number, data as Lang.String or Null) as Void {
        if (code == 200 && data != null && data.toString().length() > 0) {
            var text = data.toString();
            Storage.setValue("syncText", text);
            SettingsParser.mergeFromText(text);
            WatchUi.requestUpdate();
        }
    }

    function onStop(state as Lang.Dictionary?) as Void {}

    function onSettingsChanged() as Void {
        // Nieuwe kaarten uit Garmin Connect toevoegen zonder bestaande te wissen.
        SettingsParser.mergeFromText(SettingsParser.rawSettingsText());
        WatchUi.requestUpdate();
    }

    function getInitialView() as [WatchUi.Views] or [WatchUi.Views, WatchUi.InputDelegates] {
        // Bij een ingestelde pincode eerst het slot tonen.
        if (Pin.isSet()) {
            var pv = new PinView(PinView.MODE_UNLOCK);
            return [pv, new PinDelegate(pv)];
        }
        var view = new CardWalletView();
        return [view, new CardWalletDelegate(view)];
    }

    (:glance)
    function getGlanceView() {
        return [new CardVaultGlanceView()];
    }
}

function getApp() as CardVaultApp {
    return Application.getApp() as CardVaultApp;
}
