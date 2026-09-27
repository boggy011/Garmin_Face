import Toybox.Complications;
import Toybox.Lang;

class EmptySource extends DataSource {
    function initialize() {
        DataSource.initialize(Rez.Strings.src_Empty, Rez.Strings.srcs_Empty, null);
    }

    function getId() as String {
        return "Empty";
    }

    function getValue() as String {
        return "";
    }
}
