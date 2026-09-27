import Toybox.Lang;
import Toybox.System;

//! Display technology hints. There is no direct MIP or AMOLED query, burn in protection
//! is only required on emissive displays, so it stands in for AMOLED.
module Display {
    function isAmoled() as Boolean {
        var settings = System.getDeviceSettings();
        if (settings has :requiresBurnInProtection) {
            return settings.requiresBurnInProtection;
        }
        return false;
    }
}
