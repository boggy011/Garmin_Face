import Toybox.Activity;
import Toybox.ActivityMonitor;
import Toybox.Complications;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Position;
import Toybox.SensorHistory;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.WatchUi;
import Toybox.Weather;

//! Shared helpers for data sources.
module Sources {
    const PLACEHOLDER = "--";
    const SECONDS_PER_DAY = 86400;
    //! Sensor history is searched this far back for the newest sample that carries a value.
    const HISTORY_WINDOW_SECONDS = 2 * 3600;
    const HISTORY_MAX_SAMPLES = 60;
    const HEART_RATE_WINDOW_SECONDS = 600;

    //! Format a clock time honouring the device 12/24 hour setting.
    function formatClock(hour as Number, minute as Number) as String {
        var h = hour;
        if (!System.getDeviceSettings().is24Hour) {
            h = h % 12;
            if (h == 0) {
                h = 12;
            }
        }
        return h.toString() + ":" + minute.format("%02d");
    }

    //! Format a moment as local clock time.
    function formatMoment(moment as Time.Moment) as String {
        var info = Gregorian.info(moment, Time.FORMAT_SHORT);
        return formatClock(info.hour, info.min);
    }

    //! Format a nullable integer, or the placeholder.
    function formatNumber(value as Number?) as String {
        if (value == null) {
            return PLACEHOLDER;
        }
        return value.toString();
    }

    //! Newest value in a SensorHistory window. On a real watch the newest sample is often
    //! empty (stress is not computed while moving, body battery pauses during activities),
    //! so walk back through recent samples instead of reading only the first one.
    function latestHistoryValue(iterator as SensorHistory.SensorHistoryIterator?, maxSamples as Number) as Number? {
        if (iterator == null) {
            return null;
        }
        var sample = iterator.next();
        var steps = 0;
        while (sample != null && steps < maxSamples) {
            var data = sample.data;
            if (data != null) {
                return data.toNumber();
            }
            sample = iterator.next();
            steps += 1;
        }
        return null;
    }

    //! Live heart rate, else the newest valid sample of the last ten minutes. Watch faces
    //! only get a live value while the optical sensor is sampling.
    function latestHeartRate() as Number? {
        var rate = Activity.getActivityInfo().currentHeartRate;
        if (rate != null || !(ActivityMonitor has :getHeartRateHistory)) {
            return rate;
        }
        var iterator = ActivityMonitor.getHeartRateHistory(new Time.Duration(HEART_RATE_WINDOW_SECONDS), true);
        var sample = iterator.next();
        var steps = 0;
        while (sample != null && steps < HISTORY_MAX_SAMPLES) {
            var value = sample.heartRate;
            if (value != ActivityMonitor.INVALID_HR_SAMPLE) {
                return value;
            }
            sample = iterator.next();
            steps += 1;
        }
        return null;
    }

    //! Best known location: weather observation position, else the last activity position.
    function currentLocation() as Position.Location? {
        if ((Toybox has :Weather) && (Weather has :getCurrentConditions)) {
            var conditions = Weather.getCurrentConditions();
            if (conditions != null) {
                var position = conditions.observationLocationPosition;
                if (position != null) {
                    return position;
                }
            }
        }
        return Activity.getActivityInfo().currentLocation;
    }

    //! Sunrise or sunset today at the current location as clock time.
    function formatSunEvent(sunrise as Boolean) as String {
        if (!(Toybox has :Weather) || !(Weather has :getSunrise)) {
            return PLACEHOLDER;
        }
        var location = currentLocation();
        if (location == null) {
            return PLACEHOLDER;
        }
        var now = Time.now();
        var moment = sunrise ? Weather.getSunrise(location, now) : Weather.getSunset(location, now);
        if (moment == null) {
            return PLACEHOLDER;
        }
        return formatMoment(moment);
    }
}

//! Base class for every slot data source. Subclasses override getId and getValue and,
//! where relevant, isSupported and getComplicationType.
class DataSource {
    private var _labelRez as ResourceId;
    private var _shortRez as ResourceId;
    private var _iconRez as ResourceId?;
    private var _label as String?;
    private var _short as String?;
    private var _icon as BitmapResource or BitmapReference or Null;

    function initialize(labelRez as ResourceId, shortRez as ResourceId, iconRez as ResourceId?) {
        _labelRez = labelRez;
        _shortRez = shortRez;
        _iconRez = iconRez;
    }

    //! Stable id, must match tools/sources.yaml.
    function getId() as String {
        return SettingsKeys.EMPTY_SOURCE_ID;
    }

    //! Translated label, loaded once.
    function getLabel() as String {
        var label = _label;
        if (label == null) {
            label = WatchUi.loadResource(_labelRez) as String;
            _label = label;
        }
        return label;
    }

    //! Short uppercase label for panels, loaded once.
    function getShortLabel() as String {
        var label = _short;
        if (label == null) {
            label = WatchUi.loadResource(_shortRez) as String;
            _short = label;
        }
        return label;
    }

    //! Icon bitmap, loaded on first use, or null when the source has none.
    function getIcon() as BitmapResource or BitmapReference or Null {
        var rez = _iconRez;
        if (rez == null) {
            return null;
        }
        var icon = _icon;
        if (icon == null) {
            icon = WatchUi.loadResource(rez) as BitmapResource or BitmapReference;
            _icon = icon;
        }
        return icon;
    }

    //! Whether the device exposes the data (has checks only, never device names).
    function isSupported() as Boolean {
        return true;
    }

    //! Formatted value or the placeholder.
    function getValue() as String {
        return Sources.PLACEHOLDER;
    }

    //! System complication type the on-device editor maps to this source, or null.
    function getComplicationType() as Complications.Type? {
        return null;
    }

    //! Label that changes with the value (for example an event title), or null for the static one.
    function getDynamicLabel() as String? {
        return null;
    }

    //! 0..100 value for a rim gauge when the source is a percentage, else null.
    function getPercent() as Number? {
        return null;
    }
}
