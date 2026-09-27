import Toybox.Complications;
import Toybox.Lang;
import Toybox.Activity;
import Toybox.System;

class AltitudeSource extends DataSource {
    function initialize() {
        DataSource.initialize(Rez.Strings.src_Altitude, Rez.Strings.srcs_Altitude, Rez.Drawables.icon_altitude);
    }

    function getId() as String {
        return "Altitude";
    }

    function getComplicationType() as Complications.Type? {
        return Complications.COMPLICATION_TYPE_ALTITUDE;
    }

    function isSupported() as Boolean {
        return Activity has :getActivityInfo;
    }

    function getValue() as String {
        var meters = Activity.getActivityInfo().altitude;
        if (meters == null) {
            return Sources.PLACEHOLDER;
        }
        var metric = System.getDeviceSettings().elevationUnits == System.UNIT_METRIC;
        var value = metric ? meters : meters * 3.28084;
        return value.toNumber().toString() + (metric ? " M" : " FT");
    }
}
