import Toybox.Lang;

//! Pure horizon logic for the sun and the moon. All times are Unix seconds. A body is up
//! between its rise and its set; when the set is earlier than the rise the body is up
//! across local midnight (typical for the moon), which is handled by shifting the window.
module SkyState {
    const DAY = 86400;

    //! 0..1 progress between rise and set, or null when the body is below the horizon
    //! or the times are unknown.
    function progress(now as Number, rise as Number?, set as Number?) as Float? {
        if (rise == null || set == null) {
            return null;
        }
        var start = rise;
        var end = set;
        if (set < rise) {
            if (now < set) {
                start = rise - DAY;
            } else {
                end = set + DAY;
            }
        }
        if (now < start || now > end || end <= start) {
            return null;
        }
        return (now - start).toFloat() / (end - start).toFloat();
    }

    function isUp(now as Number, rise as Number?, set as Number?) as Boolean {
        return progress(now, rise, set) != null;
    }
}
