using Toybox.WatchUi;
using Toybox.Lang;

// Swipe = bladeren door kaarten + Sync-tegel. Tik op een kaart = code tonen,
// tik op de Sync-tegel = synchroniseren. Menu-knop (indien aanwezig) = favoriet.
class CardWalletDelegate extends WatchUi.BehaviorDelegate {

    var view as CardWalletView;

    function initialize(v as CardWalletView) {
        BehaviorDelegate.initialize();
        view = v;
    }

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
        if (view.onSyncTile()) {
            var sv = new SyncView();
            WatchUi.pushView(sv, new SyncDelegate(sv), WatchUi.SLIDE_LEFT);
            return true;
        }
        var card = view.current();
        if (card == null) {
            return true;
        }
        CardStore.markUsed(card.get("id") as Lang.String);
        var display = new CardDisplayView(card);
        WatchUi.pushView(display, new CardDisplayDelegate(display, card), WatchUi.SLIDE_LEFT);
        return true;
    }

    // Menu-knop / lang indrukken: acties voor de huidige kaart.
    function onMenu() as Lang.Boolean {
        var card = view.current();
        if (card == null) {
            return true; // op de Sync-tegel: geen menu
        }
        var menu = new WatchUi.Menu2({ :title => card.get("label") as Lang.String });
        var fav = card.get("favorite") == true;
        menu.addItem(new WatchUi.MenuItem(fav ? "Favoriet weghalen" : "Favoriet maken", null, "fav", {}));
        menu.addItem(new WatchUi.MenuItem("Verwijderen", null, "del", {}));
        WatchUi.pushView(menu, new WalletMenuDelegate(view, card.get("id") as Lang.String), WatchUi.SLIDE_UP);
        return true;
    }
}

// Acties-menu vanuit de wallet (favoriet / verwijderen).
class WalletMenuDelegate extends WatchUi.Menu2InputDelegate {
    var view as CardWalletView;
    var cardId as Lang.String;

    function initialize(v as CardWalletView, id as Lang.String) {
        Menu2InputDelegate.initialize();
        view = v;
        cardId = id;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        if (id.equals("fav")) {
            CardStore.toggleFavorite(cardId);
            view.onShow();
            WatchUi.popView(WatchUi.SLIDE_DOWN);
        } else if (id.equals("del")) {
            // Bevestiging tonen voordat er echt verwijderd wordt.
            var confirm = new WatchUi.Confirmation("Kaart verwijderen?");
            WatchUi.pushView(confirm, new DeleteConfirmDelegate(view, cardId), WatchUi.SLIDE_LEFT);
        }
    }
}

// Ja/nee-bevestiging voor verwijderen.
class DeleteConfirmDelegate extends WatchUi.ConfirmationDelegate {
    var view as CardWalletView;
    var cardId as Lang.String;

    function initialize(v as CardWalletView, id as Lang.String) {
        ConfirmationDelegate.initialize();
        view = v;
        cardId = id;
    }

    function onResponse(response as WatchUi.Confirm) as Lang.Boolean {
        if (response == WatchUi.CONFIRM_YES) {
            CardStore.deleteById(cardId);
            view.onShow();
            // De bevestiging sluit zichzelf; het onderliggende menu poppen we
            // zodat we terug bij de wallet uitkomen.
            WatchUi.popView(WatchUi.SLIDE_DOWN);
        }
        return true;
    }
}
