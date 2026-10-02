import Toybox.Complications;
import Toybox.Lang;

//! A slot source backed by one system complication. One class serves every complication
//! that only needs its value formatted, which keeps code and memory small. kind picks the
//! formatting: plain number, percent with a rim gauge, minutes shown as hours, pascals in
//! the pressure unit setting, or short text.
class ComplicationSource extends DataSource {
    enum { KIND_PLAIN = 0, KIND_PERCENT = 1, KIND_MINUTES_AS_HOURS = 2, KIND_PASCALS = 3, KIND_TEXT = 4 }
    const MAX_TEXT = 7;

    private var _id as String;
    private var _type as Complications.Type;
    private var _kind as Number;

    function initialize(id as String, labelRez as ResourceId, shortRez as ResourceId, iconRez as ResourceId?, type as Complications.Type, kind as Number) {
        DataSource.initialize(labelRez, shortRez, iconRez);
        _id = id;
        _type = type;
        _kind = kind;
    }

    function getId() as String {
        return _id;
    }

    function getComplicationType() as Complications.Type? {
        return _type;
    }

    function isSupported() as Boolean {
        return (Toybox has :Complications) && (Complications has :getComplication);
    }

    //! Raw complication value, or null when the device has no such complication.
    private function read() as Lang.Object? {
        if (!isSupported()) {
            return null;
        }
        try {
            return Complications.getComplication(new Complications.Id(_type)).value;
        } catch (e) {
            return null;
        }
    }

    function getPercent() as Number? {
        if (_kind != KIND_PERCENT) {
            return null;
        }
        var value = read();
        return (value instanceof Number || value instanceof Float) ? value.toNumber() : null;
    }

    function getValue() as String {
        var value = read();
        if (value == null) {
            return Sources.PLACEHOLDER;
        }
        if (value instanceof String) {
            return shortText(value);
        }
        if (!(value instanceof Number || value instanceof Float)) {
            return Sources.PLACEHOLDER;
        }
        if (_kind == KIND_PASCALS) {
            return WeatherCache.formatPressure(value.toFloat());
        }
        if (_kind == KIND_MINUTES_AS_HOURS) {
            return ((value.toNumber() + 30) / 60).toString() + "H";
        }
        if (_kind == KIND_PERCENT) {
            return value.toNumber().toString() + "%";
        }
        return value.toNumber().toString();
    }

    //! Uppercase text cut to what fits a panel. Known training status words get short forms.
    private function shortText(text as String) as String {
        var upper = text.toUpper();
        if (_kind == KIND_TEXT) {
            var known = ["PRODUCTIVE", "MAINTAINING", "RECOVERY", "UNPRODUCTIVE", "PEAKING", "DETRAINING", "OVERREACHING", "STRAINED", "NO RESULT", "NO STATUS"] as Array<String>;
            var short = ["PROD", "MAINT", "RECOV", "UNPROD", "PEAK", "DETRAIN", "OVERRCH", "STRAIN", "--", "--"] as Array<String>;
            for (var i = 0; i < known.size(); i++) {
                if (upper.equals(known[i])) {
                    return short[i];
                }
            }
        }
        return (upper.length() > MAX_TEXT) ? upper.substring(0, MAX_TEXT) as String : upper;
    }
}
