import Toybox.Complications;
import Toybox.Lang;
import Toybox.SensorHistory;

class StressSource extends DataSource {
    function initialize() {
        DataSource.initialize(Rez.Strings.src_Stress, Rez.Drawables.icon_stress);
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

    function getValue() as String {
        if (!isSupported()) {
            return Sources.PLACEHOLDER;
        }
        var sample = SensorHistory.getStressHistory({:period => 1, :order => SensorHistory.ORDER_NEWEST_FIRST}).next();
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
