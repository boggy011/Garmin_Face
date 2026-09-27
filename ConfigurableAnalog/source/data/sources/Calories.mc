import Toybox.Complications;
import Toybox.Lang;
import Toybox.ActivityMonitor;

class CaloriesSource extends DataSource {
    function initialize() {
        DataSource.initialize(Rez.Strings.src_Calories, Rez.Strings.srcs_Calories, Rez.Drawables.icon_calories);
    }

    function getId() as String {
        return "Calories";
    }

    function getComplicationType() as Complications.Type? {
        return Complications.COMPLICATION_TYPE_CALORIES;
    }

    function isSupported() as Boolean {
        return Toybox has :ActivityMonitor;
    }

    function getValue() as String {
        return Sources.formatNumber(ActivityMonitor.getInfo().calories);
    }
}
