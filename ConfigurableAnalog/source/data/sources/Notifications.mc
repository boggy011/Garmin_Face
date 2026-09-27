import Toybox.Complications;
import Toybox.Lang;
import Toybox.System;

class NotificationsSource extends DataSource {
    function initialize() {
        DataSource.initialize(Rez.Strings.src_Notifications, Rez.Strings.srcs_Notifications, Rez.Drawables.icon_notifications);
    }

    function getId() as String {
        return "Notifications";
    }

    function getComplicationType() as Complications.Type? {
        return Complications.COMPLICATION_TYPE_NOTIFICATION_COUNT;
    }

    function getValue() as String {
        return System.getDeviceSettings().notificationCount.toString();
    }
}
