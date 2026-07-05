using Toybox.WatchUi;
using Toybox.Lang;

// Wallet-besturing: swipe = bladeren, tik op een kaart = code tonen, tik op de
// Sync-tegel = synchroniseren, tik op het menu-knopje (drie puntjes) = acties.
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
        } else if (dir == WatchUi.SWIPE_UP || dir == WatchUi.SWIPE_DOWN) {
            // Verticaal vegen opent het actiemenu.
            openMenu();
            return true;
        }
        return false;
    }

    // Touch: onderscheid het menu-knopje (bovenrand) van de rest.
    function onTap(clickEvent as WatchUi.ClickEvent) as Lang.Boolean {
        var coords = clickEvent.getCoordinates();
        if (coords != null && view.isMenuTap(coords[0], coords[1], view.screenW, view.screenH)) {
            openMenu();
            return true;
        }
        primaryAction();
        return true;
    }

    // Lang indrukken (standaard Garmin menu-gebaar op touch) opent het menu.
    function onMenu() as Lang.Boolean {
        openMenu();
        return true;
    }

    // Fysieke knop: primaire actie (kaart/sync openen).
    function onSelect() as Lang.Boolean {
        primaryAction();
        return true;
    }

    // Verticaal vegen komt op de Venu 3 binnen als onNextPage/onPreviousPage.
    // Bladeren doe je met horizontaal vegen, dus verticaal opent het menu.
    function onNextPage() as Lang.Boolean {
        openMenu();
        return true;
    }

    function onPreviousPage() as Lang.Boolean {
        openMenu();
        return true;
    }

    function primaryAction() as Void {
        if (view.onSyncTile()) {
            var sv = new SyncView();
            WatchUi.pushView(sv, new SyncDelegate(sv), WatchUi.SLIDE_LEFT);
            return;
        }
        var card = view.current();
        if (card == null) {
            return;
        }
        CardStore.markUsed(card.get("id") as Lang.String);
        var display = new CardDisplayView(card);
        WatchUi.pushView(display, new CardDisplayDelegate(display, card), WatchUi.SLIDE_LEFT);
    }

    function openMenu() as Void {
        var menu = new WatchUi.Menu2({ :title => "CardVault" });
        var card = view.current();
        if (card != null) {
            var fav = card.get("favorite") == true;
            menu.addItem(new WatchUi.MenuItem(fav ? "Favoriet weghalen" : "Favoriet maken", null, "fav", {}));
            menu.addItem(new WatchUi.MenuItem("Naam wijzigen", null, "name", {}));
            menu.addItem(new WatchUi.MenuItem("Subtitel wijzigen", null, "sub", {}));
            menu.addItem(new WatchUi.MenuItem("Kleur wijzigen", null, "color", {}));
            menu.addItem(new WatchUi.MenuItem("Kaart verwijderen", null, "del", {}));
        }
        menu.addItem(new WatchUi.MenuItem(Pin.isSet() ? "Pincode wijzigen" : "Pincode instellen", null, "pinset", {}));
        if (Pin.isSet()) {
            menu.addItem(new WatchUi.MenuItem("Pincode uitzetten", null, "pinoff", {}));
        }
        WatchUi.pushView(menu, new WalletMenuDelegate(view), WatchUi.SLIDE_UP);
    }
}

// Acties-menu.
class WalletMenuDelegate extends WatchUi.Menu2InputDelegate {
    var view as CardWalletView;

    function initialize(v as CardWalletView) {
        Menu2InputDelegate.initialize();
        view = v;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        var card = view.current();

        if (id.equals("fav")) {
            if (card != null) {
                CardStore.toggleFavorite(card.get("id") as Lang.String);
                view.onShow();
            }
            WatchUi.popView(WatchUi.SLIDE_DOWN);

        } else if (id.equals("name")) {
            if (card != null) {
                WatchUi.popView(WatchUi.SLIDE_DOWN);
                var ev = new TextEditView(view, card.get("id") as Lang.String, "label", card.get("label") as Lang.String, "Naam");
                WatchUi.pushView(ev, new TextEditDelegate(ev), WatchUi.SLIDE_LEFT);
            }

        } else if (id.equals("sub")) {
            if (card != null) {
                WatchUi.popView(WatchUi.SLIDE_DOWN);
                var sub = card.get("sublabel");
                var cur = (sub == null) ? "" : sub.toString();
                var ev = new TextEditView(view, card.get("id") as Lang.String, "sublabel", cur, "Subtitel");
                WatchUi.pushView(ev, new TextEditDelegate(ev), WatchUi.SLIDE_LEFT);
            }

        } else if (id.equals("color")) {
            if (card != null) {
                WatchUi.popView(WatchUi.SLIDE_DOWN);
                var cm = ColorPicker.build();
                WatchUi.pushView(cm, new ColorMenuDelegate(view, card.get("id") as Lang.String), WatchUi.SLIDE_LEFT);
            }

        } else if (id.equals("del")) {
            if (card != null) {
                var confirm = new WatchUi.Confirmation("Kaart verwijderen?");
                WatchUi.pushView(confirm, new DeleteConfirmDelegate(view, card.get("id") as Lang.String), WatchUi.SLIDE_LEFT);
            }

        } else if (id.equals("pinset")) {
            WatchUi.popView(WatchUi.SLIDE_DOWN);
            var pv = new PinView(PinView.MODE_SET);
            WatchUi.pushView(pv, new PinDelegate(pv), WatchUi.SLIDE_LEFT);

        } else if (id.equals("pinoff")) {
            WatchUi.popView(WatchUi.SLIDE_DOWN);
            var pd = new PinView(PinView.MODE_DISABLE);
            WatchUi.pushView(pd, new PinDelegate(pd), WatchUi.SLIDE_LEFT);
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
            WatchUi.popView(WatchUi.SLIDE_DOWN); // menu weg
        }
        return true;
    }
}
