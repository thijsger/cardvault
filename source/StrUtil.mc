using Toybox.Lang;

// Kleine string-helpers zonder afhankelijkheid van String.split() (niet op
// alle API-levels beschikbaar) zodat dit op zoveel mogelijk devices draait.
module StrUtil {

    (:glance)
    function split(text as Lang.String, sep as Lang.String) as Lang.Array<Lang.String> {
        var parts = [] as Lang.Array<Lang.String>;
        var remaining = text;
        while (true) {
            var idx = remaining.find(sep);
            if (idx == null) {
                parts.add(remaining);
                break;
            }
            parts.add(remaining.substring(0, idx));
            remaining = remaining.substring(idx + sep.length(), remaining.length());
        }
        return parts;
    }

    // Escaped scheidingstekens ("\|") tijdelijk vervangen zodat split() ze
    // niet als veldgrens ziet, daarna terugzetten in elk veld.
    (:glance)
    function splitEscaped(text as Lang.String, sep as Lang.String) as Lang.Array<Lang.String> {
        var placeholder = "\u0001\u0001";
        var escaped = "\\" + sep;
        var protectedText = replaceAll(text, escaped, placeholder);
        var rawParts = split(protectedText, sep);
        var parts = [] as Lang.Array<Lang.String>;
        for (var i = 0; i < rawParts.size(); i++) {
            parts.add(replaceAll(rawParts[i], placeholder, sep));
        }
        return parts;
    }

    (:glance)
    function replaceAll(text as Lang.String, from as Lang.String, to as Lang.String) as Lang.String {
        var result = "";
        var remaining = text;
        while (true) {
            var idx = remaining.find(from);
            if (idx == null) {
                result += remaining;
                break;
            }
            result += remaining.substring(0, idx) + to;
            remaining = remaining.substring(idx + from.length(), remaining.length());
        }
        return result;
    }

    (:glance)
    function trim(text as Lang.String) as Lang.String {
        var start = 0;
        var end = text.length();
        while (start < end && text.substring(start, start + 1).equals(" ")) {
            start++;
        }
        while (end > start && text.substring(end - 1, end).equals(" ")) {
            end--;
        }
        return text.substring(start, end);
    }
}
