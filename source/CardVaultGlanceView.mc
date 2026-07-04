using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.Lang;
using Toybox.Application.Storage;

// Compacte glance: favoriete kaart. Glance draait in een eigen, beperkte
// compilatie-scope, dus deze view leest Storage rechtstreeks in plaats van
// via de CardStore-module (cross-module calls vanuit glance crashen).
(:glance)
class CardVaultGlanceView extends WatchUi.GlanceView {

    function initialize() {
        GlanceView.initialize();
    }

    (:glance)
    function findFavorite() as Lang.Dictionary? {
        var raw = Storage.getValue("cards") as Lang.Array<Lang.Dictionary>?;
        if (raw == null || raw.size() == 0) {
            return null;
        }
        var usage = Storage.getValue("usage") as Lang.Dictionary?;
        for (var i = 0; i < raw.size(); i++) {
            var c = raw[i];
            var id = c.get("label") + "|" + c.get("type") + "|" + c.get("data");
            var u = (usage != null) ? (usage.get(id) as Lang.Dictionary?) : null;
            if (u != null && u.get("fav") == true) {
                return c;
            }
        }
        return raw[0];
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_TRANSPARENT, Graphics.COLOR_BLACK);
        dc.clear();

        var w = dc.getWidth();
        var h = dc.getHeight();
        var cy = h / 2;

        var card = findFavorite();

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(0, 0, Graphics.FONT_XTINY, "CardVault", Graphics.TEXT_JUSTIFY_LEFT);

        if (card == null) {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(0, cy, Graphics.FONT_TINY, "Geen kaarten",
                Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
            return;
        }

        dc.setColor(card.get("color") as Lang.Number, Graphics.COLOR_TRANSPARENT);
        dc.drawText(0, cy, Graphics.FONT_MEDIUM, card.get("label") as Lang.String,
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}
