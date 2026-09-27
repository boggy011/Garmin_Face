import Toybox.Complications;
import Toybox.Lang;

class SunsetSource extends DataSource {
    function initialize() {
        DataSource.initialize(Rez.Strings.src_Sunset, Rez.Strings.srcs_Sunset, Rez.Drawables.icon_sunset);
    }

    function getId() as String {
        return "Sunset";
    }

    function getComplicationType() as Complications.Type? {
        return Complications.COMPLICATION_TYPE_SUNSET;
    }

    function isSupported() as Boolean {
        return (Toybox has :Weather) && (Weather has :getSunset);
    }

    function getValue() as String {
        return Sources.formatSunEvent(false);
    }
}
