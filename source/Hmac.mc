using Toybox.Lang;

// HMAC-SHA1 (RFC 2104), gebouwd op de pure Sha1-module.
module Hmac {

    const BLOCK_SIZE = 64;

    (:glance)
    function sha1(key as Lang.ByteArray, message as Lang.ByteArray) as Lang.ByteArray {
        var k = key;
        if (k.size() > BLOCK_SIZE) {
            k = Sha1.hash(k);
        }
        if (k.size() < BLOCK_SIZE) {
            var padded = new [BLOCK_SIZE]b;
            for (var i = 0; i < BLOCK_SIZE; i++) {
                padded[i] = (i < k.size()) ? k[i] : 0;
            }
            k = padded;
        }

        var oKeyPad = new [BLOCK_SIZE]b;
        var iKeyPad = new [BLOCK_SIZE]b;
        for (var i = 0; i < BLOCK_SIZE; i++) {
            oKeyPad[i] = k[i] ^ 0x5c;
            iKeyPad[i] = k[i] ^ 0x36;
        }

        var inner = concat(iKeyPad, message);
        var innerHash = Sha1.hash(inner);
        var outer = concat(oKeyPad, innerHash);
        return Sha1.hash(outer);
    }

    function sha256(key as Lang.ByteArray, message as Lang.ByteArray) as Lang.ByteArray {
        var k = key;
        if (k.size() > BLOCK_SIZE) {
            k = Sha256.hash(k);
        }
        if (k.size() < BLOCK_SIZE) {
            var padded = new [BLOCK_SIZE]b;
            for (var i = 0; i < BLOCK_SIZE; i++) {
                padded[i] = (i < k.size()) ? k[i] : 0;
            }
            k = padded;
        }

        var oKeyPad = new [BLOCK_SIZE]b;
        var iKeyPad = new [BLOCK_SIZE]b;
        for (var i = 0; i < BLOCK_SIZE; i++) {
            oKeyPad[i] = k[i] ^ 0x5c;
            iKeyPad[i] = k[i] ^ 0x36;
        }

        var innerHash = Sha256.hash(concat(iKeyPad, message));
        return Sha256.hash(concat(oKeyPad, innerHash));
    }

    (:glance)
    function concat(a as Lang.ByteArray, b as Lang.ByteArray) as Lang.ByteArray {
        var out = new [a.size() + b.size()]b;
        for (var i = 0; i < a.size(); i++) {
            out[i] = a[i];
        }
        for (var i = 0; i < b.size(); i++) {
            out[a.size() + i] = b[i];
        }
        return out;
    }
}
