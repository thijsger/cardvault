using Toybox.WatchUi;
using Toybox.Lang;

// Input tijdens scanweergave: select = invert, pagina-knoppen = 90° draaien,
// menu-knop = favoriet aan/uit, back = terug naar de lijst.
class CardDisplayDelegate extends WatchUi.BehaviorDelegate {

    var card as Lang.Dictionary;
    var view as CardDisplayView;

    function initialize(v as CardDisplayView, c as Lang.Dictionary) {
        BehaviorDelegate.initialize();
        view = v;
        card = c;
    }

    function onSelect() as Lang.Boolean {
        view.toggleInvert();
        return true;
    }

    function onNextPage() as Lang.Boolean {
        view.toggleRotate();
        return true;
    }

    function onPreviousPage() as Lang.Boolean {
        return onNextPage();
    }

    function onMenu() as Lang.Boolean {
        var id = card.get("id") as Lang.String;
        CardStore.toggleFavorite(id);
        var usage = CardStore.usageMap().get(id) as Lang.Dictionary?;
        var isFav = (usage != null) && (usage.get("fav") == true);
        view.flashFavorite(isFav);
        return true;
    }
}
