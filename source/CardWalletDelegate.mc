using Toybox.WatchUi;
using Toybox.Lang;

// Swipe omhoog/omlaag = bladeren, tik = scanbare code tonen, menu = favoriet.
class CardWalletDelegate extends WatchUi.BehaviorDelegate {

    var view as CardWalletView;

    function initialize(v as CardWalletView) {
        BehaviorDelegate.initialize();
        view = v;
    }

    // Horizontaal vegen om door de kaarten te bladeren (wallet-gevoel).
    function onSwipe(swipeEvent as WatchUi.SwipeEvent) as Lang.Boolean {
        var dir = swipeEvent.getDirection();
        if (dir == WatchUi.SWIPE_LEFT) {
            view.next();
            return true;
        } else if (dir == WatchUi.SWIPE_RIGHT) {
            view.prev();
            return true;
        }
        return false;
    }

    // Op knop-toestellen (geen touch): omhoog/omlaag bladeren.
    function onNextPage() as Lang.Boolean {
        view.next();
        return true;
    }

    function onPreviousPage() as Lang.Boolean {
        view.prev();
        return true;
    }

    function onSelect() as Lang.Boolean {
        var card = view.current();
        if (card == null) {
            return true;
        }
        CardStore.markUsed(card.get("id") as Lang.String);
        var display = new CardDisplayView(card);
        WatchUi.pushView(display, new CardDisplayDelegate(display, card), WatchUi.SLIDE_LEFT);
        return true;
    }

    function onMenu() as Lang.Boolean {
        var menu = new WatchUi.Menu2({ :title => "Menu" });
        menu.addItem(new WatchUi.MenuItem("Sync met webapp", null, "sync", {}));
        if (view.current() != null) {
            var fav = view.current().get("favorite") == true;
            menu.addItem(new WatchUi.MenuItem(fav ? "Favoriet weghalen" : "Favoriet maken", null, "fav", {}));
        }
        WatchUi.pushView(menu, new WalletMenuDelegate(view), WatchUi.SLIDE_UP);
        return true;
    }
}

// Acties-menu vanuit de wallet.
class WalletMenuDelegate extends WatchUi.Menu2InputDelegate {
    var view as CardWalletView;

    function initialize(v as CardWalletView) {
        Menu2InputDelegate.initialize();
        view = v;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        if (id.equals("sync")) {
            WatchUi.popView(WatchUi.SLIDE_DOWN);
            var sv = new SyncView();
            WatchUi.pushView(sv, new SyncDelegate(sv), WatchUi.SLIDE_LEFT);
        } else if (id.equals("fav")) {
            var card = view.current();
            if (card != null) {
                CardStore.toggleFavorite(card.get("id") as Lang.String);
                view.onShow();
            }
            WatchUi.popView(WatchUi.SLIDE_DOWN);
        }
    }
}
