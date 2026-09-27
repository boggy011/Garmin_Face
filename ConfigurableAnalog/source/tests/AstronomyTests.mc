import Toybox.Lang;
import Toybox.Test;
import Toybox.Weather;

//! Reference values for Belgrade (44.8 N, 20.5 E): timeanddate.com, cross checked with PyEphem.
//! Columns: UTC seconds of local midnight, moonrise UTC, moonset UTC, illuminated fraction at local noon, phase.
function belgradeMoonCases() as Array<Array<Number or Float>> {
    return [
        [1768431600, 1768449157, 1768478198, 0.107, Astronomy.PHASE_WANING_CRESCENT],
        [1775772000, 1775781791, 1775812302, 0.481, Astronomy.PHASE_LAST_QUARTER],
        [1790460000, 1790526498, 1790486215, 0.993, Astronomy.PHASE_FULL]
    ] as Array<Array<Number or Float>>;
}

function absNumber(value as Number) as Number {
    return (value < 0) ? -value : value;
}

(:test)
function testAstronomyMoonRiseSetBelgrade(logger as Logger) as Boolean {
    var cases = belgradeMoonCases();
    for (var i = 0; i < cases.size(); i++) {
        var c = cases[i];
        var midnight = c[0] as Number;
        var riseSet = Astronomy.moonRiseSet(midnight, 44.8d, 20.5d);
        var rise = riseSet.rise;
        var set = riseSet.set;
        Test.assertMessage(rise != null, "case " + i + ": moonrise found");
        Test.assertMessage(set != null, "case " + i + ": moonset found");
        var riseError = absNumber((rise as Number) - (c[1] as Number));
        var setError = absNumber((set as Number) - (c[2] as Number));
        logger.debug("case " + i + ": rise error " + riseError + " s, set error " + setError + " s");
        Test.assertMessage(riseError <= 600, "case " + i + ": moonrise within 10 minutes");
        Test.assertMessage(setError <= 600, "case " + i + ": moonset within 10 minutes");
    }
    return true;
}

(:test)
function testAstronomyMoonPhaseBelgrade(logger as Logger) as Boolean {
    var cases = belgradeMoonCases();
    for (var i = 0; i < cases.size(); i++) {
        var c = cases[i];
        var noon = (c[0] as Number) + 43200;
        var phase = Astronomy.moonPhase(noon);
        var expected = c[3] as Float;
        var error = (phase.illumination - expected).abs();
        logger.debug("case " + i + ": illumination " + phase.illumination.format("%.3f") + " expected " + expected.format("%.3f") + ", age " + phase.age.format("%.3f"));
        Test.assertMessage(error < 0.03, "case " + i + ": illuminated fraction within 3 percent");
        Test.assertEqualMessage(phase.phase, c[4] as Number, "case " + i + ": phase name");
        Test.assertEqualMessage(phase.waxing, phase.age < 0.5d, "case " + i + ": waxing flag follows age");
    }
    return true;
}

(:test)
function testWeatherConditionMappingCoversEveryConstant(logger as Logger) as Boolean {
    var all = [
        Weather.CONDITION_CHANCE_OF_RAIN_SNOW, Weather.CONDITION_CHANCE_OF_SHOWERS, Weather.CONDITION_CHANCE_OF_SNOW,
        Weather.CONDITION_CHANCE_OF_THUNDERSTORMS, Weather.CONDITION_CLEAR, Weather.CONDITION_CLOUDY,
        Weather.CONDITION_CLOUDY_CHANCE_OF_RAIN, Weather.CONDITION_CLOUDY_CHANCE_OF_RAIN_SNOW, Weather.CONDITION_CLOUDY_CHANCE_OF_SNOW,
        Weather.CONDITION_DRIZZLE, Weather.CONDITION_DUST, Weather.CONDITION_FAIR, Weather.CONDITION_FLURRIES, Weather.CONDITION_FOG,
        Weather.CONDITION_FREEZING_RAIN, Weather.CONDITION_HAIL, Weather.CONDITION_HAZE, Weather.CONDITION_HAZY, Weather.CONDITION_HEAVY_RAIN,
        Weather.CONDITION_HEAVY_RAIN_SNOW, Weather.CONDITION_HEAVY_SHOWERS, Weather.CONDITION_HEAVY_SNOW, Weather.CONDITION_HURRICANE,
        Weather.CONDITION_ICE, Weather.CONDITION_ICE_SNOW, Weather.CONDITION_LIGHT_RAIN, Weather.CONDITION_LIGHT_RAIN_SNOW,
        Weather.CONDITION_LIGHT_SHOWERS, Weather.CONDITION_LIGHT_SNOW, Weather.CONDITION_MIST, Weather.CONDITION_MOSTLY_CLEAR,
        Weather.CONDITION_MOSTLY_CLOUDY, Weather.CONDITION_PARTLY_CLEAR, Weather.CONDITION_PARTLY_CLOUDY, Weather.CONDITION_RAIN,
        Weather.CONDITION_RAIN_SNOW, Weather.CONDITION_SAND, Weather.CONDITION_SANDSTORM, Weather.CONDITION_SCATTERED_SHOWERS,
        Weather.CONDITION_SCATTERED_THUNDERSTORMS, Weather.CONDITION_SHOWERS, Weather.CONDITION_SLEET, Weather.CONDITION_SMOKE,
        Weather.CONDITION_SNOW, Weather.CONDITION_SQUALL, Weather.CONDITION_THIN_CLOUDS, Weather.CONDITION_THUNDERSTORMS,
        Weather.CONDITION_TORNADO, Weather.CONDITION_TROPICAL_STORM, Weather.CONDITION_UNKNOWN, Weather.CONDITION_UNKNOWN_PRECIPITATION,
        Weather.CONDITION_VOLCANIC_ASH, Weather.CONDITION_WINDY, Weather.CONDITION_WINTRY_MIX
    ] as Array<Number>;
    Test.assertEqualMessage(all.size(), 54, "the SDK 9.2.0 Weather module defines 54 condition constants");
    for (var i = 0; i < all.size(); i++) {
        var category = WeatherConditions.explicitCategory(all[i]);
        Test.assertMessage(category != null, "condition constant " + all[i] + " is mapped");
        Test.assertMessage((category as Number) >= 0 && (category as Number) < WeatherConditions.CATEGORY_COUNT, "category in range");
    }
    Test.assertEqualMessage(WeatherConditions.categoryFor(null), WeatherConditions.CLOUDY, "null maps to cloudy");
    Test.assertEqualMessage(WeatherConditions.categoryFor(9999), WeatherConditions.CLOUDY, "unknown value maps to cloudy");
    Test.assertEqualMessage(WeatherConditions.categoryFor(Weather.CONDITION_THUNDERSTORMS), WeatherConditions.THUNDER, "thunderstorms map to thunder");
    return true;
}
