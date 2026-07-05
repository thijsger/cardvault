using Toybox.Application;
using Toybox.WatchUi;
using Toybox.Lang;

class CardVaultApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state as Lang.Dictionary?) as Void {
        // Bouw kaarten uit Garmin Connect-instellingen; bij lege instellingen
        // val terug op eerder via de webapp gesyncte kaarten.
        SettingsParser.reload();
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
