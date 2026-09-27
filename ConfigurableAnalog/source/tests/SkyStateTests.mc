import Toybox.Lang;
import Toybox.Test;

//! Belgrade, 2026-09-27 (CEST, local midnight 1790460000 UTC). Sunrise 06:36, sunset 18:38
//! (timeanddate), moonrise 18:28 and moonset 07:16 (PyEphem, see AstronomyTests).
const BELGRADE_MIDNIGHT = 1790460000;
const BELGRADE_SUNRISE = 1790460000 + 6 * 3600 + 36 * 60;
const BELGRADE_SUNSET = 1790460000 + 18 * 3600 + 38 * 60;
const BELGRADE_MOONRISE = 1790526498;
const BELGRADE_MOONSET = 1790486215;

(:test)
function testSkyStateBelgradeMidday(logger as Logger) as Boolean {
    var noon = BELGRADE_MIDNIGHT + 12 * 3600;
    Test.assertMessage(SkyState.isUp(noon, BELGRADE_SUNRISE, BELGRADE_SUNSET), "sun is up at midday");
    var sun = SkyState.progress(noon, BELGRADE_SUNRISE, BELGRADE_SUNSET);
    Test.assertMessage(sun != null && sun > 0.4 && sun < 0.5, "sun is a little before the middle of its arc at noon");
    Test.assertMessage(!SkyState.isUp(noon, BELGRADE_MOONRISE, BELGRADE_MOONSET), "moon set at 07:16 and rises at 18:28, so it is down at midday");
    return true;
}

(:test)
function testSkyStateBelgradeMidnight(logger as Logger) as Boolean {
    var midnight = BELGRADE_MIDNIGHT;
    Test.assertMessage(!SkyState.isUp(midnight, BELGRADE_SUNRISE, BELGRADE_SUNSET), "sun is down at midnight");
    Test.assertMessage(SkyState.isUp(midnight, BELGRADE_MOONRISE, BELGRADE_MOONSET), "moon rose the previous evening and sets at 07:16, so it is up at midnight");
    var moon = SkyState.progress(midnight, BELGRADE_MOONRISE, BELGRADE_MOONSET);
    Test.assertMessage(moon != null && moon > 0.3 && moon < 0.6, "moon is around the middle of its night arc at midnight");
    var evening = BELGRADE_MIDNIGHT + 20 * 3600;
    Test.assertMessage(SkyState.isUp(evening, BELGRADE_MOONRISE, BELGRADE_MOONSET), "moon is up at 20:00 after rising at 18:28");
    Test.assertMessage(!SkyState.isUp(evening, BELGRADE_SUNRISE, BELGRADE_SUNSET), "sun is down at 20:00");
    Test.assertMessage(SkyState.progress(evening, null, BELGRADE_MOONSET) == null, "unknown rise means not drawn");
    return true;
}
