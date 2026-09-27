import Toybox.Complications;
import Toybox.Lang;
import Toybox.Time;
import Toybox.Time.Gregorian;

class DateSource extends DataSource {
    function initialize() {
        DataSource.initialize(Rez.Strings.src_Date, Rez.Drawables.icon_date);
    }

    function getId() as String {
        return "Date";
    }

    function getComplicationType() as Complications.Type? {
        return Complications.COMPLICATION_TYPE_DATE;
    }

    function getValue() as String {
        var info = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
        return info.day.toString() + " " + info.month.toString();
    }
}
