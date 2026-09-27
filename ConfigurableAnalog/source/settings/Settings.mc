import Toybox.Application;
import Toybox.Application.WatchFaceConfig;
import Toybox.Complications;
import Toybox.Lang;

//! Typed, validated accessors over phone settings (Application.Properties) merged with
//! the on-device watch face editor configuration (WatchFaceConfig).
//!
//! Merge rule: last writer wins. A phone settings change marks "phone" as the source of
//! truth, a committed on-device edit marks "device" and is also written back to
//! Properties so the phone shows the same values. In editor mode the device config is
//! always shown live.
module Settings {
    const SOURCE_KEY = "configSource";
    const SOURCE_PHONE = "phone";
    const SOURCE_DEVICE = "device";

    var _skinId as String = SettingsKeys.DEFAULT_SKIN_ID;
    var _pageCount as Number = SettingsKeys.DEFAULT_PAGE_COUNT;
    var _slots as Array<Array<String>> = [] as Array<Array<String>>;
    var _secondsHandMode as String = SettingsKeys.DEFAULT_SECONDS_HAND_MODE;
    var _secondTimeZoneOffsetMinutes as Number = SettingsKeys.SECOND_TIME_ZONE_OFFSET_MINUTES_DEFAULT;
    var _pageTypes as Array<Number> = [] as Array<Number>;
    var _pressureUnit as String = SettingsKeys.PRESSURE_UNIT_DEFAULT;
    var _healthArcTop as String = SettingsKeys.HEALTH_ARC_TOP_DEFAULT;
    var _healthArcBottom as String = SettingsKeys.HEALTH_ARC_BOTTOM_DEFAULT;
    var _effectsIntensity as String = SettingsKeys.EFFECTS_INTENSITY_DEFAULT;
    var _showSunTimes as Boolean = SettingsKeys.SHOW_SUN_TIMES_DEFAULT;
    var _showMoonPhaseLabel as Boolean = SettingsKeys.SHOW_MOON_PHASE_LABEL_DEFAULT;
    var _effectsEnabled as Boolean = SettingsKeys.EFFECTS_ENABLED_DEFAULT;
    var _effectsOnWristRaiseOnly as Boolean = SettingsKeys.EFFECTS_ON_WRIST_RAISE_ONLY_DEFAULT;
    var _weatherRefreshMinutes as Number = SettingsKeys.WEATHER_REFRESH_MINUTES_DEFAULT;
    var _accentOverride as Number?;
    var _dataColorOverride as Number?;
    var _configId as WatchFaceConfig.Id?;
    var _editMode as Boolean = false;
    var _preferDevice as Boolean = false;

    //! Call once from AppBase.onStart.
    function start(configId as WatchFaceConfig.Id?, editMode as Boolean) as Void {
        _configId = configId;
        _editMode = editMode;
        var source = Storage.getValue(SOURCE_KEY);
        _preferDevice = (source instanceof String) && source.equals(SOURCE_DEVICE);
        reload();
    }

    //! Re-read everything. Cheap enough to call from onSettingsChanged and editor callbacks.
    function reload() as Void {
        _skinId = coerceChoice(read(SettingsKeys.SKIN_ID), SettingsKeys.SKIN_IDS, SettingsKeys.DEFAULT_SKIN_ID);
        _pageCount = coerceNumber(read(SettingsKeys.PAGE_COUNT), 1, SettingsKeys.MAX_PAGES, SettingsKeys.DEFAULT_PAGE_COUNT);
        _secondsHandMode = coerceChoice(read(SettingsKeys.SECONDS_HAND_MODE), SettingsKeys.SECONDS_HAND_MODES, SettingsKeys.DEFAULT_SECONDS_HAND_MODE);
        _secondTimeZoneOffsetMinutes = coerceNumber(
            read(SettingsKeys.SECOND_TIME_ZONE_OFFSET_MINUTES),
            SettingsKeys.SECOND_TIME_ZONE_OFFSET_MINUTES_MIN,
            SettingsKeys.SECOND_TIME_ZONE_OFFSET_MINUTES_MAX,
            SettingsKeys.SECOND_TIME_ZONE_OFFSET_MINUTES_DEFAULT
        );
        var slots = [] as Array<Array<String>>;
        for (var p = 0; p < SettingsKeys.MAX_PAGES; p++) {
            var row = [] as Array<String>;
            for (var s = 0; s < SettingsKeys.SLOTS_PER_PAGE; s++) {
                row.add(coerceSourceId(read(SettingsKeys.SLOT_KEYS[p][s]), SettingsKeys.DEFAULT_SLOTS[p][s]));
            }
            slots.add(row);
        }
        _slots = slots;
        var types = [] as Array<Number>;
        for (var p = 0; p < SettingsKeys.MAX_PAGES; p++) {
            types.add(PageTypes.fromId(coerceChoice(read(SettingsKeys.PAGE_TYPE_KEYS[p]), SettingsKeys.PAGE_TYPE_IDS, SettingsKeys.DEFAULT_PAGE_TYPES[p])));
        }
        _pageTypes = types;
        _pressureUnit = coerceChoice(read(SettingsKeys.PRESSURE_UNIT), SettingsKeys.PRESSURE_UNIT_OPTIONS, SettingsKeys.PRESSURE_UNIT_DEFAULT);
        _healthArcTop = coerceChoice(read(SettingsKeys.HEALTH_ARC_TOP), SettingsKeys.HEALTH_ARC_TOP_OPTIONS, SettingsKeys.HEALTH_ARC_TOP_DEFAULT);
        _healthArcBottom = coerceChoice(read(SettingsKeys.HEALTH_ARC_BOTTOM), SettingsKeys.HEALTH_ARC_BOTTOM_OPTIONS, SettingsKeys.HEALTH_ARC_BOTTOM_DEFAULT);
        _effectsIntensity = coerceChoice(read(SettingsKeys.EFFECTS_INTENSITY), SettingsKeys.EFFECTS_INTENSITY_OPTIONS, SettingsKeys.EFFECTS_INTENSITY_DEFAULT);
        _showSunTimes = coerceBoolean(read(SettingsKeys.SHOW_SUN_TIMES), SettingsKeys.SHOW_SUN_TIMES_DEFAULT);
        _showMoonPhaseLabel = coerceBoolean(read(SettingsKeys.SHOW_MOON_PHASE_LABEL), SettingsKeys.SHOW_MOON_PHASE_LABEL_DEFAULT);
        _effectsEnabled = coerceBoolean(read(SettingsKeys.EFFECTS_ENABLED), SettingsKeys.EFFECTS_ENABLED_DEFAULT);
        _effectsOnWristRaiseOnly = coerceBoolean(read(SettingsKeys.EFFECTS_ON_WRIST_RAISE_ONLY), SettingsKeys.EFFECTS_ON_WRIST_RAISE_ONLY_DEFAULT);
        _weatherRefreshMinutes = coerceNumber(
            read(SettingsKeys.WEATHER_REFRESH_MINUTES),
            SettingsKeys.WEATHER_REFRESH_MINUTES_MIN,
            SettingsKeys.WEATHER_REFRESH_MINUTES_MAX,
            SettingsKeys.WEATHER_REFRESH_MINUTES_DEFAULT
        );
        _accentOverride = null;
        _dataColorOverride = null;
        if (_editMode || _preferDevice) {
            applyDeviceConfig();
        }
    }

    //! Overlay the on-device editor configuration where it defines values.
    function applyDeviceConfig() as Void {
        if (!(Application has :WatchFaceConfig)) {
            return;
        }
        var config = null as WatchFaceConfig.Settings?;
        try {
            config = WatchFaceConfig.getSettings(_configId);
        } catch (e) {
            config = null;
        }
        if (config == null) {
            return;
        }
        var styleId = config.styleId;
        if (styleId != null) {
            var skinId = SkinRegistry.skinIdForStyle(styleId);
            if (skinId != null) {
                _skinId = skinId;
            }
        }
        var accent = config.accentColor;
        if (accent != null && accent.color != null) {
            _accentOverride = accent.color as Number;
        }
        var dataColor = config.complicationColor;
        if (dataColor != null && dataColor.color != null) {
            _dataColorOverride = dataColor.color as Number;
        }
        var complications = config.complicationSettings;
        if (complications == null) {
            return;
        }
        for (var i = 0; i < complications.size(); i++) {
            applyComplication(complications[i]);
        }
    }

    function applyComplication(ref as WatchFaceConfig.ComplicationRef) as Void {
        var uid = ref.uniqueIdentifier;
        if (uid == null) {
            return;
        }
        var page = SettingsKeys.pageForUid(uid);
        var slot = SettingsKeys.slotForUid(uid);
        if (page < 0 || page >= SettingsKeys.MAX_PAGES || slot < 0 || slot >= SettingsKeys.SLOTS_PER_PAGE) {
            return;
        }
        var complicationId = ref.complicationId;
        if (complicationId == null) {
            _slots[page][slot] = SettingsKeys.EMPTY_SOURCE_ID;
            return;
        }
        var sourceId = DataSourceRegistry.idForComplicationType(complicationId.getType());
        if (sourceId != null) {
            _slots[page][slot] = sourceId;
        }
    }

    //! Phone settings changed: phone becomes the source of truth.
    function onPhoneSettingsChanged() as Void {
        _preferDevice = false;
        Storage.setValue(SOURCE_KEY, SOURCE_PHONE);
        reload();
    }

    //! On-device editor changed something. Committed edits become the source of truth
    //! and are mirrored into Properties.
    function onDeviceConfigEdited(configId as WatchFaceConfig.Id?, committed as Boolean) as Void {
        if (configId != null) {
            _configId = configId;
        }
        if (committed) {
            _preferDevice = true;
            Storage.setValue(SOURCE_KEY, SOURCE_DEVICE);
        }
        reload();
        if (committed) {
            writeBackToProperties();
        }
    }

    function writeBackToProperties() as Void {
        try {
            Properties.setValue(SettingsKeys.SKIN_ID, SettingsKeys.SKIN_IDS.indexOf(_skinId));
            for (var p = 0; p < SettingsKeys.MAX_PAGES; p++) {
                for (var s = 0; s < SettingsKeys.SLOTS_PER_PAGE; s++) {
                    Properties.setValue(SettingsKeys.SLOT_KEYS[p][s], SettingsKeys.SOURCE_IDS.indexOf(_slots[p][s]));
                }
            }
        } catch (e) {
            // Properties may be unavailable on some firmware, the in-memory state is still correct.
        }
    }

    function getSkinId() as String {
        return _skinId;
    }

    function getPageCount() as Number {
        return _pageCount;
    }

    //! Source ids of a 0-based page.
    function getPageSlots(page as Number) as Array<String> {
        return _slots[page];
    }

    function getSlot(page as Number, slot as Number) as String {
        return _slots[page][slot];
    }

    //! PageTypes value of a 0-based page.
    function getPageType(page as Number) as Number {
        return _pageTypes[page];
    }

    //! "hPa", "mmHg" or "inHg".
    function getPressureUnit() as String {
        return _pressureUnit;
    }

    //! Health metric id shown on the top arc of the health page.
    function getHealthArcTop() as String {
        return _healthArcTop;
    }

    //! Health metric id shown on the bottom arc of the health page.
    function getHealthArcBottom() as String {
        return _healthArcBottom;
    }

    //! "low", "normal" or "high".
    function getEffectsIntensity() as String {
        return _effectsIntensity;
    }

    function getShowSunTimes() as Boolean {
        return _showSunTimes;
    }

    function getShowMoonPhaseLabel() as Boolean {
        return _showMoonPhaseLabel;
    }

    function getEffectsEnabled() as Boolean {
        return _effectsEnabled;
    }

    function getEffectsOnWristRaiseOnly() as Boolean {
        return _effectsOnWristRaiseOnly;
    }

    function getWeatherRefreshMinutes() as Number {
        return _weatherRefreshMinutes;
    }

    //! "skin", "always", "awakeOnly" or "never".
    function getSecondsHandMode() as String {
        return _secondsHandMode;
    }

    function getSecondTimeZoneOffsetMinutes() as Number {
        return _secondTimeZoneOffsetMinutes;
    }

    function getAccentOverride() as Number? {
        return _accentOverride;
    }

    function getDataColorOverride() as Number? {
        return _dataColorOverride;
    }

    //! Property read that never throws.
    function read(key as String) as Object? {
        try {
            return Properties.getValue(key);
        } catch (e) {
            return null;
        }
    }

    //! A choice id from an ordered option list. Accepts the 0-based index (how phone settings
    //! store list values) or the id string itself. Anything else, including out of range
    //! indices, falls back.
    function coerceChoice(value as Object?, options as Array<String>, fallback as String) as String {
        if (value instanceof String && options.indexOf(value) >= 0) {
            return value;
        }
        var index = null as Number?;
        if (value instanceof Number) {
            index = value;
        } else if (value instanceof Float) {
            index = value.toNumber();
        }
        if (index != null && index >= 0 && index < options.size()) {
            return options[index];
        }
        return fallback;
    }

    //! An integer clamped to [min, max]. Floats are truncated, numeric strings parsed, anything else falls back.
    function coerceNumber(value as Object?, min as Number, max as Number, fallback as Number) as Number {
        var number = null as Number?;
        if (value instanceof Number) {
            number = value;
        } else if (value instanceof Float) {
            number = value.toNumber();
        } else if (value instanceof String) {
            number = value.toNumber();
        }
        if (number == null) {
            return fallback;
        }
        if (number < min) {
            return min;
        }
        if (number > max) {
            return max;
        }
        return number;
    }

    //! A boolean, also accepting 0/1 and "true"/"false", else the fallback.
    function coerceBoolean(value as Object?, fallback as Boolean) as Boolean {
        if (value instanceof Boolean) {
            return value;
        }
        if (value instanceof Number) {
            return value != 0;
        }
        if (value instanceof String) {
            if (value.equals("true")) {
                return true;
            }
            if (value.equals("false")) {
                return false;
            }
        }
        return fallback;
    }

    //! A registered DataSourceId (by index or id), else the fallback.
    function coerceSourceId(value as Object?, fallback as String) as String {
        var id = coerceChoice(value, SettingsKeys.SOURCE_IDS, fallback);
        if (DataSourceRegistry.isRegistered(id)) {
            return id;
        }
        return fallback;
    }
}
