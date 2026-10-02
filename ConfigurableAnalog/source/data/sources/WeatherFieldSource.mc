import Toybox.Lang;
import Toybox.System;
import Toybox.Weather;

//! Slot sources read from the current weather conditions: humidity, wind, rain chance,
//! UV index and feels like temperature. One class, the kind picks the field.
class WeatherFieldSource extends DataSource {
    enum { KIND_HUMIDITY = 0, KIND_WIND = 1, KIND_RAIN = 2, KIND_UV = 3, KIND_FEELS = 4 }

    private var _id as String;
    private var _kind as Number;

    function initialize(id as String, labelRez as ResourceId, shortRez as ResourceId, iconRez as ResourceId?, kind as Number) {
        DataSource.initialize(labelRez, shortRez, iconRez);
        _id = id;
        _kind = kind;
    }

    function getId() as String {
        return _id;
    }

    function isSupported() as Boolean {
        return (Toybox has :Weather) && (Weather has :getCurrentConditions);
    }

    private function conditions() as Weather.CurrentConditions? {
        return isSupported() ? Weather.getCurrentConditions() : null;
    }

    function getPercent() as Number? {
        var current = conditions();
        if (current == null) {
            return null;
        }
        if (_kind == KIND_HUMIDITY) {
            return current.relativeHumidity;
        }
        if (_kind == KIND_RAIN) {
            return current.precipitationChance;
        }
        return null;
    }

    function getValue() as String {
        var current = conditions();
        if (current == null) {
            return Sources.PLACEHOLDER;
        }
        if (_kind == KIND_HUMIDITY || _kind == KIND_RAIN) {
            var percent = getPercent();
            return (percent == null) ? Sources.PLACEHOLDER : percent.toString() + "%";
        }
        if (_kind == KIND_WIND) {
            var speed = current.windSpeed;
            if (speed == null) {
                return Sources.PLACEHOLDER;
            }
            var factor = (System.getDeviceSettings().distanceUnits == System.UNIT_STATUTE) ? 2.23694 : 3.6;
            return (speed * factor).toNumber().toString();
        }
        if (_kind == KIND_UV) {
            var uv = current.uvIndex;
            return (uv == null) ? Sources.PLACEHOLDER : uv.toNumber().toString();
        }
        return WeatherCache.formatTemperature(current.feelsLikeTemperature);
    }
}
