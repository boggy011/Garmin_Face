import Toybox.Complications;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;

//! Resolves and launches native complications for the press regions.
module ComplicationLaunch {
    var _ids as Dictionary<Number, Complications.Id> = {} as Dictionary<Number, Complications.Id>;
    var _checked as Dictionary<Number, Boolean> = {} as Dictionary<Number, Boolean>;

    //! Complication id for a system type when the device exposes it, else null. Cached.
    function idForType(type as Complications.Type?) as Complications.Id? {
        if (type == null) {
            return null;
        }
        if (!(Toybox has :Complications)) {
            return null;
        }
        var key = type as Number;
        if (_checked.hasKey(key)) {
            return _ids[key];
        }
        _checked[key] = true;
        try {
            var id = new Complications.Id(type);
            Complications.getComplication(id);
            _ids[key] = id;
            return id;
        } catch (e) {
            return null;
        }
    }

    //! Open the native detail app of a complication. False when the system refused.
    function launch(id as Complications.Id) as Boolean {
        try {
            Complications.exitTo(id);
            return true;
        } catch (e) {
            return false;
        }
    }
}

//! Fixed capacity table of press regions for the current page plus the centre cycling
//! circle. Renderers register their regions each time they lay out; registration updates
//! in place by id and never allocates. Regions that would overlap the centre circle or an
//! existing region are refused so the table is overlap free by construction.
module Regions {
    const CAPACITY = 16;
    const CENTER = 1;
    const CENTER_DIAMETER_PERCENT = 30;
    const MIN_SIZE_PERCENT = 15;

    const WEATHER_TEMPERATURE = 101;
    const WEATHER_PRECIPITATION = 102;
    const WEATHER_UV = 103;
    const WEATHER_PRESSURE = 104;
    const WEATHER_ICON = 105;
    const WEATHER_SUNRISE = 106;
    const WEATHER_SUNSET = 107;
    const HEALTH_HEART_RATE = 201;
    const HEALTH_STRESS = 202;
    const HEALTH_BODY_BATTERY = 203;
    const HEALTH_SPO2 = 204;
    const HEALTH_HRV = 205;

    var _ids as Array<Number> = new [CAPACITY] as Array<Number>;
    var _x as Array<Number> = new [CAPACITY] as Array<Number>;
    var _y as Array<Number> = new [CAPACITY] as Array<Number>;
    var _w as Array<Number> = new [CAPACITY] as Array<Number>;
    var _h as Array<Number> = new [CAPACITY] as Array<Number>;
    var _launch as Array<Complications.Id?> = new [CAPACITY] as Array<Complications.Id?>;
    var _count as Number = 0;
    var _refused as Number = 0;
    var _width as Number = 0;
    var _height as Number = 0;
    var _cx as Number = 0;
    var _cy as Number = 0;
    var _centerRadius as Number = 0;
    var _minSize as Number = 0;

    function configure(width as Number, height as Number) as Void {
        _width = width;
        _height = height;
        _cx = width / 2;
        _cy = height / 2;
        _centerRadius = width * CENTER_DIAMETER_PERCENT / 200;
        _minSize = width * MIN_SIZE_PERCENT / 100;
        for (var i = 0; i < CAPACITY; i++) {
            _ids[i] = 0;
            _x[i] = 0;
            _y[i] = 0;
            _w[i] = 0;
            _h[i] = 0;
            _launch[i] = null;
        }
        reset();
    }

    //! Minimum press target from the skin, never below MIN_SIZE_PERCENT of the width.
    function setMinimumSizePercent(percent as Number) as Void {
        var p = (percent < MIN_SIZE_PERCENT) ? MIN_SIZE_PERCENT : percent;
        _minSize = _width * p / 100;
    }

    //! Forget every region except the centre. Call when the page or skin changes.
    function reset() as Void {
        _count = 0;
        _refused = 0;
    }

    function getMinimumSize() as Number {
        return _minSize;
    }

    //! Register or update a region centred on (cx, cy) with at least the given content size.
    //! Returns false when the region has no launch target, would overlap the centre circle
    //! or an existing region, or the table is full.
    function register(id as Number, cx as Number, cy as Number, contentWidth as Number, contentHeight as Number, launch as Complications.Id?) as Boolean {
        if (launch == null) {
            return false;
        }
        var w = (contentWidth < _minSize) ? _minSize : contentWidth;
        var h = (contentHeight < _minSize) ? _minSize : contentHeight;
        var x = cx - w / 2;
        var y = cy - h / 2;
        var existing = indexOf(id);
        if (overlapsCenter(x, y, w, h) || overlapsOther(existing, x, y, w, h)) {
            _refused += 1;
            logRefused(id, x, y, w, h, overlapsCenter(x, y, w, h));
            return false;
        }
        var index = existing;
        if (index < 0) {
            if (_count >= CAPACITY) {
                return false;
            }
            index = _count;
            _count += 1;
            _ids[index] = id;
        }
        _x[index] = x;
        _y[index] = y;
        _w[index] = w;
        _h[index] = h;
        _launch[index] = launch;
        return true;
    }

    function indexOf(id as Number) as Number {
        for (var i = 0; i < _count; i++) {
            if (_ids[i] == id) {
                return i;
            }
        }
        return -1;
    }

    //! Rectangle versus the centre circle.
    function overlapsCenter(x as Number, y as Number, w as Number, h as Number) as Boolean {
        var nearestX = clampNumber(_cx, x, x + w);
        var nearestY = clampNumber(_cy, y, y + h);
        var dx = nearestX - _cx;
        var dy = nearestY - _cy;
        return dx * dx + dy * dy < _centerRadius * _centerRadius;
    }

    function overlapsOther(skipIndex as Number, x as Number, y as Number, w as Number, h as Number) as Boolean {
        for (var i = 0; i < _count; i++) {
            if (i == skipIndex) {
                continue;
            }
            if (x < _x[i] + _w[i] && x + w > _x[i] && y < _y[i] + _h[i] && y + h > _y[i]) {
                return true;
            }
        }
        return false;
    }

    function centerContains(x as Number, y as Number) as Boolean {
        var dx = x - _cx;
        var dy = y - _cy;
        return dx * dx + dy * dy <= _centerRadius * _centerRadius;
    }

    //! Region id under a point, or null when the point is in a gap.
    function hitTest(x as Number, y as Number) as Number? {
        for (var i = 0; i < _count; i++) {
            if (x >= _x[i] && x < _x[i] + _w[i] && y >= _y[i] && y < _y[i] + _h[i]) {
                return _ids[i];
            }
        }
        return null;
    }

    function launchIdFor(id as Number) as Complications.Id? {
        var index = indexOf(id);
        return (index < 0) ? null : _launch[index];
    }

    function getCount() as Number {
        return _count;
    }

    //! Number of registrations refused because they would overlap. Zero in a correct skin.
    function getRefusedCount() as Number {
        return _refused;
    }

    //! Pairs of registered regions that overlap. Always zero by construction, tests assert it.
    function overlapCount() as Number {
        var overlaps = 0;
        for (var i = 0; i < _count; i++) {
            if (overlapsCenter(_x[i], _y[i], _w[i], _h[i])) {
                overlaps += 1;
            }
            for (var j = i + 1; j < _count; j++) {
                if (_x[i] < _x[j] + _w[j] && _x[i] + _w[i] > _x[j] && _y[i] < _y[j] + _h[j] && _y[i] + _h[i] > _y[j]) {
                    overlaps += 1;
                }
            }
        }
        return overlaps;
    }

    function clampNumber(value as Number, low as Number, high as Number) as Number {
        if (value < low) {
            return low;
        }
        if (value > high) {
            return high;
        }
        return value;
    }

    (:debug)
    var _logged as Array<Number> = [] as Array<Number>;

    (:debug)
    function logRefused(id as Number, x as Number, y as Number, w as Number, h as Number, centre as Boolean) as Void {
        if (_logged.indexOf(id) >= 0) {
            return;
        }
        _logged.add(id);
        System.println("Regions: refused id " + id + " at " + x + "," + y + " " + w + "x" + h + (centre ? " (centre circle)" : " (overlaps another region)"));
    }

    (:release)
    function logRefused(id as Number, x as Number, y as Number, w as Number, h as Number, centre as Boolean) as Void {
    }

    //! Debug builds: report layouts whose regions had to be refused.
    (:debug)
    function assertLayout(tag as String) as Void {
        if (_refused > 0 || overlapCount() > 0) {
            System.println("Regions: " + tag + " refused " + _refused + " overlapping region(s), overlaps " + overlapCount());
        }
    }

    (:release)
    function assertLayout(tag as String) as Void {
    }
}
