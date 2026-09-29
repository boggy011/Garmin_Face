import Toybox.Complications;
import Toybox.Lang;
import Toybox.Activity;
import Toybox.ActivityMonitor;

class HeartRateSource extends DataSource {
    function initialize() {
        DataSource.initialize(Rez.Strings.src_HeartRate, Rez.Strings.srcs_HeartRate, Rez.Drawables.icon_heartrate);
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
        return Sources.formatNumber(Sources.latestHeartRate());
    }
}
