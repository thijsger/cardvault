using Toybox.Lang;
using Toybox.Application;
using Toybox.Application.Properties;
using Toybox.Graphics;

// Leest de card-data-tekst uit Properties (4 gechunkte velden, samen één
// tekst) en zet elke regel om in een kaart-dictionary voor CardStore.
//
// Regelformaat (pipe-gescheiden, "\|" is een letterlijke pipe in een veld):
//   barcode|Label|Sublabel|kleur|icoon|nummer|EAN13|categorie
//   totp|Label|Sublabel|kleur|icoon|secret|SHA1:6:30|categorie
module SettingsParser {

    const COLORS = {
        "blue" => Graphics.COLOR_BLUE,
        "red" => Graphics.COLOR_RED,
        "green" => Graphics.COLOR_GREEN,
        "orange" => Graphics.COLOR_ORANGE,
        "purple" => Graphics.COLOR_PURPLE,
        "pink" => Graphics.COLOR_PINK,
        "yellow" => Graphics.COLOR_YELLOW,
        "dkblue" => Graphics.COLOR_DK_BLUE,
        "dkgreen" => Graphics.COLOR_DK_GREEN,
        "dkred" => Graphics.COLOR_DK_RED,
        "ltgray" => Graphics.COLOR_LT_GRAY,
        "dkgray" => Graphics.COLOR_DK_GRAY,
        "white" => Graphics.COLOR_WHITE
    };

    (:glance)
    function colorFor(name as Lang.String) as Lang.Number {
        var c = COLORS.get(StrUtil.trim(name).toLower());
        return (c == null) ? Graphics.COLOR_BLUE : c;
    }

    (:glance)
    function rawSettingsText() as Lang.String {
        var text = "";
        for (var i = 0; i < 4; i++) {
            var chunk = Properties.getValue("cardsData" + i.toString());
            if (chunk != null) {
                text += chunk.toString();
            }
        }
        return text;
    }

    // Startup-load: alleen als er nog geen kaarten zijn, importeer dan uit
    // Garmin Connect-instellingen (of de laatst gesyncte tekst). Bestaande
    // kaarten (incl. verwijderingen) blijven staan zodat sync/delete niet
    // ongedaan gemaakt worden bij herstart.
    (:glance)
    function reload() as Void {
        if (CardStore.rawCards().size() > 0) {
            return;
        }
        var text = rawSettingsText();
        if (StrUtil.trim(text).length() == 0) {
            var synced = Application.Storage.getValue("syncText");
            if (synced != null) {
                text = synced.toString();
            }
        }
        CardStore.setCards(parseText(text));
    }

    // Tekst -> array van kaart-dictionaries (zonder op te slaan).
    (:glance)
    function parseText(text as Lang.String) as Lang.Array<Lang.Dictionary> {
        var lines = StrUtil.split(text, "\n");
        var cards = [] as Lang.Array<Lang.Dictionary>;
        for (var i = 0; i < lines.size(); i++) {
            var line = StrUtil.trim(lines[i]);
            if (line.length() == 0) {
                continue;
            }
            var card = parseLine(line);
            if (card != null) {
                cards.add(card);
            }
        }
        return cards;
    }

    // Vervang de volledige kaartenlijst (voor de testdata / expliciet resetten).
    (:glance)
    function reloadFromText(text as Lang.String) as Void {
        CardStore.setCards(parseText(text));
    }

    // Voeg kaarten uit deze tekst toe zonder bestaande te wissen.
    (:glance)
    function mergeFromText(text as Lang.String) as Lang.Number {
        return CardStore.mergeCards(parseText(text));
    }

    (:glance)
    function parseLine(line as Lang.String) as Lang.Dictionary or Null {
        var f = StrUtil.splitEscaped(line, "|");
        if (f.size() < 6) {
            return null;
        }

        var type = StrUtil.trim(f[0]).toLower();
        var label = StrUtil.trim(f[1]);
        var sublabel = StrUtil.trim(f[2]);
        var color = colorFor(f[3]);
        var icon = StrUtil.trim(f[4]);
        var data = StrUtil.trim(f[5]);
        var extra = (f.size() > 6) ? StrUtil.trim(f[6]) : "";
        var category = (f.size() > 7) ? StrUtil.trim(f[7]) : "Overig";

        if (label.length() == 0 || data.length() == 0) {
            return null;
        }

        if (type.equals("totp")) {
            var totpParts = StrUtil.split(extra, ":");
            var algo = (totpParts.size() > 0 && totpParts[0].length() > 0) ? totpParts[0] : "SHA1";
            var digits = (totpParts.size() > 1) ? totpParts[1].toNumber() : 6;
            var period = (totpParts.size() > 2) ? totpParts[2].toNumber() : 30;

            return {
                "type" => "totp",
                "label" => label,
                "sublabel" => sublabel,
                "color" => color,
                "icon" => icon,
                "data" => data,
                "algo" => algo,
                "digits" => (digits == null) ? 6 : digits,
                "period" => (period == null) ? 30 : period,
                "category" => category
            };
        }

        if (type.equals("qr")) {
            return {
                "type" => "qr",
                "label" => label,
                "sublabel" => sublabel,
                "color" => color,
                "icon" => icon,
                "data" => data,
                "category" => category
            };
        }

        var format = (extra.length() > 0) ? extra.toUpper() : "CODE128";
        return {
            "type" => "barcode",
            "label" => label,
            "sublabel" => sublabel,
            "color" => color,
            "icon" => icon,
            "data" => data,
            "format" => format,
            "category" => category
        };
    }
}
