import Toybox.Complications;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;

class SecondTimeZoneSource extends DataSource {
    function initialize() {
        DataSource.initialize(Rez.Strings.src_SecondTimeZone, Rez.Drawables.icon_secondtimezone);
    }

    function getId() as String {
        return "SecondTimeZone";
    }

    function getValue() as String {
        var offsetMinutes = Settings.getSecondTimeZoneOffsetMinutes();
        var utcSeconds = Time.now().value() - System.getClockTime().timeZoneOffset;
        var daySeconds = (utcSeconds + offsetMinutes * 60) % Sources.SECONDS_PER_DAY;
        if (daySeconds < 0) {
            daySeconds += Sources.SECONDS_PER_DAY;
        }
        return Sources.formatClock(daySeconds / 3600, (daySeconds % 3600) / 60);
    }
}
