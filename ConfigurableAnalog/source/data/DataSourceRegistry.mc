import Toybox.Complications;
import Toybox.Lang;

//! Map from DataSourceId to a DataSource instance. Sources are created on first use, so
//! only the sources that some page slot shows take memory. The reverse map from system
//! complication type to DataSourceId for the on-device editor comes from the generated
//! SettingsKeys.SOURCE_COMPLICATION_TYPES table and needs no instances.
module DataSourceRegistry {
    var _byId as Dictionary<String, DataSource> = {} as Dictionary<String, DataSource>;
    var _empty as DataSource?;

    //! Create the Empty source. Idempotent.
    function init() as Void {
        if (_empty == null) {
            var empty = new EmptySource();
            _empty = empty;
            _byId[empty.getId()] = empty;
        }
    }

    //! Source for an id, created on first use, falling back to Empty for unknown ids.
    function get(id as String) as DataSource {
        init();
        var source = _byId[id];
        if (source == null) {
            source = create(id);
            if (source == null) {
                return _empty as DataSource;
            }
            _byId[id] = source;
        }
        return source;
    }

    function isRegistered(id as String) as Boolean {
        return SettingsKeys.SOURCE_IDS.indexOf(id) >= 0;
    }

    //! DataSourceId for a system complication type, or null when nothing maps to it.
    function idForComplicationType(type as Complications.Type) as String? {
        var wanted = type as Number;
        var types = SettingsKeys.SOURCE_COMPLICATION_TYPES;
        for (var i = 0; i < types.size(); i++) {
            if (types[i] == wanted) {
                return SettingsKeys.SOURCE_IDS[i];
            }
        }
        return null;
    }

    //! New instance for a source id, null for unknown ids. Keep in sync with tools/sources.yaml.
    function create(id as String) as DataSource? {
        if (id.equals("Battery")) {
            return new BatterySource();
        }
        if (id.equals("Steps")) {
            return new StepsSource();
        }
        if (id.equals("HeartRate")) {
            return new HeartRateSource();
        }
        if (id.equals("Date")) {
            return new DateSource();
        }
        if (id.equals("DayOfWeek")) {
            return new DayOfWeekSource();
        }
        if (id.equals("BodyBattery")) {
            return new BodyBatterySource();
        }
        if (id.equals("Stress")) {
            return new StressSource();
        }
        if (id.equals("Calories")) {
            return new CaloriesSource();
        }
        if (id.equals("Distance")) {
            return new DistanceSource();
        }
        if (id.equals("FloorsClimbed")) {
            return new FloorsClimbedSource();
        }
        if (id.equals("Notifications")) {
            return new NotificationsSource();
        }
        if (id.equals("Weather")) {
            return new WeatherSource();
        }
        if (id.equals("Sunrise")) {
            return new SunriseSource();
        }
        if (id.equals("Sunset")) {
            return new SunsetSource();
        }
        if (id.equals("SecondTimeZone")) {
            return new SecondTimeZoneSource();
        }
        if (id.equals("Altitude")) {
            return new AltitudeSource();
        }
        if (id.equals("SolarIntensity")) {
            return new SolarIntensitySource();
        }
        if (id.equals("ActiveMinutes")) {
            return new ActiveMinutesSource();
        }
        if (id.equals("NextEvent")) {
            return new NextEventSource();
        }
        if (id.equals("PulseOx")) {
            return new ComplicationSource("PulseOx", Rez.Strings.src_PulseOx, Rez.Strings.srcs_PulseOx, Rez.Drawables.icon_pulseox, Complications.COMPLICATION_TYPE_PULSE_OX, ComplicationSource.KIND_PERCENT);
        }
        if (id.equals("RespirationRate")) {
            return new ComplicationSource("RespirationRate", Rez.Strings.src_RespirationRate, Rez.Strings.srcs_RespirationRate, Rez.Drawables.icon_respiration, Complications.COMPLICATION_TYPE_RESPIRATION_RATE, ComplicationSource.KIND_PLAIN);
        }
        if (id.equals("RecoveryTime")) {
            return new ComplicationSource("RecoveryTime", Rez.Strings.src_RecoveryTime, Rez.Strings.srcs_RecoveryTime, Rez.Drawables.icon_recovery, Complications.COMPLICATION_TYPE_RECOVERY_TIME, ComplicationSource.KIND_MINUTES_AS_HOURS);
        }
        if (id.equals("SleepScore")) {
            return new ComplicationSource("SleepScore", Rez.Strings.src_SleepScore, Rez.Strings.srcs_SleepScore, Rez.Drawables.icon_sleep, Complications.COMPLICATION_TYPE_SLEEP_SCORE, ComplicationSource.KIND_PLAIN);
        }
        if (id.equals("TrainingStatus")) {
            return new ComplicationSource("TrainingStatus", Rez.Strings.src_TrainingStatus, Rez.Strings.srcs_TrainingStatus, Rez.Drawables.icon_training, Complications.COMPLICATION_TYPE_TRAINING_STATUS, ComplicationSource.KIND_TEXT);
        }
        if (id.equals("Vo2Max")) {
            return new ComplicationSource("Vo2Max", Rez.Strings.src_Vo2Max, Rez.Strings.srcs_Vo2Max, Rez.Drawables.icon_vo2max, Complications.COMPLICATION_TYPE_VO2MAX_RUN, ComplicationSource.KIND_PLAIN);
        }
        if (id.equals("Barometer")) {
            return new ComplicationSource("Barometer", Rez.Strings.src_Barometer, Rez.Strings.srcs_Barometer, Rez.Drawables.icon_barometer, Complications.COMPLICATION_TYPE_SEA_LEVEL_PRESSURE, ComplicationSource.KIND_PASCALS);
        }
        if (id.equals("HighLowTemp")) {
            return new ComplicationSource("HighLowTemp", Rez.Strings.src_HighLowTemp, Rez.Strings.srcs_HighLowTemp, Rez.Drawables.icon_highlow, Complications.COMPLICATION_TYPE_HIGH_LOW_TEMPERATURE, ComplicationSource.KIND_TEXT);
        }
        if (id.equals("Humidity")) {
            return new WeatherFieldSource("Humidity", Rez.Strings.src_Humidity, Rez.Strings.srcs_Humidity, Rez.Drawables.icon_humidity, WeatherFieldSource.KIND_HUMIDITY);
        }
        if (id.equals("Wind")) {
            return new WeatherFieldSource("Wind", Rez.Strings.src_Wind, Rez.Strings.srcs_Wind, Rez.Drawables.icon_wind, WeatherFieldSource.KIND_WIND);
        }
        if (id.equals("RainChance")) {
            return new WeatherFieldSource("RainChance", Rez.Strings.src_RainChance, Rez.Strings.srcs_RainChance, Rez.Drawables.icon_rainchance, WeatherFieldSource.KIND_RAIN);
        }
        if (id.equals("UvIndex")) {
            return new WeatherFieldSource("UvIndex", Rez.Strings.src_UvIndex, Rez.Strings.srcs_UvIndex, Rez.Drawables.icon_uvindex, WeatherFieldSource.KIND_UV);
        }
        if (id.equals("FeelsLike")) {
            return new WeatherFieldSource("FeelsLike", Rez.Strings.src_FeelsLike, Rez.Strings.srcs_FeelsLike, Rez.Drawables.icon_feelslike, WeatherFieldSource.KIND_FEELS);
        }
        if (id.equals("BatteryDays")) {
            return new DeviceFieldSource("BatteryDays", Rez.Strings.src_BatteryDays, Rez.Strings.srcs_BatteryDays, Rez.Drawables.icon_batterydays, DeviceFieldSource.KIND_BATTERY_DAYS);
        }
        if (id.equals("StepGoal")) {
            return new DeviceFieldSource("StepGoal", Rez.Strings.src_StepGoal, Rez.Strings.srcs_StepGoal, Rez.Drawables.icon_stepgoal, DeviceFieldSource.KIND_STEP_GOAL);
        }
        return null;
    }
}
