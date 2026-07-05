using Toybox.WatchUi;
using Toybox.Lang;

class PinDelegate extends WatchUi.BehaviorDelegate {

    var view as PinView;

    function initialize(v as PinView) {
        BehaviorDelegate.initialize();
        view = v;
    }

    function onTap(clickEvent as WatchUi.ClickEvent) as Lang.Boolean {
        var coords = clickEvent.getCoordinates();
        var key = view.keyAt(coords[0], coords[1]);
        if (key.equals("")) {
            return true;
        }
        view.press(key);
        handleCommit();
        return true;
    }

    function handleCommit() as Void {
        var result = view.commit();
        if (result.equals("unlocked")) {
            // Vervang het slot door de wallet.
            var wallet = new CardWalletView();
            WatchUi.switchToView(wallet, new CardWalletDelegate(wallet), WatchUi.SLIDE_LEFT);
        } else if (result.equals("saved") || result.equals("disabled")) {
            WatchUi.popView(WatchUi.SLIDE_DOWN);
        }
        // "again" / "error" / "": op het scherm blijven.
    }

    // Bij het ontgrendel-scherm mag back de app niet zomaar verlaten... maar
    // Garmin sluit dan de app, wat prima is (alsof je 'm niet opent).
    function onBack() as Lang.Boolean {
        if (view.mode == PinView.MODE_UNLOCK) {
            return false; // standaardgedrag: app verlaten
        }
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }
}
