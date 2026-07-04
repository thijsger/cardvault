using Toybox.Lang;

// EAN-13 en CODE128 (subset B) encoders. Beide geven een module-bitstring
// terug ("1" = zwarte bar, "0" = witte ruimte, één teken per module) zodat
// de renderer alle formaten identiek kan tekenen.
module Barcode {

    const EAN_L = [
        "0001101", "0011001", "0010011", "0111101", "0100011",
        "0110001", "0101111", "0111011", "0110111", "0001011"
    ];
    const EAN_G = [
        "0100111", "0110011", "0011011", "0100001", "0011101",
        "0111001", "0000101", "0010001", "0001001", "0010111"
    ];
    const EAN_R = [
        "1110010", "1100110", "1101100", "1000010", "1011100",
        "1001110", "1010000", "1000100", "1001000", "1110100"
    ];
    // Parity-patroon (L/G) voor cijfers 2-7, per eerste cijfer 0-9.
    const EAN_PARITY = [
        "LLLLLL", "LLGLGG", "LLGGLG", "LLGGGL", "LGLLGG",
        "LGGLLG", "LGGGLL", "LGLGLG", "LGLGGL", "LGGLGL"
    ];

    (:glance)
    function ean13CheckDigit(digits12 as Lang.String) as Lang.Number {
        var sum = 0;
        for (var i = 0; i < 12; i++) {
            var d = digits12.substring(i, i + 1).toNumber();
            sum += (i % 2 == 0) ? d : d * 3;
        }
        return (10 - (sum % 10)) % 10;
    }

    // data: 12 of 13 cijfers als string. Bij 12 wordt het checkcijfer berekend.
    (:glance)
    function encodeEan13(data as Lang.String) as Lang.String {
        var digits12 = data.substring(0, 12);
        var checkDigit = ean13CheckDigit(digits12);
        var full = digits12 + checkDigit.toString();

        var d1 = full.substring(0, 1).toNumber();
        var parity = EAN_PARITY[d1];

        var bits = "101";
        for (var i = 1; i < 7; i++) {
            var d = full.substring(i, i + 1).toNumber();
            var useG = parity.substring(i - 1, i).equals("G");
            bits += useG ? EAN_G[d] : EAN_L[d];
        }
        bits += "01010";
        for (var i = 7; i < 13; i++) {
            var d = full.substring(i, i + 1).toNumber();
            bits += EAN_R[d];
        }
        bits += "101";
        return bits;
    }

    // Widths-tabel voor CODE128 (waarden 0-106), 6 elementen per teken,
    // behalve STOP (106) met 7 elementen. Elk cijfer = aantal modules,
    // afwisselend bar/space, beginnend met bar.
    const CODE128_WIDTHS = [
        "212222", "222122", "222221", "121223", "121322", "131222", "122213",
        "122312", "132212", "221213", "221312", "231212", "112232", "122132",
        "122231", "113222", "123122", "123221", "223211", "221132", "221231",
        "213212", "223112", "312131", "311222", "321122", "321221", "312212",
        "322112", "322211", "212123", "212321", "232121", "111323", "131123",
        "131321", "112313", "132113", "132311", "211313", "231113", "231311",
        "112133", "112331", "132131", "113123", "113321", "133121", "313121",
        "211331", "231131", "213113", "213311", "213131", "311123", "311321",
        "331121", "312113", "312311", "332111", "314111", "221411", "431111",
        "111224", "111422", "121124", "121421", "141122", "141221", "112214",
        "112412", "122114", "122411", "142112", "142211", "241211", "221114",
        "413111", "241112", "134111", "111242", "121142", "121241", "114212",
        "124112", "124211", "411212", "421112", "421211", "212141", "214121",
        "412121", "111143", "111341", "131141", "114113", "114311", "411113",
        "411311", "113141", "114131", "311141", "411131",
        "211412", "211214", "211232", "2331112"
    ];

    const CODE128_START_B = 104;
    const CODE128_STOP = 106;

    (:glance)
    function widthsToBits(pattern as Lang.String) as Lang.String {
        var bits = "";
        var bar = true;
        for (var i = 0; i < pattern.length(); i++) {
            var n = pattern.substring(i, i + 1).toNumber();
            var ch = bar ? "1" : "0";
            for (var j = 0; j < n; j++) {
                bits += ch;
            }
            bar = !bar;
        }
        return bits;
    }

    // Alle 95 tekens van subset B, op volgorde -> index = code-waarde (0-94).
    const CODE128_B_CHARS =
        " !\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~";

    // text: ASCII 32-126 (subset B: cijfers, letters, leestekens, spatie).
    (:glance)
    function encodeCode128(text as Lang.String) as Lang.String {
        var values = [CODE128_START_B] as Lang.Array<Lang.Number>;
        for (var i = 0; i < text.length(); i++) {
            var ch = text.substring(i, i + 1);
            var code = CODE128_B_CHARS.find(ch);
            if (code == null) {
                code = 0; // niet-ondersteund teken -> spatie
            }
            values.add(code);
        }

        var checksum = CODE128_START_B;
        for (var i = 1; i < values.size(); i++) {
            checksum += values[i] * i;
        }
        values.add(checksum % 103);
        values.add(CODE128_STOP);

        var bits = "";
        for (var i = 0; i < values.size(); i++) {
            bits += widthsToBits(CODE128_WIDTHS[values[i]]);
        }
        return bits;
    }
}
