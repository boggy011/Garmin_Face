import Toybox.Complications;
import Toybox.Lang;
import Toybox.SensorHistory;
import Toybox.Time;

class StressSource extends DataSource {
    function initialize() {
        DataSource.initialize(Rez.Strings.src_Stress, Rez.Strings.srcs_Stress, Rez.Drawables.icon_stress);
    }

    function getId() as String {
        return "Stress";
    }

    function getComplicationType() as Complications.Type? {
        return Complications.COMPLICATION_TYPE_STRESS;
    }

    function isSupported() as Boolean {
        return (Toybox has :SensorHistory) && (SensorHistory has :getStressHistory);
    }

    function getPercent() as Number? {
        if (!isSupported()) {
            return null;
        }
        var iterator = SensorHistory.getStressHistory({:period => new Time.Duration(Sources.HISTORY_WINDOW_SECONDS), :order => SensorHistory.ORDER_NEWEST_FIRST});
        return Sources.latestHistoryValue(iterator, Sources.HISTORY_MAX_SAMPLES);
    }

    function getValue() as String {
        return Sources.formatNumber(getPercent());
    }
}
