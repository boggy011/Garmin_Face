import Toybox.Complications;
import Toybox.Lang;

//! Static map from DataSourceId to a DataSource instance, plus the reverse map
//! from system complication type to DataSourceId for the on-device editor.
module DataSourceRegistry {
    var _byId as Dictionary<String, DataSource> = {} as Dictionary<String, DataSource>;
    var _byType as Dictionary<Number, String> = {} as Dictionary<Number, String>;
    var _empty as DataSource?;

    //! Register every source. Idempotent. Keep in sync with tools/sources.yaml.
    function init() as Void {
        if (_empty != null) {
            return;
        }
        var empty = new EmptySource();
        _empty = empty;
        register(empty);
        register(new BatterySource());
        register(new StepsSource());
        register(new HeartRateSource());
        register(new DateSource());
        register(new DayOfWeekSource());
        register(new BodyBatterySource());
        register(new StressSource());
        register(new CaloriesSource());
        register(new DistanceSource());
        register(new FloorsClimbedSource());
        register(new NotificationsSource());
        register(new WeatherSource());
        register(new SunriseSource());
        register(new SunsetSource());
        register(new SecondTimeZoneSource());
        register(new AltitudeSource());
        register(new SolarIntensitySource());
        register(new ActiveMinutesSource());
        register(new NextEventSource());
    }

    function register(source as DataSource) as Void {
        _byId[source.getId()] = source;
        var type = source.getComplicationType();
        if (type != null) {
            _byType[type as Number] = source.getId();
        }
    }

    //! Source for an id, falling back to Empty for unknown ids.
    function get(id as String) as DataSource {
        init();
        var source = _byId[id];
        if (source != null) {
            return source;
        }
        return _empty as DataSource;
    }

    function isRegistered(id as String) as Boolean {
        init();
        return _byId.hasKey(id);
    }

    //! DataSourceId for a system complication type, or null when nothing maps to it.
    function idForComplicationType(type as Complications.Type) as String? {
        init();
        return _byType[type as Number];
    }
}
