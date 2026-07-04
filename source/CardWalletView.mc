using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.Lang;

// Wallet-weergave: één kaart tegelijk, groot en gecentreerd als een fysieke
// pas (met chip en gestapelde randjes), swipe omhoog/omlaag om te bladeren,
// tik om de scanbare code te tonen.
class CardWalletView extends WatchUi.View {

    var cards as Lang.Array<Lang.Dictionary>;
    var index as Lang.Number;

    function initialize() {
        View.initialize();
        cards = [] as Lang.Array<Lang.Dictionary>;
        index = 0;
    }

    function onShow() as Void {
        cards = CardStore.getCards();
        if (index >= cards.size()) {
            index = (cards.size() > 0) ? cards.size() - 1 : 0;
        }
        WatchUi.requestUpdate();
    }

    function count() as Lang.Number {
        return cards.size();
    }

    function current() as Lang.Dictionary? {
        if (cards.size() == 0) {
            return null;
        }
        return cards[index];
    }

    function next() as Void {
        if (cards.size() > 0) {
            index = (index + 1) % cards.size();
            WatchUi.requestUpdate();
        }
    }

    function prev() as Void {
        if (cards.size() > 0) {
            index = (index - 1 + cards.size()) % cards.size();
            WatchUi.requestUpdate();
        }
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var w = dc.getWidth();
        var h = dc.getHeight();
        var cx = w / 2;
        var cy = h / 2;

        if (cards.size() == 0) {
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, cy - 24, Graphics.FONT_SMALL, "CardVault",
                Graphics.TEXT_JUSTIFY_CENTER);
            dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, cy + 14, Graphics.FONT_XTINY, "Voeg kaarten toe",
                Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(cx, cy + 36, Graphics.FONT_XTINY, "via Garmin Connect",
                Graphics.TEXT_JUSTIFY_CENTER);
            return;
        }

        var card = cards[index];
        var color = card.get("color") as Lang.Number;

        var cardW = (w * 0.76).toNumber();
        var cardH = (h * 0.56).toNumber();
        var cardX = cx - cardW / 2;
        var cardY = cy - cardH / 2 - 10;
        var radius = 22;

        // Gestapelde randjes (deck-gevoel) achter de hoofdkaart.
        if (cards.size() > 1) {
            dc.setColor(0x2A2A2A, Graphics.COLOR_TRANSPARENT);
            dc.fillRoundedRectangle(cardX + 16, cardY - 12, cardW - 32, cardH, radius);
            dc.setColor(0x1E1E1E, Graphics.COLOR_TRANSPARENT);
            dc.fillRoundedRectangle(cardX + 26, cardY - 22, cardW - 52, cardH, radius);
        }

        // De kaart zelf.
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(cardX, cardY, cardW, cardH, radius);

        var textColor = textColorFor(color);
        var dimColor = textColorDim(color);

        // Chip (zoals op een bankpas), goudkleurig.
        var chipX = cardX + 26;
        var chipY = cardY + 26;
        dc.setColor(0xD4AF37, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(chipX, chipY, 46, 34, 6);
        dc.setColor(0x8A7020, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(chipX + 15, chipY, chipX + 15, chipY + 34);
        dc.drawLine(chipX + 31, chipY, chipX + 31, chipY + 34);
        dc.drawLine(chipX, chipY + 17, chipX + 46, chipY + 17);

        // Type-indicator rechtsboven.
        var type = card.get("type") as Lang.String;
        dc.setColor(dimColor, Graphics.COLOR_TRANSPARENT);
        var typeLabel = type.equals("totp") ? "2FA" : "CARD";
        dc.drawText(cardX + cardW - 22, cardY + 24, Graphics.FONT_XTINY, typeLabel,
            Graphics.TEXT_JUSTIFY_RIGHT);

        // Favoriet-ster rechtsonder.
        if (card.get("favorite") == true) {
            dc.setColor(textColor, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cardX + cardW - 20, cardY + cardH - 44, Graphics.FONT_SMALL, "*",
                Graphics.TEXT_JUSTIFY_RIGHT);
        }

        // Naam + subtekst linksonder, zoals de naam op een pas.
        var sub = card.get("sublabel") as Lang.String;
        var hasSub = (sub != null && sub.length() > 0);

        // Naam-font krimpt als de naam te breed is voor de kaart.
        var name = card.get("label") as Lang.String;
        var nameFont = Graphics.FONT_SMALL;
        if (dc.getTextWidthInPixels(name, nameFont) > cardW - 44) {
            nameFont = Graphics.FONT_XTINY;
        }
        var nameH = dc.getFontHeight(nameFont);
        var subH = dc.getFontHeight(Graphics.FONT_XTINY);
        var bottomMargin = 16;

        if (hasSub) {
            // Subtekst onderaan met vaste marge; naam er ruim boven.
            var subY = cardY + cardH - bottomMargin - subH;
            var nameY = subY - 14 - nameH;
            dc.setColor(textColor, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cardX + 24, nameY, nameFont, name, Graphics.TEXT_JUSTIFY_LEFT);
            dc.setColor(dimColor, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cardX + 24, subY, Graphics.FONT_XTINY, sub, Graphics.TEXT_JUSTIFY_LEFT);
        } else {
            dc.setColor(textColor, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cardX + 24, cardY + cardH - bottomMargin - nameH, nameFont, name,
                Graphics.TEXT_JUSTIFY_LEFT);
        }

        // Pagina-stipjes onder de kaart.
        drawDots(dc, cx, cardY + cardH + 20);
    }

    function drawDots(dc as Graphics.Dc, cx as Lang.Number, y as Lang.Number) as Void {
        var n = cards.size();
        if (n <= 1) {
            return;
        }
        var maxDots = 7;
        var shown = (n < maxDots) ? n : maxDots;
        var spacing = 16;
        var startX = cx - ((shown - 1) * spacing) / 2;
        for (var i = 0; i < shown; i++) {
            var active = (i == index) || (shown < n && i == shown - 1 && index >= shown - 1);
            if (i == index) {
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                dc.fillCircle(startX + i * spacing, y, 4);
            } else {
                dc.setColor(0x555555, Graphics.COLOR_TRANSPARENT);
                dc.fillCircle(startX + i * spacing, y, 3);
            }
        }
    }

    // Zwarte of witte tekst afhankelijk van de kaartkleur.
    function textColorFor(color as Lang.Number) as Lang.Number {
        return (luma(color) > 140) ? Graphics.COLOR_BLACK : Graphics.COLOR_WHITE;
    }

    // Iets gedempte variant voor subtekst.
    function textColorDim(color as Lang.Number) as Lang.Number {
        return (luma(color) > 140) ? 0x404040 : 0xC8C8C8;
    }

    function luma(color as Lang.Number) as Lang.Number {
        var r = (color >> 16) & 0xFF;
        var g = (color >> 8) & 0xFF;
        var b = color & 0xFF;
        return (r * 299 + g * 587 + b * 114) / 1000;
    }
}
