using Toybox.Lang;
using Toybox.Time;

// RFC 6238 TOTP, gebouwd op Hmac.sha1() en Base32.decode().
module Totp {

    // Garmin's Moment.value() telt seconden sinds 1989-12-31 00:00:00 UTC,
    // niet sinds de Unix-epoch. Offset is nodig zodat de counter matcht
    // met de server (die altijd Unix-tijd gebruikt).
    const GARMIN_EPOCH_OFFSET = 631065600l;

    (:glance)
    function currentUnixTime() as Lang.Long {
        return Time.now().value().toLong() + GARMIN_EPOCH_OFFSET;
    }

    (:glance)
    function secondsRemaining(period as Lang.Number) as Lang.Number {
        var t = currentUnixTime();
        return (period - (t % period).toNumber()).toNumber();
    }

    // secretBase32: TOTP-secret zoals getoond door de dienst (base32, geen spaties).
    // algo: "SHA1" of "SHA256" (SHA512 valt terug op SHA256-mac-lengte niet nodig hier).
    (:glance)
    function generate(secretBase32 as Lang.String, period as Lang.Number, digits as Lang.Number, algo as Lang.String) as Lang.String {
        var secret = Base32.decode(secretBase32);
        var counter = currentUnixTime() / period.toLong();
        var counterBytes = longToBytes(counter);

        var mac;
        if (algo != null && algo.equals("SHA256")) {
            mac = Hmac.sha256(secret, counterBytes);
        } else {
            mac = Hmac.sha1(secret, counterBytes);
        }
        // Dynamische truncatie gebruikt de laatste nibble als offset.
        var offset = mac[mac.size() - 1] & 0x0F;

        var binCode = ((mac[offset] & 0x7f) << 24) |
                      ((mac[offset + 1] & 0xff) << 16) |
                      ((mac[offset + 2] & 0xff) << 8) |
                      (mac[offset + 3] & 0xff);

        var mod = 1;
        for (var i = 0; i < digits; i++) {
            mod *= 10;
        }
        var otp = binCode % mod;

        var s = otp.toString();
        while (s.length() < digits) {
            s = "0" + s;
        }
        return s;
    }

    (:glance)
    function longToBytes(value as Lang.Long) as Lang.ByteArray {
        var b = new [8]b;
        var v = value;
        for (var i = 7; i >= 0; i--) {
            b[i] = (v & 0xFFl).toNumber();
            v = v >> 8;
        }
        return b;
    }
}
