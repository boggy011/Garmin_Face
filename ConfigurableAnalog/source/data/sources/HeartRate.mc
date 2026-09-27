import Toybox.Complications;
import Toybox.Lang;
import Toybox.Activity;
import Toybox.ActivityMonitor;

class HeartRateSource extends DataSource {
    function initialize() {
        DataSource.initialize(Rez.Strings.src_HeartRate, Rez.Drawables.icon_heartrate);
    }

    function getId() as String {
        return "HeartRate";
    }

    function getComplicationType() as Complications.Type? {
        return Complications.COMPLICATION_TYPE_HEART_RATE;
    }

    function isSupported() as Boolean {
        return Activity has :getActivityInfo;
    }

    function getValue() as String {
        var rate = Activity.getActivityInfo().currentHeartRate;
        if (rate == null && (ActivityMonitor has :getHeartRateHistory)) {
            var sample = ActivityMonitor.getHeartRateHistory(1, true).next();
            if (sample != null && sample.heartRate != ActivityMonitor.INVALID_HR_SAMPLE) {
                rate = sample.heartRate;
            }
        }
        return Sources.formatNumber(rate);
    }
}
