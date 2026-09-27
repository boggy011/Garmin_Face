import Toybox.Complications;
import Toybox.Lang;
import Toybox.System;
import Toybox.Weather;

class WeatherSource extends DataSource {
    function initialize() {
        DataSource.initialize(Rez.Strings.src_Weather, Rez.Strings.srcs_Weather, Rez.Drawables.icon_weather);
    }

    function getId() as String {
        return "Weather";
    }

    function getComplicationType() as Complications.Type? {
        return Complications.COMPLICATION_TYPE_CURRENT_TEMPERATURE;
    }

    function isSupported() as Boolean {
        return (Toybox has :Weather) && (Weather has :getCurrentConditions);
    }

    function getValue() as String {
        if (!isSupported()) {
            return Sources.PLACEHOLDER;
        }
        var conditions = Weather.getCurrentConditions();
        if (conditions == null) {
            return Sources.PLACEHOLDER;
        }
        var celsius = conditions.temperature;
        if (celsius == null) {
            return Sources.PLACEHOLDER;
        }
        var value = celsius;
        if (System.getDeviceSettings().temperatureUnits == System.UNIT_STATUTE) {
            value = value * 9 / 5 + 32;
        }
        return value.toString() + "°";
    }
}
