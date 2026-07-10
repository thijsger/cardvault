using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.Lang;

// Pincode-scherm met een numpad. Drie modi:
//   MODE_UNLOCK  — bij opstarten, ontgrendelt de app
//   MODE_SET     — nieuwe pincode kiezen (twee keer invoeren)
//   MODE_DISABLE — huidige pincode invoeren om het slot uit te zetten
class PinView extends WatchUi.View {

    enum {
        MODE_UNLOCK = 0,
        MODE_SET = 1,
        MODE_DISABLE = 2
    }

    var mode as Lang.Number;
    var entry as Lang.String;      // huidige invoer
    var firstEntry as Lang.String; // eerste invoer bij MODE_SET
    var message as Lang.String;
    var errorFlash as Lang.Boolean;
    var w as Lang.Number;
    var h as Lang.Number;

    function initialize(m as Lang.Number) {
        View.initialize();
        mode = m;
        entry = "";
        firstEntry = "";
        message = titleFor(m);
        errorFlash = false;
        w = 260;
        h = 260;
    }

    function titleFor(m as Lang.Number) as Lang.String {
        if (m == MODE_SET) { return "New PIN"; }
        if (m == MODE_DISABLE) { return "Enter PIN"; }
        return "PIN";
    }

    function onLayout(dc as Graphics.Dc) as Void {
        w = dc.getWidth();
        h = dc.getHeight();
    }

    // Numpad-geometrie: 3 kolommen, 4 rijen (1-9, dan leeg/0/wis).
    function gridTop() as Lang.Number { return (h * 0.30).toNumber(); }
    function cellW() as Lang.Number { return w / 3; }
    function cellH() as Lang.Number { return ((h - gridTop()) / 4).toNumber(); }

    // Welke toets ligt op (x,y)? Geeft "0".."9", "<" (wissen) of "" terug.
    function keyAt(x as Lang.Number, y as Lang.Number) as Lang.String {
        if (y < gridTop()) { return ""; }
        var col = x / cellW();
        var row = (y - gridTop()) / cellH();
        if (col > 2) { col = 2; }
        if (row > 3) { row = 3; }
        if (row < 3) {
            var n = row * 3 + col + 1; // 1..9
            return n.toString();
        }
        // laatste rij: [leeg] [0] [wis]
        if (col == 1) { return "0"; }
        if (col == 2) { return "<"; }
        return "";
    }

    function press(key as Lang.String) as Void {
        errorFlash = false;
        if (key.equals("<")) {
            if (entry.length() > 0) {
                entry = entry.substring(0, entry.length() - 1);
            }
        } else if (entry.length() < 4) {
            entry += key;
        }
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();
        var cx = w / 2;

        // titel / melding
        dc.setColor(errorFlash ? Graphics.COLOR_RED : Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 0.12, Graphics.FONT_XTINY, message, Graphics.TEXT_JUSTIFY_CENTER);

        // ingevoerde cijfers als bolletjes
        var dotY = (h * 0.21).toNumber();
        var spacing = 26;
        var startX = cx - (spacing * 3) / 2;
        for (var i = 0; i < 4; i++) {
            if (i < entry.length()) {
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                dc.fillCircle(startX + i * spacing, dotY, 6);
            } else {
                dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
                dc.drawCircle(startX + i * spacing, dotY, 6);
            }
        }

        // numpad
        var top = gridTop();
        var cw = cellW();
        var ch = cellH();
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        for (var r = 0; r < 4; r++) {
            for (var c = 0; c < 3; c++) {
                var label = "";
                if (r < 3) {
                    label = (r * 3 + c + 1).toString();
                } else if (c == 1) {
                    label = "0";
                } else if (c == 2) {
                    label = "<";
                }
                if (!label.equals("")) {
                    var bx = c * cw + cw / 2;
                    var by = top + r * ch + ch / 2;
                    dc.drawText(bx, by, Graphics.FONT_MEDIUM, label,
                        Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
                }
            }
        }
    }

    // Aangeroepen wanneer 4 cijfers zijn ingevoerd. Geeft terug wat er moet
    // gebeuren: "unlocked", "saved", "disabled", "again", "error", of "".
    function commit() as Lang.String {
        if (entry.length() != 4) { return ""; }
        var code = entry;
        entry = "";

        if (mode == MODE_UNLOCK) {
            if (Pin.verify(code)) { return "unlocked"; }
            return fail("Wrong. Try again.");
        }
        if (mode == MODE_DISABLE) {
            if (Pin.verify(code)) { Pin.clear(); return "disabled"; }
            return fail("Wrong. Try again.");
        }
        // MODE_SET: twee keer invoeren
        if (firstEntry.equals("")) {
            firstEntry = code;
            message = "Repeat PIN";
            WatchUi.requestUpdate();
            return "again";
        }
        if (firstEntry.equals(code)) {
            Pin.set(code);
            return "saved";
        }
        firstEntry = "";
        return fail("Does not match.");
    }

    function fail(msg as Lang.String) as Lang.String {
        message = msg;
        errorFlash = true;
        WatchUi.requestUpdate();
        return "error";
    }
}
