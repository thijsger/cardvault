using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.Lang;

// Glance: simpelweg de app-naam. Een glance kan geen scanbare kaart tonen,
// dus we houden het bij nette branding.
(:glance)
class CardVaultGlanceView extends WatchUi.GlanceView {

    function initialize() {
        GlanceView.initialize();
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        // Transparant laten: geen eigen zwarte achtergrond tekenen.
        var h = dc.getHeight();
        var cy = h / 2;

        // Klein "pas"-icoontje links.
        var iconW = 34;
        var iconH = 22;
        var iconY = cy - iconH / 2;
        dc.setColor(0x5B9DFF, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(0, iconY, iconW, iconH, 4);
        // Magneetstreep in dezelfde blauwtint maar donkerder (geen zwart blok).
        dc.setColor(0x2A5FA0, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(0, iconY + 5, iconW, 4);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(iconW + 10, cy, Graphics.FONT_TINY, "CardVault",
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}
