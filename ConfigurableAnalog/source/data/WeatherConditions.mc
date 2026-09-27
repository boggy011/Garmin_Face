import Toybox.Lang;
import Toybox.Weather;

//! Maps every Toybox.Weather.CONDITION_* constant to one of ten icon categories.
module WeatherConditions {
    enum {
        CLEAR = 0,
        PARTLY_CLOUDY = 1,
        CLOUDY = 2,
        RAIN = 3,
        HEAVY_RAIN = 4,
        SNOW = 5,
        SLEET = 6,
        THUNDER = 7,
        FOG = 8,
        WIND = 9
    }

    const CATEGORY_COUNT = 10;

    //! Category for a condition, CLOUDY for null or anything unmapped.
    function categoryFor(condition as Number?) as Number {
        if (condition == null) {
            return CLOUDY;
        }
        var mapped = explicitCategory(condition);
        return (mapped != null) ? mapped : CLOUDY;
    }

    //! Explicit mapping, null when the constant is not covered. Tests assert full coverage.
    function explicitCategory(condition as Number) as Number? {
        switch (condition) {
            case Weather.CONDITION_CLEAR:
            case Weather.CONDITION_FAIR:
            case Weather.CONDITION_MOSTLY_CLEAR:
                return CLEAR;
            case Weather.CONDITION_PARTLY_CLOUDY:
            case Weather.CONDITION_PARTLY_CLEAR:
            case Weather.CONDITION_THIN_CLOUDS:
                return PARTLY_CLOUDY;
            case Weather.CONDITION_CLOUDY:
            case Weather.CONDITION_MOSTLY_CLOUDY:
            case Weather.CONDITION_UNKNOWN:
                return CLOUDY;
            case Weather.CONDITION_RAIN:
            case Weather.CONDITION_LIGHT_RAIN:
            case Weather.CONDITION_SHOWERS:
            case Weather.CONDITION_LIGHT_SHOWERS:
            case Weather.CONDITION_SCATTERED_SHOWERS:
            case Weather.CONDITION_CHANCE_OF_SHOWERS:
            case Weather.CONDITION_CLOUDY_CHANCE_OF_RAIN:
            case Weather.CONDITION_DRIZZLE:
            case Weather.CONDITION_UNKNOWN_PRECIPITATION:
                return RAIN;
            case Weather.CONDITION_HEAVY_RAIN:
            case Weather.CONDITION_HEAVY_SHOWERS:
            case Weather.CONDITION_TROPICAL_STORM:
                return HEAVY_RAIN;
            case Weather.CONDITION_SNOW:
            case Weather.CONDITION_LIGHT_SNOW:
            case Weather.CONDITION_HEAVY_SNOW:
            case Weather.CONDITION_FLURRIES:
            case Weather.CONDITION_CHANCE_OF_SNOW:
            case Weather.CONDITION_CLOUDY_CHANCE_OF_SNOW:
            case Weather.CONDITION_ICE_SNOW:
            case Weather.CONDITION_ICE:
                return SNOW;
            case Weather.CONDITION_SLEET:
            case Weather.CONDITION_RAIN_SNOW:
            case Weather.CONDITION_LIGHT_RAIN_SNOW:
            case Weather.CONDITION_HEAVY_RAIN_SNOW:
            case Weather.CONDITION_CHANCE_OF_RAIN_SNOW:
            case Weather.CONDITION_CLOUDY_CHANCE_OF_RAIN_SNOW:
            case Weather.CONDITION_FREEZING_RAIN:
            case Weather.CONDITION_HAIL:
            case Weather.CONDITION_WINTRY_MIX:
                return SLEET;
            case Weather.CONDITION_THUNDERSTORMS:
            case Weather.CONDITION_SCATTERED_THUNDERSTORMS:
            case Weather.CONDITION_CHANCE_OF_THUNDERSTORMS:
                return THUNDER;
            case Weather.CONDITION_FOG:
            case Weather.CONDITION_MIST:
            case Weather.CONDITION_HAZE:
            case Weather.CONDITION_HAZY:
            case Weather.CONDITION_SMOKE:
            case Weather.CONDITION_DUST:
            case Weather.CONDITION_SAND:
            case Weather.CONDITION_SANDSTORM:
            case Weather.CONDITION_VOLCANIC_ASH:
                return FOG;
            case Weather.CONDITION_WINDY:
            case Weather.CONDITION_SQUALL:
            case Weather.CONDITION_TORNADO:
            case Weather.CONDITION_HURRICANE:
                return WIND;
            default:
                return null;
        }
    }
}
