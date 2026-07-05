using Toybox.Lang;

// QR-encoder: byte-mode, error-correctielevel M, versies 1-10 (21x21 t/m 57x57).
// Geport van een geverifieerde referentie (RS-syndromen nul voor alle versies,
// inclusief multi-block interleaving). Gebruikt platte ByteArrays voor de matrix
// (veel sneller dan geneste arrays in Monkey C) en vast masker 0 om binnen de
// watchdog-tijd te blijven; het gebruikte masker staat in de format-bits, dus
// elke scanner leest dit gewoon.
module Qr {

    // Per versie (1..10) bij level M:
    // [total_data_cw, ecc_per_block, group1_blocks, g1_data_cw, group2_blocks, g2_data_cw]
    const VERSION_M = [
        [16, 10, 1, 16, 0, 0],
        [28, 16, 1, 28, 0, 0],
        [44, 26, 1, 44, 0, 0],
        [64, 18, 2, 32, 0, 0],
        [86, 24, 2, 43, 0, 0],
        [108, 16, 4, 27, 0, 0],
        [124, 18, 4, 31, 0, 0],
        [154, 22, 2, 38, 2, 39],
        [182, 22, 3, 36, 2, 37],
        [216, 26, 4, 43, 1, 44]
    ];

    const ALIGN = [
        [], [6, 18], [6, 22], [6, 26], [6, 30],
        [6, 34], [6, 22, 38], [6, 24, 42], [6, 26, 46], [6, 28, 50]
    ];

    var _exp = new [512];
    var _log = new [256];
    var _gfReady = false;

    function initGf() as Void {
        if (_gfReady) { return; }
        var x = 1;
        for (var i = 0; i < 255; i++) {
            _exp[i] = x;
            _log[x] = i;
            x = x << 1;
            if ((x & 0x100) != 0) { x = x ^ 0x11d; }
        }
        for (var i = 255; i < 512; i++) { _exp[i] = _exp[i - 255]; }
        _gfReady = true;
    }

    function gmul(a as Lang.Number, b as Lang.Number) as Lang.Number {
        if (a == 0 || b == 0) { return 0; }
        return _exp[_log[a] + _log[b]];
    }

    function rsGen(deg as Lang.Number) as Lang.Array<Lang.Number> {
        var g = [1] as Lang.Array<Lang.Number>;
        for (var i = 0; i < deg; i++) {
            var ng = new [g.size() + 1] as Lang.Array<Lang.Number>;
            for (var j = 0; j < ng.size(); j++) { ng[j] = 0; }
            for (var j = 0; j < g.size(); j++) {
                ng[j] = ng[j] ^ g[j];
                ng[j + 1] = ng[j + 1] ^ gmul(g[j], _exp[i]);
            }
            g = ng;
        }
        return g;
    }

    function rsEcc(data as Lang.Array<Lang.Number>, deg as Lang.Number, gen as Lang.Array<Lang.Number>) as Lang.Array<Lang.Number> {
        var msg = new [data.size() + deg] as Lang.Array<Lang.Number>;
        for (var i = 0; i < data.size(); i++) { msg[i] = data[i]; }
        for (var i = data.size(); i < msg.size(); i++) { msg[i] = 0; }
        for (var i = 0; i < data.size(); i++) {
            var coef = msg[i];
            if (coef != 0) {
                for (var j = 0; j < gen.size(); j++) {
                    msg[i + j] = msg[i + j] ^ gmul(gen[j], coef);
                }
            }
        }
        var ecc = new [deg] as Lang.Array<Lang.Number>;
        for (var i = 0; i < deg; i++) { ecc[i] = msg[data.size() + i]; }
        return ecc;
    }

    function capacityBytes(v as Lang.Number) as Lang.Number {
        var total = VERSION_M[v - 1][0];
        var countBits = (v < 10) ? 8 : 16;
        return (total * 8 - 4 - countBits) / 8;
    }

    function chooseVersion(n as Lang.Number) as Lang.Number {
        for (var v = 1; v <= 10; v++) {
            if (capacityBytes(v) >= n) { return v; }
        }
        return -1;
    }

    function encodeCodewords(bytes as Lang.ByteArray, v as Lang.Number) as Lang.Array<Lang.Number> {
        var n = bytes.size();
        var total = VERSION_M[v - 1][0];
        var countBits = (v < 10) ? 8 : 16;

        var bits = [] as Lang.Array<Lang.Number>;
        putBits(bits, 0x4, 4);
        putBits(bits, n, countBits);
        for (var i = 0; i < n; i++) { putBits(bits, bytes[i] & 0xFF, 8); }

        var cap = total * 8;
        var term = 4;
        if (cap - bits.size() < 4) { term = cap - bits.size(); }
        if (term < 0) { term = 0; }
        putBits(bits, 0, term);
        while (bits.size() % 8 != 0) { bits.add(0); }

        var cw = [] as Lang.Array<Lang.Number>;
        for (var i = 0; i < bits.size(); i += 8) {
            var b = 0;
            for (var j = 0; j < 8; j++) { b = (b << 1) | bits[i + j]; }
            cw.add(b);
        }
        var pad = [0xEC, 0x11];
        var k = 0;
        while (cw.size() < total) { cw.add(pad[k % 2]); k++; }
        return cw;
    }

    function putBits(bits as Lang.Array<Lang.Number>, val as Lang.Number, len as Lang.Number) as Void {
        for (var i = len - 1; i >= 0; i--) { bits.add((val >> i) & 1); }
    }

    function interleave(cw as Lang.Array<Lang.Number>, v as Lang.Number) as Lang.Array<Lang.Number> {
        var spec = VERSION_M[v - 1];
        var eccPer = spec[1];
        var g1 = spec[2]; var d1 = spec[3];
        var g2 = spec[4]; var d2 = spec[5];
        var nb = g1 + g2;
        var gen = rsGen(eccPer);

        var blocks = [] as Lang.Array;
        var eccs = [] as Lang.Array;
        var idx = 0;
        for (var b = 0; b < nb; b++) {
            var dlen = (b < g1) ? d1 : d2;
            var blk = new [dlen] as Lang.Array<Lang.Number>;
            for (var i = 0; i < dlen; i++) { blk[i] = cw[idx]; idx++; }
            blocks.add(blk);
            eccs.add(rsEcc(blk, eccPer, gen));
        }

        var out = [] as Lang.Array<Lang.Number>;
        var maxD = (d1 > d2) ? d1 : d2;
        for (var i = 0; i < maxD; i++) {
            for (var b = 0; b < nb; b++) {
                var blk = blocks[b] as Lang.Array<Lang.Number>;
                if (i < blk.size()) { out.add(blk[i]); }
            }
        }
        for (var i = 0; i < eccPer; i++) {
            for (var b = 0; b < nb; b++) {
                var e = eccs[b] as Lang.Array<Lang.Number>;
                out.add(e[i]);
            }
        }
        return out;
    }

    // Masker 0: (r+c) % 2 == 0.
    const FMT_POLY = 0x537;
    function formatBits(mask as Lang.Number) as Lang.Number {
        var d = (0x0 << 3) | mask;
        var rem = d << 10;
        for (var i = 14; i >= 10; i--) {
            if (((rem >> i) & 1) != 0) { rem = rem ^ (FMT_POLY << (i - 10)); }
        }
        return ((d << 10) | rem) ^ 0x5412;
    }

    // Platte matrix-helpers: index = r*size + c.
    function mget(m as Lang.ByteArray, size as Lang.Number, r as Lang.Number, c as Lang.Number) as Lang.Number {
        return m[r * size + c];
    }
    function mset(m as Lang.ByteArray, func as Lang.ByteArray, size as Lang.Number, r as Lang.Number, c as Lang.Number, val as Lang.Number) as Void {
        m[r * size + c] = val;
        func[r * size + c] = 1;
    }

    // Hoofdfunctie: tekst -> platte ByteArray-matrix (size*size van 0/1) of null.
    // Geeft [size, matrix] terug.
    function encode(text as Lang.String) as Lang.Array or Null {
        initGf();
        var bytes = strToBytes(text);
        var v = chooseVersion(bytes.size());
        if (v < 0) { return null; }

        var cw = encodeCodewords(bytes, v);
        var data = interleave(cw, v);
        var size = 17 + 4 * v;
        var total = size * size;

        var m = new [total]b;
        var func = new [total]b;
        for (var i = 0; i < total; i++) { m[i] = 0; func[i] = 0; }

        placeFinder(m, func, size, 0, 0);
        placeFinder(m, func, size, 0, size - 7);
        placeFinder(m, func, size, size - 7, 0);

        for (var i = 0; i < size; i++) {
            if (func[6 * size + i] == 0) { mset(m, func, size, 6, i, (i % 2 == 0) ? 1 : 0); }
            if (func[i * size + 6] == 0) { mset(m, func, size, i, 6, (i % 2 == 0) ? 1 : 0); }
        }

        var pos = ALIGN[v - 1];
        for (var a = 0; a < pos.size(); a++) {
            for (var bb = 0; bb < pos.size(); bb++) {
                var pr = pos[a]; var pc = pos[bb];
                if (func[pr * size + pc] != 0) { continue; }
                var clear = true;
                for (var dr = -2; dr <= 2 && clear; dr++) {
                    for (var dc = -2; dc <= 2; dc++) {
                        if (func[(pr + dr) * size + (pc + dc)] != 0) { clear = false; }
                    }
                }
                if (!clear) { continue; }
                for (var dr = -2; dr <= 2; dr++) {
                    for (var dc = -2; dc <= 2; dc++) {
                        var on = (abs(dr) == 2 || abs(dc) == 2 || (dr == 0 && dc == 0));
                        mset(m, func, size, pr + dr, pc + dc, on ? 1 : 0);
                    }
                }
            }
        }

        mset(m, func, size, size - 8, 8, 1);

        // format-gebieden reserveren
        for (var i = 0; i < 9; i++) { func[8 * size + i] = 1; func[i * size + 8] = 1; }
        for (var i = 0; i < 8; i++) { func[8 * size + (size - 1 - i)] = 1; func[(size - 1 - i) * size + 8] = 1; }

        // data plaatsen (zigzag) + masker 0 direct toepassen
        var totalBits = data.size() * 8;
        var bi = 0;
        var col = size - 1;
        var up = true;
        while (col > 0) {
            if (col == 6) { col--; }
            var row = up ? (size - 1) : 0;
            while (row >= 0 && row < size) {
                for (var t = 0; t < 2; t++) {
                    var cc = col - t;
                    var fi = row * size + cc;
                    if (func[fi] == 0) {
                        var bit = 0;
                        if (bi < totalBits) {
                            bit = (data[bi >> 3] >> (7 - (bi & 7))) & 1;
                        }
                        // masker 0
                        if ((row + cc) % 2 == 0) { bit = bit ^ 1; }
                        m[fi] = bit;
                        bi++;
                    }
                }
                row = up ? (row - 1) : (row + 1);
            }
            up = !up;
            col -= 2;
        }

        // format-bits plaatsen (masker 0)
        var fb = formatBits(0);
        for (var i = 0; i < 6; i++) { m[8 * size + i] = (fb >> i) & 1; }
        m[8 * size + 7] = (fb >> 6) & 1; m[8 * size + 8] = (fb >> 7) & 1; m[7 * size + 8] = (fb >> 8) & 1;
        for (var i = 9; i < 15; i++) { m[(14 - i) * size + 8] = (fb >> i) & 1; }
        for (var i = 0; i < 8; i++) { m[(size - 1 - i) * size + 8] = (fb >> i) & 1; }
        for (var i = 8; i < 15; i++) { m[8 * size + (size - 8 + (i - 7))] = (fb >> i) & 1; }

        return [size, m];
    }

    function setF(m as Lang.ByteArray, func as Lang.ByteArray, r as Lang.Number, c as Lang.Number, val as Lang.Number, size as Lang.Number) as Void {
        m[r * size + c] = val; func[r * size + c] = 1;
    }

    function placeFinder(m as Lang.ByteArray, func as Lang.ByteArray, size as Lang.Number, r as Lang.Number, c as Lang.Number) as Void {
        for (var dr = -1; dr <= 7; dr++) {
            for (var dc = -1; dc <= 7; dc++) {
                var rr = r + dr; var cc = c + dc;
                if (rr >= 0 && rr < size && cc >= 0 && cc < size) {
                    var on = ((dr >= 0 && dr <= 6 && (dc == 0 || dc == 6)) ||
                              (dc >= 0 && dc <= 6 && (dr == 0 || dr == 6)) ||
                              (dr >= 2 && dr <= 4 && dc >= 2 && dc <= 4));
                    mset(m, func, size, rr, cc, on ? 1 : 0);
                }
            }
        }
    }

    function abs(x as Lang.Number) as Lang.Number { return (x < 0) ? -x : x; }

    function strToBytes(text as Lang.String) as Lang.ByteArray {
        var chars = text.toUtf8Array();
        var b = new [chars.size()]b;
        for (var i = 0; i < chars.size(); i++) { b[i] = chars[i] & 0xFF; }
        return b;
    }
}
