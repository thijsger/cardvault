using Toybox.Application;
using Toybox.WatchUi;
using Toybox.Lang;

class CardVaultApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state as Lang.Dictionary?) as Void {
        // TIJDELIJKE TESTDATA voor visuele controle in de simulator.
        var test = "barcode|Sportschool|Lidmaatschap|blue|card|9501101530003|CODE128|Sport\n"
                 + "totp|GitHub|jij@mail.com|dkgray|lock|JBSWY3DPEHPK3PXP|SHA1:6:30|2FA\n"
                 + "qr|Concertticket|Zaal 4|purple|ticket|https://cardvault.app/t/9F2A|QR|Tickets";
        SettingsParser.reloadFromText(test);
    }

    function onStop(state as Lang.Dictionary?) as Void {}

    function onSettingsChanged() as Void {
        SettingsParser.reload();
        WatchUi.requestUpdate();
    }

    function getInitialView() as [WatchUi.Views] or [WatchUi.Views, WatchUi.InputDelegates] {
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
