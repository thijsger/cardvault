using Toybox.WatchUi;
using Toybox.Lang;
using Toybox.Communications;
using Toybox.Application.Storage;

// Wallet-besturing: swipe = bladeren, tik op een kaart = code tonen, tik op de
// Sync-tegel = synchroniseren, tik op het menu-knopje (drie puntjes) = acties.
class CardWalletDelegate extends WatchUi.BehaviorDelegate {

    var view as CardWalletView;

    function initialize(v as CardWalletView) {
        BehaviorDelegate.initialize();
        view = v;
    }

    // Horizontaal vegen = bladeren. Verticaal vegen NIET gebruiken: op sommige
    // toestellen (bv. Vivoactive 4) sluit omhoog vegen de app af.
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

    // Touch: tik op de menu-knop (bovenrand) opent het menu, elders = primair.
    function onTap(clickEvent as WatchUi.ClickEvent) as Lang.Boolean {
        var coords = clickEvent.getCoordinates();
        if (coords != null && view.isMenuTap(coords[0], coords[1], view.screenW, view.screenH)) {
            openMenu();
            return true;
        }
        primaryAction();
        return true;
    }

    // Lang indrukken / menu-knop opent het menu (device-onafhankelijk).
    function onMenu() as Lang.Boolean {
        openMenu();
        return true;
    }

    // Fysieke select-knop: primaire actie (kaart/sync openen).
    function onSelect() as Lang.Boolean {
        primaryAction();
        return true;
    }

    // Fysieke omhoog/omlaag-knoppen (bv. Vivoactive 4): bladeren.
    function onNextPage() as Lang.Boolean {
        view.next();
        return true;
    }

    function onPreviousPage() as Lang.Boolean {
        view.prev();
        return true;
    }

    function primaryAction() as Void {
        if (view.onSyncTile()) {
            // Tik op de sync-tegel = meteen ophalen (geen tussenscherm).
            doSync();
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

    // Haalt kaarten op en toont de status op de sync-tegel zelf.
    function doSync() as Void {
        // Sync is nu bewust gebruikt: zet auto-sync bij volgende starts aan.
        Storage.setValue("syncEnabled", true);
        view.syncStatus = "Fetching...";
        WatchUi.requestUpdate();
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
            var added = SettingsParser.mergeFromText(text);
            view.syncStatus = added.toString() + " new card(s)";
        } else if (code == 200) {
            view.syncStatus = "Nothing found";
        } else {
            view.syncStatus = "No connection";
        }
        view.onShow();
    }

    function openMenu() as Void {
        var menu = new WatchUi.Menu2({ :title => "CardVault" });
        var card = view.current();
        if (card != null) {
            var fav = card.get("favorite") == true;
            menu.addItem(new WatchUi.MenuItem(fav ? "Remove favorite" : "Make favorite", null, "fav", {}));
            menu.addItem(new WatchUi.MenuItem("Edit name", null, "name", {}));
            menu.addItem(new WatchUi.MenuItem("Edit subtitle", null, "sub", {}));
            menu.addItem(new WatchUi.MenuItem("Change color", null, "color", {}));
            menu.addItem(new WatchUi.MenuItem("Delete card", null, "del", {}));
        }
        menu.addItem(new WatchUi.MenuItem(Pin.isSet() ? "Change PIN" : "Set PIN", null, "pinset", {}));
        if (Pin.isSet()) {
            menu.addItem(new WatchUi.MenuItem("Turn off PIN", null, "pinoff", {}));
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
                var ev = new TextEditView(view, card.get("id") as Lang.String, "label", card.get("label") as Lang.String, "Name");
                WatchUi.pushView(ev, new TextEditDelegate(ev), WatchUi.SLIDE_LEFT);
            }

        } else if (id.equals("sub")) {
            if (card != null) {
                WatchUi.popView(WatchUi.SLIDE_DOWN);
                var sub = card.get("sublabel");
                var cur = (sub == null) ? "" : sub.toString();
                var ev = new TextEditView(view, card.get("id") as Lang.String, "sublabel", cur, "Subtitle");
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
                var confirm = new WatchUi.Confirmation("Delete card?");
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
