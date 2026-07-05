using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.Lang;
using Toybox.System;

// Wallet-weergave: één kaart tegelijk, groot en gecentreerd als een fysieke
// pas (met chip en gestapelde randjes), swipe omhoog/omlaag om te bladeren,
// tik om de scanbare code te tonen.
class CardWalletView extends WatchUi.View {

    var cards as Lang.Array<Lang.Dictionary>;
    var index as Lang.Number;
    var screenW as Lang.Number;
    var screenH as Lang.Number;
    var syncStatus as Lang.String;

    function initialize() {
        View.initialize();
        cards = [] as Lang.Array<Lang.Dictionary>;
        index = 0;
        syncStatus = "";
        // Schermmaat direct betrouwbaar ophalen (niet wachten op onLayout).
        var ds = System.getDeviceSettings();
        screenW = ds.screenWidth;
        screenH = ds.screenHeight;
    }

    function onLayout(dc as Graphics.Dc) as Void {
        screenW = dc.getWidth();
        screenH = dc.getHeight();
    }

    function onShow() as Void {
        cards = CardStore.getCards();
        // slides = alle kaarten + 1 Sync-tegel aan het eind.
        if (index >= slideCount()) {
            index = slideCount() - 1;
        }
        if (index < 0) { index = 0; }
        WatchUi.requestUpdate();
    }

    // Aantal slides incl. de Sync-tegel.
    function slideCount() as Lang.Number {
        return cards.size() + 1;
    }

    // true als we op de Sync-tegel staan (de laatste slide).
    function onSyncTile() as Lang.Boolean {
        return index == cards.size();
    }

    function current() as Lang.Dictionary? {
        if (onSyncTile() || cards.size() == 0) {
            return null;
        }
        return cards[index];
    }

    function next() as Void {
        index = (index + 1) % slideCount();
        WatchUi.requestUpdate();
    }

    function prev() as Void {
        index = (index - 1 + slideCount()) % slideCount();
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var w = dc.getWidth();
        var h = dc.getHeight();
        var cx = w / 2;
        var cy = h / 2;

        // Hint onderaan: veeg omhoog voor het actiemenu.
        drawMenuHint(dc, cx, h);

        // Laatste slide = Sync-tegel.
        if (onSyncTile()) {
            drawSyncTile(dc, cx, cy, w, h);
            drawDots(dc, cx, cy + (h * 0.28).toNumber() + 30);
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

        // Chip (zoals op een bankpas), goudkleurig. Penbreedte expliciet op 1
        // zetten — een vorige weergave (barcode/QR) kan 'm dik hebben gelaten.
        dc.setPenWidth(1);
        var chipX = cardX + 26;
        var chipY = cardY + 28;
        var chipW = 44;
        var chipH = 32;
        dc.setColor(0xD4AF37, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(chipX, chipY, chipW, chipH, 6);
        // Eén subtiel middenlijntje: strakker dan een raster.
        dc.setColor(0x9A7B20, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(chipX + chipW / 2 - 1, chipY + 6, 2, chipH - 12);
        dc.fillRectangle(chipX + 8, chipY + chipH / 2 - 1, chipW - 16, 2);

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
        var maxTextW = cardW - 40;

        // Naam: kies het grootste font dat past.
        var name = card.get("label") as Lang.String;
        var nameFont = fitFont(dc, name, maxTextW,
            [Graphics.FONT_MEDIUM, Graphics.FONT_SMALL, Graphics.FONT_TINY, Graphics.FONT_XTINY]);
        var nameH = dc.getFontHeight(nameFont);
        var subH = dc.getFontHeight(Graphics.FONT_XTINY);
        var bottomMargin = 16;

        if (hasSub) {
            // Subtekst onderaan met vaste marge; naam er ruim boven.
            var subFont = fitFont(dc, sub, maxTextW, [Graphics.FONT_XTINY]);
            var subY = cardY + cardH - bottomMargin - subH;
            var nameY = subY - 12 - nameH;
            dc.setColor(textColor, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cardX + 24, nameY, nameFont, name, Graphics.TEXT_JUSTIFY_LEFT);
            dc.setColor(dimColor, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cardX + 24, subY, subFont, sub, Graphics.TEXT_JUSTIFY_LEFT);
        } else {
            dc.setColor(textColor, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cardX + 24, cardY + cardH - bottomMargin - nameH, nameFont, name,
                Graphics.TEXT_JUSTIFY_LEFT);
        }

        // Pagina-stipjes onder de kaart.
        drawDots(dc, cx, cardY + cardH + 20);
    }

    // Sync-tegel: altijd bereikbaar door voorbij de laatste kaart te swipen.
    function drawSyncTile(dc as Graphics.Dc, cx as Lang.Number, cy as Lang.Number, w as Lang.Number, h as Lang.Number) as Void {
        var tileW = (w * 0.76).toNumber();
        var tileH = (h * 0.56).toNumber();
        var tx = cx - tileW / 2;
        var ty = cy - tileH / 2 - 10;

        dc.setColor(0x1A2A3A, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(tx, ty, tileW, tileH, 22);

        // "SYNC" bovenaan, "Koppelcode" eronder, dan de grote code gecentreerd.
        dc.setColor(0x5B9DFF, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, ty + 20, Graphics.FONT_TINY, "SYNC", Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, ty + 54, Graphics.FONT_XTINY, "Koppelcode", Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, ty + tileH / 2 + 14, Graphics.FONT_NUMBER_MEDIUM, Sync.deviceCode(),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Onderaan: status na een sync, anders de tik-hint.
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        var bottom = syncStatus.equals("") ? "Tik om op te halen" : syncStatus;
        dc.drawText(cx, ty + tileH - 46, Graphics.FONT_XTINY, bottom, Graphics.TEXT_JUSTIFY_CENTER);
    }

    // Y-positie van het menu-knopje.
    function menuIconY(h as Lang.Number) as Lang.Number {
        return (h * 0.14).toNumber();
    }

    // Subtiele hint: pijltje omhoog + "menu" onderaan het scherm.
    function drawMenuHint(dc as Graphics.Dc, cx as Lang.Number, h as Lang.Number) as Void {
        var y = (h * 0.88).toNumber();
        dc.setColor(0x777777, Graphics.COLOR_TRANSPARENT);
        // klein pijltje omhoog
        dc.fillPolygon([[cx - 6, y + 2], [cx + 6, y + 2], [cx, y - 5]]);
        dc.drawText(cx, y + 6, Graphics.FONT_XTINY, "menu", Graphics.TEXT_JUSTIFY_CENTER);
    }

    // Ligt (x,y) op het menu-knopje? Hele bovenrand telt, zodat het makkelijk
    // te raken is (de kaartinhoud staat in het midden).
    function isMenuTap(x as Lang.Number, y as Lang.Number, w as Lang.Number, h as Lang.Number) as Lang.Boolean {
        return y < (h * 0.24).toNumber();
    }

    function drawDots(dc as Graphics.Dc, cx as Lang.Number, y as Lang.Number) as Void {
        var n = slideCount();
        if (n <= 1) {
            return;
        }
        var maxDots = 8;
        var shown = (n < maxDots) ? n : maxDots;
        var spacing = 16;
        var startX = cx - ((shown - 1) * spacing) / 2;
        for (var i = 0; i < shown; i++) {
            if (i == index) {
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                dc.fillCircle(startX + i * spacing, y, 4);
            } else {
                dc.setColor(0x555555, Graphics.COLOR_TRANSPARENT);
                dc.fillCircle(startX + i * spacing, y, 3);
            }
        }
    }

    // Grootste font uit de lijst dat binnen maxW past (anders het kleinste).
    function fitFont(dc as Graphics.Dc, text as Lang.String, maxW as Lang.Number, fonts as Lang.Array) as Graphics.FontDefinition {
        for (var i = 0; i < fonts.size(); i++) {
            if (dc.getTextWidthInPixels(text, fonts[i]) <= maxW) {
                return fonts[i];
            }
        }
        return fonts[fonts.size() - 1];
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
