using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.Lang;

// Eenvoudige tekst-editor voor op het horloge. Bediening met de gebaren die
// op de Venu 3 werken:
//   horizontaal vegen = door de tekens bladeren
//   tik / knop        = geselecteerd teken toevoegen
//   verticaal vegen   = laatste teken wissen
//   terug             = opslaan en sluiten
class TextEditView extends WatchUi.View {

    const ALPHABET =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789 .-@";

    var title as Lang.String;
    var text as Lang.String;
    var cursor as Lang.Number; // index in ALPHABET
    var cardId as Lang.String;
    var field as Lang.String;  // "label" of "sublabel"
    var walletView as CardWalletView;

    function initialize(wallet as CardWalletView, id as Lang.String, fld as Lang.String, current as Lang.String, ttl as Lang.String) {
        View.initialize();
        walletView = wallet;
        cardId = id;
        field = fld;
        text = current;
        title = ttl;
        cursor = 0;
    }

    function moveCursor(delta as Lang.Number) as Void {
        var n = ALPHABET.length();
        cursor = (cursor + delta + n) % n;
        WatchUi.requestUpdate();
    }

    function addChar() as Void {
        if (text.length() < 20) {
            text += ALPHABET.substring(cursor, cursor + 1);
            WatchUi.requestUpdate();
        }
    }

    function backspace() as Void {
        if (text.length() > 0) {
            text = text.substring(0, text.length() - 1);
            WatchUi.requestUpdate();
        }
    }

    function save() as Void {
        CardStore.updateField(cardId, field, text);
        walletView.onShow();
    }

    function charAt(offset as Lang.Number) as Lang.String {
        var n = ALPHABET.length();
        var idx = (cursor + offset + n) % n;
        var c = ALPHABET.substring(idx, idx + 1);
        return c.equals(" ") ? "_" : c;
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();
        var w = dc.getWidth();
        var h = dc.getHeight();
        var cx = w / 2;

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 0.12, Graphics.FONT_XTINY, title, Graphics.TEXT_JUSTIFY_CENTER);

        // Huidige tekst.
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        var shown = (text.length() == 0) ? "..." : text;
        dc.drawText(cx, h * 0.30, Graphics.FONT_SMALL, shown, Graphics.TEXT_JUSTIFY_CENTER);

        // Tekenwiel: buur-links, groot midden, buur-rechts.
        var midY = (h * 0.55).toNumber();
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx - 70, midY, Graphics.FONT_MEDIUM, charAt(-1), Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(cx + 70, midY, Graphics.FONT_MEDIUM, charAt(1), Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(0x5B9DFF, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, midY, Graphics.FONT_NUMBER_MEDIUM, charAt(0), Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Hints.
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 0.76, Graphics.FONT_XTINY, "veeg = kies  tik = toevoegen", Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(cx, h * 0.83, Graphics.FONT_XTINY, "omhoog = wis  terug = klaar", Graphics.TEXT_JUSTIFY_CENTER);
    }
}

class TextEditDelegate extends WatchUi.BehaviorDelegate {
    var view as TextEditView;

    function initialize(v as TextEditView) {
        BehaviorDelegate.initialize();
        view = v;
    }

    function onSwipe(swipeEvent as WatchUi.SwipeEvent) as Lang.Boolean {
        var dir = swipeEvent.getDirection();
        if (dir == WatchUi.SWIPE_LEFT) { view.moveCursor(1); return true; }
        if (dir == WatchUi.SWIPE_RIGHT) { view.moveCursor(-1); return true; }
        return true;
    }

    function onSelect() as Lang.Boolean {
        view.addChar();
        return true;
    }

    // Verticaal vegen = wissen.
    function onNextPage() as Lang.Boolean { view.backspace(); return true; }
    function onPreviousPage() as Lang.Boolean { view.backspace(); return true; }

    // Terug = opslaan en sluiten.
    function onBack() as Lang.Boolean {
        view.save();
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }
}
