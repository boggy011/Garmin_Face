import Toybox.Complications;
import Toybox.Lang;
import Toybox.System;

class BatterySource extends DataSource {
    function initialize() {
        DataSource.initialize(Rez.Strings.src_Battery, Rez.Drawables.icon_battery);
    }

    function getId() as String {
        return "Battery";
    }

    function getComplicationType() as Complications.Type? {
        return Complications.COMPLICATION_TYPE_BATTERY;
    }

    function getValue() as String {
        var battery = System.getSystemStats().battery;
        return battery.toNumber().toString() + "%";
    }
}
