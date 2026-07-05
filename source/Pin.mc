using Toybox.Lang;
using Toybox.Application.Storage;

// Optionele 4-cijferige pincode. We slaan een simpele hash op (geen plaintext).
module Pin {

    const HASH_KEY = "pinHash";

    // Eenvoudige, deterministische hash van een 4-cijferige code.
    (:glance)
    function hash(code as Lang.String) as Lang.Number {
        var h = 5381;
        for (var i = 0; i < code.length(); i++) {
            var ch = code.substring(i, i + 1).toNumber();
            if (ch == null) { ch = 0; }
            h = ((h * 33) + ch) & 0x7FFFFFFF;
        }
        return h;
    }

    (:glance)
    function isSet() as Lang.Boolean {
        return Storage.getValue(HASH_KEY) != null;
    }

    (:glance)
    function set(code as Lang.String) as Void {
        Storage.setValue(HASH_KEY, hash(code));
    }

    (:glance)
    function clear() as Void {
        Storage.deleteValue(HASH_KEY);
    }

    (:glance)
    function verify(code as Lang.String) as Lang.Boolean {
        var stored = Storage.getValue(HASH_KEY);
        if (stored == null) { return true; }
        return (stored as Lang.Number) == hash(code);
    }
}
