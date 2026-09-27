import Toybox.Activity;
import Toybox.Lang;
import Toybox.Position;
import Toybox.SensorHistory;
import Toybox.System;
import Toybox.Time;
import Toybox.WatchUi;
import Toybox.Weather;

//! Weather, sun and moon data for the weather page. Refreshed at most every
//! weatherRefreshMinutes and rendered from this cache. Values are preformatted here so
//! drawing allocates nothing. Never called from onPartialUpdate.
module WeatherCache {
    var category as Number = WeatherConditions.CLOUDY;
    var temperature as String = Sources.PLACEHOLDER;
    var precipitation as String = Sources.PLACEHOLDER;
    var uv as String = Sources.PLACEHOLDER;
    var pressure as String = Sources.PLACEHOLDER;
    var sunrise as Number?;
    var sunset as Number?;
    var sunriseLabel as String = Sources.PLACEHOLDER;
    var sunsetLabel as String = Sources.PLACEHOLDER;
    var moonRise as Number?;
    var moonSet as Number?;
    var moonIllumination as Float = 0.0;
    var moonWaxing as Boolean = true;
    var moonPhase as Number = Astronomy.PHASE_NEW;
    var moonPhaseLabel as String = "";
    var windBearing as Number?;
    var lastRefresh as Number = 0;

    var _phaseNames as Array<ResourceId> = [
        Rez.Strings.moon_phase_0, Rez.Strings.moon_phase_1, Rez.Strings.moon_phase_2, Rez.Strings.moon_phase_3,
        Rez.Strings.moon_phase_4, Rez.Strings.moon_phase_5, Rez.Strings.moon_phase_6, Rez.Strings.moon_phase_7
    ] as Array<ResourceId>;

    //! Refresh when the configured interval has passed. Returns true when refreshed.
    function refreshIfDue(now as Number) as Boolean {
        var interval = Settings.getWeatherRefreshMinutes() * 60;
        if (lastRefresh != 0 && now - lastRefresh < interval) {
            return false;
        }
        refresh(now);
        return true;
    }

    function refresh(now as Number) as Void {
        lastRefresh = now;
        var conditions = null as CurrentConditions?;
        if ((Toybox has :Weather) && (Weather has :getCurrentConditions)) {
            conditions = Weather.getCurrentConditions();
        }
        category = WeatherConditions.categoryFor((conditions != null) ? conditions.condition : null);
        temperature = formatTemperature((conditions != null) ? conditions.temperature : null);
        precipitation = formatPercent((conditions != null) ? conditions.precipitationChance : null);
        uv = formatUv((conditions != null) ? conditions.uvIndex : null);
        windBearing = (conditions != null) ? conditions.windBearing : null;
        pressure = formatPressure(readPressurePa());
        var location = locate(conditions);
        refreshSun(location);
        refreshMoon(location, now);
    }

    //! Observation position, else the positioning subsystem, else the last activity fix.
    function locate(conditions as CurrentConditions?) as Position.Location? {
        if (conditions != null) {
            var observed = conditions.observationLocationPosition;
            if (observed != null) {
                return observed;
            }
        }
        if ((Toybox has :Position) && (Position has :getInfo)) {
            var fix = Position.getInfo().position;
            if (fix != null) {
                return fix;
            }
        }
        return Activity.getActivityInfo().currentLocation;
    }

    function refreshSun(location as Position.Location?) as Void {
        sunrise = null;
        sunset = null;
        sunriseLabel = Sources.PLACEHOLDER;
        sunsetLabel = Sources.PLACEHOLDER;
        if (location == null) {
            return;
        }
        if (!(Toybox has :Weather) || !(Weather has :getSunrise)) {
            return;
        }
        var today = Time.now();
        var rise = Weather.getSunrise(location, today);
        var set = Weather.getSunset(location, today);
        if (rise != null) {
            sunrise = rise.value();
            sunriseLabel = Sources.formatMoment(rise);
        }
        if (set != null) {
            sunset = set.value();
            sunsetLabel = Sources.formatMoment(set);
        }
    }

    function refreshMoon(location as Position.Location?, now as Number) as Void {
        var phase = Astronomy.moonPhase(now);
        moonIllumination = phase.illumination.toFloat();
        moonWaxing = phase.waxing;
        moonPhase = phase.phase;
        moonPhaseLabel = WatchUi.loadResource(_phaseNames[phase.phase]) as String;
        moonRise = null;
        moonSet = null;
        if (location == null) {
            return;
        }
        var degrees = location.toDegrees();
        var riseSet = Astronomy.moonRiseSet(localMidnight(now), degrees[0], degrees[1]);
        moonRise = riseSet.rise;
        moonSet = riseSet.set;
    }

    //! UTC seconds of local midnight of the day containing now.
    function localMidnight(now as Number) as Number {
        var offset = System.getClockTime().timeZoneOffset;
        return ((now + offset) / Sources.SECONDS_PER_DAY) * Sources.SECONDS_PER_DAY - offset;
    }

    //! Latest barometric sample in Pascals, else the activity ambient pressure, else null.
    function readPressurePa() as Float? {
        if ((Toybox has :SensorHistory) && (SensorHistory has :getPressureHistory)) {
            var sample = SensorHistory.getPressureHistory({:period => 1, :order => SensorHistory.ORDER_NEWEST_FIRST}).next();
            if (sample != null) {
                var data = sample.data;
                if (data != null) {
                    return data.toFloat();
                }
            }
        }
        return Activity.getActivityInfo().ambientPressure;
    }

    function formatTemperature(celsius as Numeric?) as String {
        if (celsius == null) {
            return Sources.PLACEHOLDER;
        }
        var value = celsius.toFloat();
        if (System.getDeviceSettings().temperatureUnits == System.UNIT_STATUTE) {
            value = value * 9.0 / 5.0 + 32.0;
        }
        return value.format("%d") + "°";
    }

    function formatPercent(value as Number?) as String {
        if (value == null) {
            return Sources.PLACEHOLDER;
        }
        return value.toString() + "%";
    }

    function formatUv(index as Float?) as String {
        if (index == null) {
            return Sources.PLACEHOLDER;
        }
        return index.format("%d");
    }

    function formatPressure(pascals as Float?) as String {
        if (pascals == null) {
            return Sources.PLACEHOLDER;
        }
        var unit = Settings.getPressureUnit();
        if (unit.equals("mmHg")) {
            return (pascals * 0.00750062).format("%d");
        }
        if (unit.equals("inHg")) {
            return (pascals * 0.0002953).format("%.2f");
        }
        return (pascals / 100.0).format("%d");
    }
}
