import Toybox.Complications;
import Toybox.Lang;

//! Nearest calendar event from the system calendar complication: value is its time, the
//! dynamic label its title, scrolling when it is longer than the panel. Dash when the
//! device or the calendar offers nothing.
class NextEventSource extends DataSource {
    const LABEL_MAX = 9;

    private var _title as String?;
    private var _full as String = "";
    private var _offset as Number = 0;

    function initialize() {
        DataSource.initialize(Rez.Strings.src_NextEvent, Rez.Strings.srcs_NextEvent, null);
    }

    function getId() as String {
        return "NextEvent";
    }

    function getComplicationType() as Complications.Type? {
        return Complications.COMPLICATION_TYPE_CALENDAR_EVENTS;
    }

    function isSupported() as Boolean {
        return (Toybox has :Complications) && (Complications has :getComplication);
    }

    function getValue() as String {
        _title = null;
        if (!isSupported()) {
            return Sources.PLACEHOLDER;
        }
        try {
            var complication = Complications.getComplication(new Complications.Id(Complications.COMPLICATION_TYPE_CALENDAR_EVENTS));
            var value = complication.value;
            var label = complication.shortLabel;
            if (label == null) {
                label = complication.longLabel;
            }
            if (label != null) {
                var upper = label.toUpper();
                if (upper.length() <= LABEL_MAX) {
                    _title = upper;
                } else {
                    if (!upper.equals(_full)) {
                        _full = upper + "   ";
                        _offset = 0;
                    }
                    _title = window(_full, _offset, LABEL_MAX);
                    _offset = (_offset + 1) % _full.length();
                }
            }
            if (value == null) {
                return Sources.PLACEHOLDER;
            }
            return value.toString();
        } catch (e) {
            return Sources.PLACEHOLDER;
        }
    }

    //! Characters [start, start + count) of text, wrapping around, so long titles scroll.
    private function window(text as String, start as Number, count as Number) as String {
        var length = text.length();
        var end = start + count;
        if (end <= length) {
            var part = text.substring(start, end);
            return (part == null) ? text : part;
        }
        var head = text.substring(start, length);
        var tail = text.substring(0, end - length);
        return ((head == null) ? "" : head) + ((tail == null) ? "" : tail);
    }

    //! Event title, refreshed by getValue. Long titles scroll one character per refresh.
    function getDynamicLabel() as String? {
        return _title;
    }
}
