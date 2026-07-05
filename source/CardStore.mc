using Toybox.Lang;
using Toybox.Application.Storage;

// Data-laag: kaartdefinities komen uit SettingsParser (via Properties),
// favoriet/laatst-gebruikt wordt apart in Storage bijgehouden zodat het
// bewerken van instellingen die gebruiksgeschiedenis niet wist.
module CardStore {

    const CARDS_KEY = "cards";
    const USAGE_KEY = "usage";
    const COUNTER_KEY = "usageCounter";

    // Stabiele id: type + data. Bewust ZONDER label, zodat een kaart
    // hernoemen z'n identiteit (favoriet/gebruik) niet breekt.
    (:glance)
    function cardId(card as Lang.Dictionary) as Lang.String {
        return card.get("type") + "|" + card.get("data");
    }

    // Werk een veld van de opgeslagen kaart met dit id bij (naam/sublabel/color).
    function updateField(id as Lang.String, key as Lang.String, value) as Void {
        var cards = rawCards();
        for (var i = 0; i < cards.size(); i++) {
            if (cardId(cards[i]).equals(id)) {
                cards[i].put(key, value);
                Storage.setValue(CARDS_KEY, cards);
                return;
            }
        }
    }

    (:glance)
    function setCards(cards as Lang.Array<Lang.Dictionary>) as Void {
        Storage.setValue(CARDS_KEY, cards);
    }

    // Voeg nieuwe kaarten toe zonder de bestaande te wissen (dedup op cardId).
    // Geeft het aantal daadwerkelijk toegevoegde kaarten terug.
    (:glance)
    function mergeCards(newCards as Lang.Array<Lang.Dictionary>) as Lang.Number {
        var existing = rawCards();
        var ids = {} as Lang.Dictionary;
        for (var i = 0; i < existing.size(); i++) {
            ids.put(cardId(existing[i]), true);
        }
        var added = 0;
        for (var i = 0; i < newCards.size(); i++) {
            var id = cardId(newCards[i]);
            if (!(ids.hasKey(id))) {
                existing.add(newCards[i]);
                ids.put(id, true);
                added++;
            }
        }
        Storage.setValue(CARDS_KEY, existing);
        return added;
    }

    // Verwijder de kaart met dit id uit de opslag.
    function deleteById(id as Lang.String) as Void {
        var existing = rawCards();
        var kept = [] as Lang.Array<Lang.Dictionary>;
        for (var i = 0; i < existing.size(); i++) {
            if (!cardId(existing[i]).equals(id)) {
                kept.add(existing[i]);
            }
        }
        Storage.setValue(CARDS_KEY, kept);
    }

    (:glance)
    function rawCards() as Lang.Array<Lang.Dictionary> {
        var c = Storage.getValue(CARDS_KEY);
        if (c == null) {
            return [] as Lang.Array<Lang.Dictionary>;
        }
        return c as Lang.Array<Lang.Dictionary>;
    }

    (:glance)
    function usageMap() as Lang.Dictionary {
        var u = Storage.getValue(USAGE_KEY);
        if (u == null) {
            return {} as Lang.Dictionary;
        }
        return u as Lang.Dictionary;
    }

    // Kaarten + favoriet/laatst-gebruikt info, gesorteerd: favorieten eerst,
    // dan meest recent gebruikt.
    (:glance)
    function getCards() as Lang.Array<Lang.Dictionary> {
        var raw = rawCards();
        var usage = usageMap();
        var enriched = [] as Lang.Array<Lang.Dictionary>;

        for (var i = 0; i < raw.size(); i++) {
            var card = raw[i];
            var id = cardId(card);
            var u = usage.get(id) as Lang.Dictionary?;
            var fav = (u != null) ? (u.get("fav") == true) : false;
            var last = (u != null) ? (u.get("last") as Lang.Number) : 0;

            var copy = {} as Lang.Dictionary;
            var keys = card.keys();
            for (var k = 0; k < keys.size(); k++) {
                copy.put(keys[k], card.get(keys[k]));
            }
            copy.put("id", id);
            copy.put("favorite", fav);
            copy.put("lastUsed", last);
            copy.put("_order", i);
            enriched.add(copy);
        }

        // Eenvoudige insertion sort (lijsten zijn klein genoeg voor O(n^2)).
        for (var i = 1; i < enriched.size(); i++) {
            var current = enriched[i];
            var j = i - 1;
            while (j >= 0 && isBefore(current, enriched[j])) {
                enriched[j + 1] = enriched[j];
                j--;
            }
            enriched[j + 1] = current;
        }

        return enriched;
    }

    // true als 'a' vóór 'b' moet komen.
    (:glance)
    function isBefore(a as Lang.Dictionary, b as Lang.Dictionary) as Lang.Boolean {
        var favA = a.get("favorite") == true;
        var favB = b.get("favorite") == true;
        if (favA != favB) {
            return favA;
        }
        var lastA = a.get("lastUsed") as Lang.Number;
        var lastB = b.get("lastUsed") as Lang.Number;
        if (lastA != lastB) {
            return lastA > lastB;
        }
        return (a.get("_order") as Lang.Number) < (b.get("_order") as Lang.Number);
    }

    (:glance)
    function markUsed(id as Lang.String) as Void {
        var usage = usageMap();
        var counter = Storage.getValue(COUNTER_KEY);
        var next = ((counter == null) ? 0 : counter as Lang.Number) + 1;
        Storage.setValue(COUNTER_KEY, next);

        var u = usage.get(id) as Lang.Dictionary?;
        var fav = (u != null) ? (u.get("fav") == true) : false;
        usage.put(id, { "fav" => fav, "last" => next });
        Storage.setValue(USAGE_KEY, usage);
    }

    (:glance)
    function toggleFavorite(id as Lang.String) as Void {
        var usage = usageMap();
        var u = usage.get(id) as Lang.Dictionary?;
        var fav = (u != null) ? (u.get("fav") == true) : false;
        var last = (u != null) ? (u.get("last") as Lang.Number) : 0;
        usage.put(id, { "fav" => !fav, "last" => last });
        Storage.setValue(USAGE_KEY, usage);
    }

    (:glance)
    function favoriteCard() as Lang.Dictionary or Null {
        var cards = getCards();
        for (var i = 0; i < cards.size(); i++) {
            if (cards[i].get("favorite") == true) {
                return cards[i];
            }
        }
        return (cards.size() > 0) ? cards[0] : null;
    }
}
