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

    // Menu-knop (indien het toestel er een heeft): favoriet aan/uit.
    function onMenu() as Lang.Boolean {
        var card = view.current();
        if (card != null) {
            CardStore.toggleFavorite(card.get("id") as Lang.String);
            view.onShow();
        }
        return true;
    }
}
