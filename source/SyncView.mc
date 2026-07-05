using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.Lang;
using Toybox.Communications;
using Toybox.Application.Storage;

// Sync-scherm: toont de koppelcode en haalt kaarten op van de server.
class SyncView extends WatchUi.View {

    var statusText as Lang.String;
    var busy as Lang.Boolean;

    function initialize() {
        View.initialize();
        statusText = "";
        busy = false;
    }

    function startPull() as Void {
        if (busy) { return; }
        busy = true;
        statusText = "Ophalen…";
        WatchUi.requestUpdate();
        Communications.makeWebRequest(
            Sync.pullUrl(),
            {},
            {
                :method => Communications.HTTP_REQUEST_METHOD_GET,
                :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_TEXT_PLAIN
            },
            method(:onResponse)
        );
    }

    function onResponse(code as Lang.Number, data as Lang.String or Null) as Void {
        busy = false;
        if (code == 200 && data != null && data.toString().length() > 0) {
            var text = data.toString();
            Storage.setValue("syncText", text);
            // Toevoegen zonder bestaande kaarten te wissen.
            var added = SettingsParser.mergeFromText(text);
            statusText = added.toString() + " nieuwe kaart(en)";
        } else if (code == 200) {
            statusText = "Niets gevonden voor deze code.";
        } else {
            statusText = "Fout (" + code.toString() + "). Server bereikbaar?";
        }
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();
        var w = dc.getWidth();
        var h = dc.getHeight();
        var cx = w / 2;

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 0.16, Graphics.FONT_XTINY, "Koppelcode", Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 0.32, Graphics.FONT_NUMBER_MEDIUM, Sync.deviceCode(),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 0.54, Graphics.FONT_XTINY, "Typ in de webapp,", Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(cx, h * 0.62, Graphics.FONT_XTINY, "tik dan hier: Ophalen", Graphics.TEXT_JUSTIFY_CENTER);

        if (statusText.length() > 0) {
            dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, h * 0.78, Graphics.FONT_XTINY, statusText, Graphics.TEXT_JUSTIFY_CENTER);
        }
    }
}

class SyncDelegate extends WatchUi.BehaviorDelegate {

    var view as SyncView;

    function initialize(v as SyncView) {
        BehaviorDelegate.initialize();
        view = v;
    }

    // Tik / selecteer = ophalen.
    function onSelect() as Lang.Boolean {
        view.startPull();
        return true;
    }

    function onBack() as Lang.Boolean {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }
}
