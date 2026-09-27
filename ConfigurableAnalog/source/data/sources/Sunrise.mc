import Toybox.Complications;
import Toybox.Lang;

class SunriseSource extends DataSource {
    function initialize() {
        DataSource.initialize(Rez.Strings.src_Sunrise, Rez.Drawables.icon_sunrise);
    }

    function getId() as String {
        return "Sunrise";
    }

    function getComplicationType() as Complications.Type? {
        return Complications.COMPLICATION_TYPE_SUNRISE;
    }

    function isSupported() as Boolean {
        return (Toybox has :Weather) && (Weather has :getSunrise);
    }

    function getValue() as String {
        return Sources.formatSunEvent(true);
    }
}
