import Toybox.Complications;
import Toybox.Lang;
import Toybox.ActivityMonitor;
import Toybox.System;

class DistanceSource extends DataSource {
    function initialize() {
        DataSource.initialize(Rez.Strings.src_Distance, Rez.Strings.srcs_Distance, Rez.Drawables.icon_distance);
    }

    function getId() as String {
        return "Distance";
    }

    function isSupported() as Boolean {
        return Toybox has :ActivityMonitor;
    }

    function getValue() as String {
        var centimeters = ActivityMonitor.getInfo().distance;
        if (centimeters == null) {
            return Sources.PLACEHOLDER;
        }
        var metric = System.getDeviceSettings().distanceUnits == System.UNIT_METRIC;
        var value = centimeters / 100000.0;
        if (!metric) {
            value = value * 0.621371;
        }
        return value.format("%.1f") + (metric ? " KM" : " MI");
    }
}
