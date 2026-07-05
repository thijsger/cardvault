using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.Lang;

// Kleur-keuzemenu voor een kaart. Toont de beschikbare kleuren; selectie zet
// de kaartkleur en slaat op.
module ColorPicker {

    const NAMES = ["blue", "green", "orange", "purple", "red",
                   "pink", "yellow", "dkblue", "dkgreen", "dkgray"];
    const LABELS = ["Blauw", "Groen", "Oranje", "Paars", "Rood",
                    "Roze", "Geel", "Donkerblauw", "Donkergroen", "Grijs"];
    const VALUES = [0x1e90ff, 0x34c759, 0xff9500, 0xaf52de, 0xff3b30,
                    0xff2d92, 0xffd60a, 0x0a3d91, 0x1b6b2f, 0x3a3a3a];

    function build() as WatchUi.Menu2 {
        var menu = new WatchUi.Menu2({ :title => "Kleur" });
        for (var i = 0; i < NAMES.size(); i++) {
            menu.addItem(new WatchUi.MenuItem(LABELS[i], null, NAMES[i], {}));
        }
        return menu;
    }

    function colorFor(name as Lang.String) as Lang.Number {
        for (var i = 0; i < NAMES.size(); i++) {
            if (NAMES[i].equals(name)) { return VALUES[i]; }
        }
        return 0x1e90ff;
    }
}

class ColorMenuDelegate extends WatchUi.Menu2InputDelegate {
    var view as CardWalletView;
    var cardId as Lang.String;

    function initialize(v as CardWalletView, id as Lang.String) {
        Menu2InputDelegate.initialize();
        view = v;
        cardId = id;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var name = item.getId() as Lang.String;
        CardStore.updateField(cardId, "color", ColorPicker.colorFor(name));
        view.onShow();
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}
