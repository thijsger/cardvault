using Toybox.Lang;

// Pure Monkey C SHA-256 (FIPS 180-4). 32-bit rekenwerk met Number; alleen de
// unsigned right-shift leent kort een Long (zoals in Sha1.mc).
module Sha256 {

    const K = [
        0x428a2f98, 0x71374491, -0x4a3f0431, -0x164a245b, 0x3956c25b, 0x59f111f1, -0x6dc07d5c, -0x54e3a12b,
        -0x27f85568, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, -0x7f214e02, -0x6423f959, -0x3e640e8c,
        -0x1b64963f, -0x1041b87a, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
        -0x67c1aeae, -0x57ce3993, -0x4ffcd838, -0x40a68039, -0x391ff40d, -0x2a586eb9, 0x06ca6351, 0x14292967,
        0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, -0x7e3d36d2, -0x6d8dd37b,
        -0x5d40175f, -0x57e599b5, -0x3db47490, -0x3893ae5d, -0x2e6d17e7, -0x2966f9dc, -0xbf1ca7b, 0x106aa070,
        0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
        0x748f82ee, 0x78a5636f, -0x7b3787ec, -0x7338fdf8, -0x6f410006, -0x5baf9315, -0x41065c09, -0x398e870e
    ];

    function ushr(x as Lang.Number, n as Lang.Number) as Lang.Number {
        if (n <= 0) { return x; }
        var lx = x.toLong() & 0xFFFFFFFFl;
        return (lx >> n).toNumber();
    }
    function rotr(x as Lang.Number, n as Lang.Number) as Lang.Number {
        return ushr(x, n) | (x << (32 - n));
    }

    function hash(message as Lang.ByteArray) as Lang.ByteArray {
        var msgLen = message.size();
        var bitLen = msgLen * 8;
        var padLen = ((56 - (msgLen + 1) % 64) + 64) % 64;
        var totalLen = msgLen + 1 + padLen + 8;
        var padded = new [totalLen]b;
        for (var i = 0; i < msgLen; i++) { padded[i] = message[i]; }
        padded[msgLen] = 0x80;
        for (var i = msgLen + 1; i < msgLen + 1 + padLen; i++) { padded[i] = 0; }
        for (var i = 0; i < 8; i++) {
            var shift = (7 - i) * 8;
            padded[totalLen - 8 + i] = (shift < 32) ? ((bitLen >> shift) & 0xFF) : 0;
        }

        var h0 = 0x6a09e667; var h1 = -0x4498517b; var h2 = 0x3c6ef372; var h3 = -0x5ab00ac6;
        var h4 = 0x510e527f; var h5 = -0x64fa9774; var h6 = 0x1f83d9ab; var h7 = 0x5be0cd19;

        var chunks = totalLen / 64;
        var w = new [64] as Lang.Array<Lang.Number>;

        for (var c = 0; c < chunks; c++) {
            var base = c * 64;
            for (var t = 0; t < 16; t++) {
                var o = base + t * 4;
                w[t] = ((padded[o] & 0xFF) << 24) | ((padded[o + 1] & 0xFF) << 16) |
                       ((padded[o + 2] & 0xFF) << 8) | (padded[o + 3] & 0xFF);
            }
            for (var t = 16; t < 64; t++) {
                var s0 = rotr(w[t - 15], 7) ^ rotr(w[t - 15], 18) ^ ushr(w[t - 15], 3);
                var s1 = rotr(w[t - 2], 17) ^ rotr(w[t - 2], 19) ^ ushr(w[t - 2], 10);
                w[t] = w[t - 16] + s0 + w[t - 7] + s1;
            }

            var a = h0; var b = h1; var cc = h2; var d = h3;
            var e = h4; var f = h5; var g = h6; var h = h7;

            for (var t = 0; t < 64; t++) {
                var S1 = rotr(e, 6) ^ rotr(e, 11) ^ rotr(e, 25);
                var ch = (e & f) ^ ((~e) & g);
                var temp1 = h + S1 + ch + K[t] + w[t];
                var S0 = rotr(a, 2) ^ rotr(a, 13) ^ rotr(a, 22);
                var maj = (a & b) ^ (a & cc) ^ (b & cc);
                var temp2 = S0 + maj;
                h = g; g = f; f = e; e = d + temp1;
                d = cc; cc = b; b = a; a = temp1 + temp2;
            }

            h0 += a; h1 += b; h2 += cc; h3 += d; h4 += e; h5 += f; h6 += g; h7 += h;
        }

        var digest = new [32]b;
        writeWord(digest, 0, h0); writeWord(digest, 4, h1); writeWord(digest, 8, h2); writeWord(digest, 12, h3);
        writeWord(digest, 16, h4); writeWord(digest, 20, h5); writeWord(digest, 24, h6); writeWord(digest, 28, h7);
        return digest;
    }

    function writeWord(buf as Lang.ByteArray, offset as Lang.Number, word as Lang.Number) as Void {
        buf[offset] = (word >> 24) & 0xFF;
        buf[offset + 1] = (word >> 16) & 0xFF;
        buf[offset + 2] = (word >> 8) & 0xFF;
        buf[offset + 3] = word & 0xFF;
    }
}
