import Toybox.Complications;
import Toybox.Lang;
import Toybox.SensorHistory;

class BodyBatterySource extends DataSource {
    function initialize() {
        DataSource.initialize(Rez.Strings.src_BodyBattery, Rez.Drawables.icon_bodybattery);
    }

    function getId() as String {
        return "BodyBattery";
    }

    function getComplicationType() as Complications.Type? {
        return Complications.COMPLICATION_TYPE_BODY_BATTERY;
    }

    function isSupported() as Boolean {
        return (Toybox has :SensorHistory) && (SensorHistory has :getBodyBatteryHistory);
    }

    function getValue() as String {
        if (!isSupported()) {
            return Sources.PLACEHOLDER;
        }
        var sample = SensorHistory.getBodyBatteryHistory({:period => 1, :order => SensorHistory.ORDER_NEWEST_FIRST}).next();
        if (sample == null) {
            return Sources.PLACEHOLDER;
        }
        var data = sample.data;
        if (data == null) {
            return Sources.PLACEHOLDER;
        }
        return data.toNumber().toString();
    }
}
