import Toybox.Complications;
import Toybox.Lang;
import Toybox.System;

class SolarIntensitySource extends DataSource {
    function initialize() {
        DataSource.initialize(Rez.Strings.src_SolarIntensity, Rez.Strings.srcs_SolarIntensity, Rez.Drawables.icon_solarintensity);
    }

    function getId() as String {
        return "SolarIntensity";
    }

    function getComplicationType() as Complications.Type? {
        return Complications.COMPLICATION_TYPE_SOLAR_INPUT;
    }

    function isSupported() as Boolean {
        return System.getSystemStats() has :solarIntensity;
    }

    function getValue() as String {
        var stats = System.getSystemStats();
        if (!(stats has :solarIntensity)) {
            return Sources.PLACEHOLDER;
        }
        var intensity = stats.solarIntensity;
        if (intensity == null) {
            return Sources.PLACEHOLDER;
        }
        return intensity.toString() + "%";
    }
}
