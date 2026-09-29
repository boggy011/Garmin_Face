import Toybox.Complications;
import Toybox.Lang;
import Toybox.SensorHistory;
import Toybox.Time;

class BodyBatterySource extends DataSource {
    function initialize() {
        DataSource.initialize(Rez.Strings.src_BodyBattery, Rez.Strings.srcs_BodyBattery, Rez.Drawables.icon_bodybattery);
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

    function getPercent() as Number? {
        if (!isSupported()) {
            return null;
        }
        var iterator = SensorHistory.getBodyBatteryHistory({:period => new Time.Duration(Sources.HISTORY_WINDOW_SECONDS), :order => SensorHistory.ORDER_NEWEST_FIRST});
        return Sources.latestHistoryValue(iterator, Sources.HISTORY_MAX_SAMPLES);
    }

    function getValue() as String {
        return Sources.formatNumber(getPercent());
    }
}
