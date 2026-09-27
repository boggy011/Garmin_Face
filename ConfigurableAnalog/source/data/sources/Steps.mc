import Toybox.Complications;
import Toybox.Lang;
import Toybox.ActivityMonitor;

class StepsSource extends DataSource {
    function initialize() {
        DataSource.initialize(Rez.Strings.src_Steps, Rez.Strings.srcs_Steps, Rez.Drawables.icon_steps);
    }

    function getId() as String {
        return "Steps";
    }

    function getComplicationType() as Complications.Type? {
        return Complications.COMPLICATION_TYPE_STEPS;
    }

    function isSupported() as Boolean {
        return Toybox has :ActivityMonitor;
    }

    function getValue() as String {
        return Sources.formatNumber(ActivityMonitor.getInfo().steps);
    }
}
