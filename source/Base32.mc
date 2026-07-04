using Toybox.Lang;

// RFC 4648 base32-decoder (voor TOTP-secrets, geen padding vereist).
module Base32 {

    const ALPHABET = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567";

    (:glance)
    function decode(input as Lang.String) as Lang.ByteArray {
        var clean = "";
        var upper = input.toUpper();
        for (var i = 0; i < upper.length(); i++) {
            var c = upper.substring(i, i + 1);
            if (ALPHABET.find(c) != null) {
                clean = clean + c;
            }
        }

        var bits = 0;
        var value = 0;
        var bytes = [] as Lang.Array<Lang.Number>;

        for (var j = 0; j < clean.length(); j++) {
            var idx = ALPHABET.find(clean.substring(j, j + 1));
            value = (value << 5) | idx;
            bits += 5;
            if (bits >= 8) {
                bytes.add((value >> (bits - 8)) & 0xFF);
                bits -= 8;
            }
        }

        var b = new [bytes.size()]b;
        for (var k = 0; k < bytes.size(); k++) {
            b[k] = bytes[k];
        }
        return b;
    }
}
