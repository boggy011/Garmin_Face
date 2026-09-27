import Toybox.Complications;
import Toybox.Lang;
import Toybox.ActivityMonitor;

class ActiveMinutesSource extends DataSource {
    function initialize() {
        DataSource.initialize(Rez.Strings.src_ActiveMinutes, Rez.Drawables.icon_activeminutes);
    }

    function getId() as String {
        return "ActiveMinutes";
    }

    function getComplicationType() as Complications.Type? {
        return Complications.COMPLICATION_TYPE_INTENSITY_MINUTES;
    }

    function isSupported() as Boolean {
        return (Toybox has :ActivityMonitor) && (ActivityMonitor.Info has :activeMinutesWeek);
    }

    function getValue() as String {
        var minutes = ActivityMonitor.getInfo().activeMinutesWeek;
        if (minutes == null) {
            return Sources.PLACEHOLDER;
        }
        return minutes.total.toString();
    }
}
