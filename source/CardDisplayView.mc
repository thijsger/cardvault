using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.Lang;
using Toybox.Timer;
using Toybox.Attention;

// Scanbaarheidsmodus: maximale backlight, zwart-op-wit met quiet zone,
// scherm blijft actief zolang de kaart open staat.
class CardDisplayView extends WatchUi.View {

    var card as Lang.Dictionary;
    var invert as Lang.Boolean;
    var rotated as Lang.Boolean;
    var timer as Timer.Timer?;
    var secondsShown as Lang.Number;
    var favoriteFlashUntil as Lang.Number;
    var favoriteFlashText as Lang.String;
    var qrMatrix as Lang.Array?;      // gecachte QR-matrix (zwaar om te berekenen)
    var qrTried as Lang.Boolean;

    function initialize(c as Lang.Dictionary) {
        View.initialize();
        card = c;
        invert = false;
        rotated = false;
        secondsShown = 0;
        favoriteFlashUntil = 0;
        favoriteFlashText = "";
        qrMatrix = null;
        qrTried = false;
    }

    function toggleInvert() as Void {
        invert = !invert;
        WatchUi.requestUpdate();
    }

    function toggleRotate() as Void {
        rotated = !rotated;
        WatchUi.requestUpdate();
    }

    function flashFavorite(isFavorite as Lang.Boolean) as Void {
        favoriteFlashUntil = secondsShown + 2;
        favoriteFlashText = isFavorite ? "★ favoriet" : "☆ niet meer favoriet";
        WatchUi.requestUpdate();
    }

    function onShow() as Void {
        if (Attention has :backlight) {
            Attention.backlight(true);
        }
        timer = new Timer.Timer();
        (timer as Timer.Timer).start(method(:onTick), 1000, true);
    }

    function onHide() as Void {
        if (timer != null) {
            (timer as Timer.Timer).stop();
            timer = null;
        }
    }

    function onTick() as Void {
        secondsShown++;
        // Backlight-limiet per device: elke ~20s opnieuw aanvragen.
        if (secondsShown % 20 == 0 && Attention has :backlight) {
            Attention.backlight(true);
        }
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var bg = invert ? Graphics.COLOR_BLACK : Graphics.COLOR_WHITE;
        var fg = invert ? Graphics.COLOR_WHITE : Graphics.COLOR_BLACK;

        dc.setColor(fg, bg);
        dc.clear();

        var type = card.get("type");
        if (type.equals("totp")) {
            drawTotp(dc, fg, bg);
        } else if (type.equals("qr")) {
            drawQr(dc, fg, bg);
        } else {
            drawBarcode(dc, fg, bg);
        }

        if (secondsShown < favoriteFlashUntil) {
            dc.setColor(fg, Graphics.COLOR_TRANSPARENT);
            dc.drawText(dc.getWidth() / 2, dc.getHeight() - 60, Graphics.FONT_TINY,
                favoriteFlashText, Graphics.TEXT_JUSTIFY_CENTER);
        }
    }

    function drawBarcode(dc as Graphics.Dc, fg as Lang.Number, bg as Lang.Number) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        var cx = w / 2;
        var cy = h / 2;
        // Veilige zone: op ronde schermen worden rand-gebieden afgesneden.
        // We tekenen titel + code + nummer als één blok rond het midden.
        var margin = (rotated ? h : w) * 0.14;

        var format = card.get("format") as Lang.String;
        var data = card.get("data") as Lang.String;
        var bits;
        if (format.equals("EAN13")) {
            bits = Barcode.encodeEan13(data);
        } else {
            bits = Barcode.encodeCode128(data);
        }

        // Barcode-band iets boven het midden, zodat titel (boven) en nummer
        // (onder) in de cirkel passen.
        var barBandHeight = ((rotated ? w : h) * 0.34).toNumber();
        var axisLen = ((rotated ? h : w) - 2 * margin).toNumber();
        var moduleSize = axisLen / bits.length();
        if (moduleSize < 1) {
            moduleSize = 1;
        }
        var totalLen = moduleSize * bits.length();
        var start = ((rotated ? h : w) - totalLen) / 2;
        var bandStart = ((rotated ? w : h) - barBandHeight) / 2;

        // Titel ruim boven de band (extra marge zodat tekst de bars niet raakt).
        dc.setColor(fg, Graphics.COLOR_TRANSPARENT);
        if (rotated) {
            dc.drawText(cx - barBandHeight / 2 - 30, cy, Graphics.FONT_TINY,
                card.get("label") as Lang.String,
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        } else {
            dc.drawText(cx, bandStart - 54, Graphics.FONT_TINY,
                card.get("label") as Lang.String, Graphics.TEXT_JUSTIFY_CENTER);
        }

        // Bars.
        var i = 0;
        while (i < bits.length()) {
            if (bits.substring(i, i + 1).equals("1")) {
                var runStart = i;
                while (i < bits.length() && bits.substring(i, i + 1).equals("1")) {
                    i++;
                }
                var runLen = (i - runStart) * moduleSize;
                var offset = start + runStart * moduleSize;
                if (rotated) {
                    dc.fillRectangle(bandStart, offset, barBandHeight, runLen);
                } else {
                    dc.fillRectangle(offset, bandStart, runLen, barBandHeight);
                }
            } else {
                i++;
            }
        }

        // Nummer direct onder de band (binnen de cirkel).
        dc.setColor(fg, Graphics.COLOR_TRANSPARENT);
        if (rotated) {
            dc.drawText(cx + barBandHeight / 2 + 22, cy, Graphics.FONT_TINY, data,
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        } else {
            dc.drawText(cx, bandStart + barBandHeight + 14, Graphics.FONT_TINY, data,
                Graphics.TEXT_JUSTIFY_CENTER);
        }
    }

    function drawQr(dc as Graphics.Dc, fg as Lang.Number, bg as Lang.Number) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        var cx = w / 2;
        var cy = h / 2;

        if (!qrTried) {
            qrTried = true;
            qrMatrix = Qr.encode(card.get("data") as Lang.String);
        }

        if (qrMatrix == null) {
            dc.setColor(fg, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, cy, Graphics.FONT_TINY, "QR te lang", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            return;
        }

        var matrix = qrMatrix as Lang.Array;
        var n = matrix.size();
        // Grootste vierkant met quiet zone dat op het ronde scherm past.
        var avail = ((w < h ? w : h) * 0.82).toNumber();
        var modSize = avail / (n + 8); // 4 modules quiet zone rondom
        if (modSize < 1) { modSize = 1; }
        var qrPixels = modSize * n;
        var startX = cx - qrPixels / 2;
        var startY = cy - qrPixels / 2;

        // witte achtergrond met quiet zone
        dc.setColor(bg, Graphics.COLOR_TRANSPARENT);
        var quiet = modSize * 4;
        dc.fillRectangle(startX - quiet, startY - quiet, qrPixels + 2 * quiet, qrPixels + 2 * quiet);

        // modules
        dc.setColor(fg, Graphics.COLOR_TRANSPARENT);
        for (var r = 0; r < n; r++) {
            var rowArr = matrix[r] as Lang.Array<Lang.Number>;
            for (var c = 0; c < n; c++) {
                if (rowArr[c] != 0) {
                    dc.fillRectangle(startX + c * modSize, startY + r * modSize, modSize, modSize);
                }
            }
        }
    }

    function drawTotp(dc as Graphics.Dc, fg as Lang.Number, bg as Lang.Number) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        var cx = w / 2;
        var cy = h / 2;
        var minDim = (w < h ? w : h);

        var secret = card.get("data") as Lang.String;
        var digits = card.get("digits") as Lang.Number;
        var period = card.get("period") as Lang.Number;
        var algo = card.get("algo") as Lang.String;
        var code = Totp.generate(secret, period, digits, algo);
        var remaining = Totp.secondsRemaining(period);
        var spaced = code.substring(0, digits / 2) + " " + code.substring(digits / 2, digits);

        // Aftelring helemaal op de schermrand, zodat de volle breedte vrij is
        // voor de code. De code pakt het grootste font dat over de volle
        // breedte past (dus groter bij weinig cijfers, kleiner bij 8/10).
        var radius = minDim / 2 - 8;
        var maxCodeW = 2 * radius - 44;
        var fonts = [
            Graphics.FONT_NUMBER_HOT,
            Graphics.FONT_NUMBER_MEDIUM,
            Graphics.FONT_NUMBER_MILD,
            Graphics.FONT_LARGE,
            Graphics.FONT_MEDIUM,
            Graphics.FONT_SMALL
        ];
        var codeFont = fonts[fonts.size() - 1];
        for (var fi = 0; fi < fonts.size(); fi++) {
            var tw = dc.getTextWidthInPixels(spaced, fonts[fi]);
            codeFont = fonts[fi];
            if (tw <= maxCodeW) {
                break;
            }
        }

        var ringColor = fg;
        if (remaining < 5) {
            ringColor = Graphics.COLOR_RED;
        } else if (remaining < 10) {
            ringColor = Graphics.COLOR_ORANGE;
        }

        dc.setPenWidth(10);
        dc.setColor(ringColor, Graphics.COLOR_TRANSPARENT);
        var fraction = remaining.toFloat() / period.toFloat();
        var endAngle = 90 - (360.0 * fraction);
        while (endAngle < 0) {
            endAngle += 360;
        }
        dc.drawArc(cx, cy, radius, Graphics.ARC_CLOCKWISE, 90, endAngle);

        // Verticale plaatsing t.o.v. de codehoogte, zodat titel en seconden
        // altijd netjes vlak boven/onder het getal staan.
        var codeH = dc.getFontHeight(codeFont);
        var titleH = dc.getFontHeight(Graphics.FONT_TINY);

        dc.setColor(fg, Graphics.COLOR_TRANSPARENT);

        // Titel een stukje boven het getal.
        dc.drawText(cx, cy - codeH / 2 - 6 - titleH, Graphics.FONT_TINY,
            card.get("label") as Lang.String, Graphics.TEXT_JUSTIFY_CENTER);

        // Code groot in het midden.
        dc.drawText(cx, cy, codeFont, spaced,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Seconden vlak onder het getal.
        dc.drawText(cx, cy + codeH / 2 + 4, Graphics.FONT_XTINY, remaining.toString() + "s",
            Graphics.TEXT_JUSTIFY_CENTER);
    }
}
