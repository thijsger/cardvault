using Toybox.Lang;

// Pure Monkey C SHA-1 (RFC 3174), voor devices zonder Toybox.Cryptography.Hmac.
// Werkt volledig met Lang.Number (32-bit, wrapt zoals C's uint32_t bij optellen);
// alleen de unsigned right-shift (nodig voor rotate-left) leent kortstondig Long.
module Sha1 {

    (:glance)
    function ushr(x as Lang.Number, n as Lang.Number) as Lang.Number {
        if (n <= 0) {
            return x;
        }
        var lx = x.toLong() & 0xFFFFFFFFl;
        return (lx >> n).toNumber();
    }

    (:glance)
    function rotl(x as Lang.Number, n as Lang.Number) as Lang.Number {
        return (x << n) | ushr(x, 32 - n);
    }

    // message: ByteArray -> digest: ByteArray (20 bytes)
    (:glance)
    function hash(message as Lang.ByteArray) as Lang.ByteArray {
        var msgLen = message.size();
        var bitLen = msgLen * 8;

        // Padding: 0x80, dan nullen tot lengte % 64 == 56, dan 8 bytes bit-lengte (big-endian).
        var padLen = ((56 - (msgLen + 1) % 64) + 64) % 64;
        var totalLen = msgLen + 1 + padLen + 8;
        var padded = new [totalLen]b;
        for (var i = 0; i < msgLen; i++) {
            padded[i] = message[i];
        }
        padded[msgLen] = 0x80;
        for (var i = msgLen + 1; i < msgLen + 1 + padLen; i++) {
            padded[i] = 0;
        }
        for (var i = 0; i < 8; i++) {
            var shift = (7 - i) * 8;
            padded[totalLen - 8 + i] = (shift < 32) ? ((bitLen >> shift) & 0xFF) : 0;
        }

        // Literalen > 0x7FFFFFFF passen niet in een signed 32-bit Number-literal;
        // via Long invoeren en naar Number truncaten geeft het juiste gewrapte bitpatroon.
        var h0 = 0x67452301;
        var h1 = (0xEFCDAB89l).toNumber();
        var h2 = (0x98BADCFEl).toNumber();
        var h3 = 0x10325476;
        var h4 = (0xC3D2E1F0l).toNumber();

        var chunks = totalLen / 64;
        var w = new [80] as Lang.Array<Lang.Number>;

        for (var c = 0; c < chunks; c++) {
            var base = c * 64;
            for (var t = 0; t < 16; t++) {
                var o = base + t * 4;
                w[t] = ((padded[o] & 0xFF) << 24) |
                       ((padded[o + 1] & 0xFF) << 16) |
                       ((padded[o + 2] & 0xFF) << 8) |
                       (padded[o + 3] & 0xFF);
            }
            for (var t = 16; t < 80; t++) {
                w[t] = rotl(w[t - 3] ^ w[t - 8] ^ w[t - 14] ^ w[t - 16], 1);
            }

            var a = h0;
            var b = h1;
            var cc = h2;
            var d = h3;
            var e = h4;

            for (var t = 0; t < 80; t++) {
                var f;
                var k;
                if (t < 20) {
                    f = (b & cc) | (~b & d);
                    k = 0x5A827999;
                } else if (t < 40) {
                    f = b ^ cc ^ d;
                    k = 0x6ED9EBA1;
                } else if (t < 60) {
                    f = (b & cc) | (b & d) | (cc & d);
                    k = (0x8F1BBCDCl).toNumber();
                } else {
                    f = b ^ cc ^ d;
                    k = (0xCA62C1D6l).toNumber();
                }

                var temp = rotl(a, 5) + f + e + k + w[t];
                e = d;
                d = cc;
                cc = rotl(b, 30);
                b = a;
                a = temp;
            }

            h0 = h0 + a;
            h1 = h1 + b;
            h2 = h2 + cc;
            h3 = h3 + d;
            h4 = h4 + e;
        }

        var digest = new [20]b;
        writeWord(digest, 0, h0);
        writeWord(digest, 4, h1);
        writeWord(digest, 8, h2);
        writeWord(digest, 12, h3);
        writeWord(digest, 16, h4);
        return digest;
    }

    (:glance)
    function writeWord(buf as Lang.ByteArray, offset as Lang.Number, word as Lang.Number) as Void {
        buf[offset] = (word >> 24) & 0xFF;
        buf[offset + 1] = (word >> 16) & 0xFF;
        buf[offset + 2] = (word >> 8) & 0xFF;
        buf[offset + 3] = word & 0xFF;
    }
}
