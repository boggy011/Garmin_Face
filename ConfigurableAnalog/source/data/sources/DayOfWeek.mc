import Toybox.Complications;
import Toybox.Lang;
import Toybox.Time;
import Toybox.Time.Gregorian;

class DayOfWeekSource extends DataSource {
    function initialize() {
        DataSource.initialize(Rez.Strings.src_DayOfWeek, Rez.Strings.srcs_DayOfWeek, Rez.Drawables.icon_dayofweek);
    }

    function getId() as String {
        return "DayOfWeek";
    }

    function getComplicationType() as Complications.Type? {
        return Complications.COMPLICATION_TYPE_WEEKDAY_MONTHDAY;
    }

    function getValue() as String {
        var info = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
        return info.day_of_week.toString().toUpper();
    }
}
