import Toybox.Complications;
import Toybox.Lang;
import Toybox.ActivityMonitor;

class FloorsClimbedSource extends DataSource {
    function initialize() {
        DataSource.initialize(Rez.Strings.src_FloorsClimbed, Rez.Strings.srcs_FloorsClimbed, Rez.Drawables.icon_floorsclimbed);
    }

    function getId() as String {
        return "FloorsClimbed";
    }

    function getComplicationType() as Complications.Type? {
        return Complications.COMPLICATION_TYPE_FLOORS_CLIMBED;
    }

    function isSupported() as Boolean {
        return (Toybox has :ActivityMonitor) && (ActivityMonitor.Info has :floorsClimbed);
    }

    function getValue() as String {
        return Sources.formatNumber(ActivityMonitor.getInfo().floorsClimbed);
    }
}
