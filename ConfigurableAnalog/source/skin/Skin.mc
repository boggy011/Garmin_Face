import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

//! Constants and typed accessors used to turn a skin JSON dictionary into a Skin.
module SkinDefs {
    const ACCENT_REF = -2;

    enum { NUMERALS_NONE = 0, NUMERALS_QUARTERS = 1, NUMERALS_ALL = 2 }
    enum { SECONDS_ALWAYS = 0, SECONDS_AWAKE_ONLY = 1, SECONDS_NEVER = 2 }
    enum { SHAPE_BATON = 0, SHAPE_DAUPHINE = 1, SHAPE_ARROW = 2, SHAPE_LINE = 3, SHAPE_SKELETON = 4 }

    //! Graphics.COLOR_* by name, or null.
    function namedColor(name as String) as Number? {
        if (name.equals("COLOR_WHITE")) { return Graphics.COLOR_WHITE; }
        if (name.equals("COLOR_LT_GRAY")) { return Graphics.COLOR_LT_GRAY; }
        if (name.equals("COLOR_DK_GRAY")) { return Graphics.COLOR_DK_GRAY; }
        if (name.equals("COLOR_BLACK")) { return Graphics.COLOR_BLACK; }
        if (name.equals("COLOR_RED")) { return Graphics.COLOR_RED; }
        if (name.equals("COLOR_DK_RED")) { return Graphics.COLOR_DK_RED; }
        if (name.equals("COLOR_ORANGE")) { return Graphics.COLOR_ORANGE; }
        if (name.equals("COLOR_YELLOW")) { return Graphics.COLOR_YELLOW; }
        if (name.equals("COLOR_GREEN")) { return Graphics.COLOR_GREEN; }
        if (name.equals("COLOR_DK_GREEN")) { return Graphics.COLOR_DK_GREEN; }
        if (name.equals("COLOR_BLUE")) { return Graphics.COLOR_BLUE; }
        if (name.equals("COLOR_DK_BLUE")) { return Graphics.COLOR_DK_BLUE; }
        if (name.equals("COLOR_PURPLE")) { return Graphics.COLOR_PURPLE; }
        if (name.equals("COLOR_PINK")) { return Graphics.COLOR_PINK; }
        if (name.equals("COLOR_TRANSPARENT")) { return Graphics.COLOR_TRANSPARENT; }
        return null;
    }

    //! Graphics.FONT_* by name, or null.
    function systemFont(name as String) as Graphics.FontDefinition? {
        if (name.equals("FONT_XTINY")) { return Graphics.FONT_XTINY; }
        if (name.equals("FONT_TINY")) { return Graphics.FONT_TINY; }
        if (name.equals("FONT_SMALL")) { return Graphics.FONT_SMALL; }
        if (name.equals("FONT_MEDIUM")) { return Graphics.FONT_MEDIUM; }
        if (name.equals("FONT_LARGE")) { return Graphics.FONT_LARGE; }
        if (name.equals("FONT_NUMBER_MILD")) { return Graphics.FONT_NUMBER_MILD; }
        if (name.equals("FONT_NUMBER_MEDIUM")) { return Graphics.FONT_NUMBER_MEDIUM; }
        if (name.equals("FONT_NUMBER_HOT")) { return Graphics.FONT_NUMBER_HOT; }
        if (name.equals("FONT_NUMBER_THAI_HOT")) { return Graphics.FONT_NUMBER_THAI_HOT; }
        return null;
    }

    //! Named option to its enum value: hand shapes, numeral styles, seconds modes, textures.
    function shape(name as String) as Number? {
        if (name.equals("baton")) { return SHAPE_BATON; }
        if (name.equals("dauphine")) { return SHAPE_DAUPHINE; }
        if (name.equals("arrow")) { return SHAPE_ARROW; }
        if (name.equals("line")) { return SHAPE_LINE; }
        if (name.equals("skeleton")) { return SHAPE_SKELETON; }
        return null;
    }

    function numeralStyle(name as String) as Number? {
        if (name.equals("none")) { return NUMERALS_NONE; }
        if (name.equals("quarters")) { return NUMERALS_QUARTERS; }
        if (name.equals("all")) { return NUMERALS_ALL; }
        return null;
    }

    function secondsMode(name as String) as Number? {
        if (name.equals("always")) { return SECONDS_ALWAYS; }
        if (name.equals("awakeOnly")) { return SECONDS_AWAKE_ONLY; }
        if (name.equals("never")) { return SECONDS_NEVER; }
        return null;
    }

    function texture(name as String) as Number? {
        if (name.equals("none")) { return 0; }
        if (name.equals("sunburst")) { return 1; }
        if (name.equals("concentricRings")) { return 2; }
        if (name.equals("crosshatch")) { return 3; }
        if (name.equals("dotGrid")) { return 4; }
        if (name.equals("topo")) { return 5; }
        return null;
    }

    function shapeOption(d as Dictionary, key as String, fallback as Number) as Number {
        var value = d[key];
        if (value instanceof String) {
            var found = shape(value);
            if (found != null) {
                return found;
            }
        }
        return fallback;
    }

    function numeralStyleOption(d as Dictionary, key as String, fallback as Number) as Number {
        var value = d[key];
        if (value instanceof String) {
            var found = numeralStyle(value);
            if (found != null) {
                return found;
            }
        }
        return fallback;
    }

    function secondsModeOption(d as Dictionary, key as String, fallback as Number) as Number {
        var value = d[key];
        if (value instanceof String) {
            var found = secondsMode(value);
            if (found != null) {
                return found;
            }
        }
        return fallback;
    }

    function textureOption(d as Dictionary, key as String, fallback as Number) as Number {
        var value = d[key];
        if (value instanceof String) {
            var found = texture(value);
            if (found != null) {
                return found;
            }
        }
        return fallback;
    }

    function dict(d as Dictionary, key as String) as Dictionary {
        var value = d[key];
        if (value instanceof Dictionary) {
            return value;
        }
        return {};
    }

    function array(d as Dictionary, key as String) as Array {
        var value = d[key];
        if (value instanceof Array) {
            return value;
        }
        return [];
    }

    function str(d as Dictionary, key as String, fallback as String) as String {
        var value = d[key];
        if (value instanceof String) {
            return value;
        }
        return fallback;
    }

    function num(d as Dictionary, key as String, fallback as Number) as Number {
        var value = d[key];
        if (value instanceof Number) {
            return value;
        }
        if (value instanceof Float) {
            return value.toNumber();
        }
        return fallback;
    }

    function flt(d as Dictionary, key as String, fallback as Float) as Float {
        var value = d[key];
        if (value instanceof Float) {
            return value;
        }
        if (value instanceof Number) {
            return value.toFloat();
        }
        return fallback;
    }

    function bool(d as Dictionary, key as String, fallback as Boolean) as Boolean {
        var value = d[key];
        if (value instanceof Boolean) {
            return value;
        }
        return fallback;
    }

    //! Colour from a Graphics.COLOR_* name, a "0xRRGGBB" string, a number, or "accent".
    function parseColor(value as Object?, fallback as Number) as Number {
        if (value instanceof Number) {
            return value;
        }
        if (value instanceof String) {
            if (value.equals("accent")) {
                return ACCENT_REF;
            }
            var named = namedColor(value);
            if (named != null) {
                return named;
            }
            if (value.find("0x") == 0) {
                var hex = value.substring(2, value.length());
                if (hex != null) {
                    var parsed = hex.toNumberWithBase(16);
                    if (parsed != null) {
                        return parsed;
                    }
                }
            }
        }
        return fallback;
    }

    function color(d as Dictionary, key as String, fallback as Number) as Number {
        return parseColor(d[key] as Object?, fallback);
    }

    var CUSTOM_FONTS as Dictionary<String, ResourceId> = {
        "@Value" => Rez.Fonts.Value,
        "@ValueLarge" => Rez.Fonts.ValueLarge,
        "@Label" => Rez.Fonts.Label
    } as Dictionary<String, ResourceId>;
    var _loadedFonts as Dictionary<String, FontResource> = {} as Dictionary<String, FontResource>;

    //! A Graphics.FONT_* name or a "@Name" bitmap font from the resource build.
    function font(d as Dictionary, key as String, fallback as Graphics.FontType) as Graphics.FontType {
        var value = d[key];
        if (value instanceof String) {
            var found = systemFont(value);
            if (found != null) {
                return found;
            }
            var custom = CUSTOM_FONTS[value];
            if (custom != null) {
                var loaded = _loadedFonts[value];
                if (loaded == null) {
                    loaded = WatchUi.loadResource(custom) as FontResource;
                    _loadedFonts[value] = loaded;
                }
                return loaded;
            }
        }
        return fallback;
    }

    function justify(d as Dictionary, key as String) as Graphics.TextJustification {
        var value = d[key];
        if (value instanceof String) {
            if (value.equals("left")) {
                return Graphics.TEXT_JUSTIFY_LEFT;
            }
            if (value.equals("right")) {
                return Graphics.TEXT_JUSTIFY_RIGHT;
            }
        }
        return Graphics.TEXT_JUSTIFY_CENTER;
    }
}

//! Geometry and colour of one hand.
class HandSpec {
    var length as Float;
    var width as Number;
    var color as Number;
    var shape as Number;
    var tail as Float;
    var counterweight as Number;

    function initialize(d as Dictionary, defaultLength as Float, defaultWidth as Number) {
        length = SkinDefs.flt(d, "length", defaultLength);
        width = SkinDefs.num(d, "width", defaultWidth);
        color = SkinDefs.color(d, "color", Graphics.COLOR_WHITE);
        shape = SkinDefs.shapeOption(d, "shape", SkinDefs.SHAPE_BATON);
        tail = SkinDefs.flt(d, "tail", 0.1);
        counterweight = SkinDefs.num(d, "counterweight", 0);
    }
}

//! A fully parsed skin definition. Every field has a default so a partial JSON still renders.
class Skin {
    var id as String;

    var backgroundColor as Number;
    var dialColor as Number;
    var tickMajorColor as Number;
    var tickMinorColor as Number;
    var numeralColor as Number;
    var accentColor as Number;
    var slotValueColor as Number;
    var slotLabelColor as Number;
    var capColor as Number;
    var pageIndicatorColor as Number;

    var showMinorTicks as Boolean;
    var tickMajorLength as Number;
    var tickMinorLength as Number;
    var tickMajorWidth as Number;
    var tickMinorWidth as Number;

    var numeralStyle as Number;
    var numeralFont as Graphics.FontType;
    var numeralRadius as Number;

    var hourHand as HandSpec;
    var minuteHand as HandSpec;
    var secondHand as HandSpec;
    var capRadius as Number;
    var secondsHandMode as Number;

    var slotFont as Graphics.FontType;
    var slotLabelFont as Graphics.FontType;
    var showIcons as Boolean;
    var showLabels as Boolean;

    var pageIndicatorVisible as Boolean;
    var pageIndicatorX as Number;
    var pageIndicatorY as Number;
    var pageIndicatorDotRadius as Float;
    var hitboxPaddingPercent as Number;

    var _weather as WeatherSkin?;
    var _health as HealthSkin?;
    var _effects as EffectsSkin?;
    var _dial as DialSkin?;
    var _panels as PanelSkin?;
    var _battery as BatterySkin?;

    function initialize(d as Dictionary) {
        id = SkinDefs.str(d, "id", "unknown");

        var colors = SkinDefs.dict(d, "colors");
        backgroundColor = SkinDefs.color(colors, "background", Graphics.COLOR_BLACK);
        dialColor = SkinDefs.color(colors, "dial", backgroundColor);
        tickMajorColor = SkinDefs.color(colors, "tickMajor", Graphics.COLOR_WHITE);
        tickMinorColor = SkinDefs.color(colors, "tickMinor", Graphics.COLOR_LT_GRAY);
        numeralColor = SkinDefs.color(colors, "numeral", Graphics.COLOR_WHITE);
        accentColor = SkinDefs.color(colors, "accent", Graphics.COLOR_RED);
        slotValueColor = SkinDefs.color(colors, "slotValue", Graphics.COLOR_WHITE);
        slotLabelColor = SkinDefs.color(colors, "slotLabel", Graphics.COLOR_LT_GRAY);
        capColor = SkinDefs.color(colors, "cap", Graphics.COLOR_WHITE);
        pageIndicatorColor = SkinDefs.color(colors, "pageIndicator", Graphics.COLOR_LT_GRAY);

        var ticks = SkinDefs.dict(d, "ticks");
        showMinorTicks = SkinDefs.bool(ticks, "showMinor", true);
        tickMajorLength = SkinDefs.num(ticks, "majorLength", 10);
        tickMinorLength = SkinDefs.num(ticks, "minorLength", 4);
        tickMajorWidth = SkinDefs.num(ticks, "majorWidth", 3);
        tickMinorWidth = SkinDefs.num(ticks, "minorWidth", 1);

        var numerals = SkinDefs.dict(d, "numerals");
        numeralStyle = SkinDefs.numeralStyleOption(numerals, "style", SkinDefs.NUMERALS_QUARTERS);
        numeralFont = SkinDefs.font(numerals, "font", Graphics.FONT_MEDIUM);
        numeralRadius = SkinDefs.num(numerals, "radius", 76);

        var hands = SkinDefs.dict(d, "hands");
        hourHand = new HandSpec(SkinDefs.dict(hands, "hour"), 0.5, 8);
        minuteHand = new HandSpec(SkinDefs.dict(hands, "minute"), 0.8, 6);
        secondHand = new HandSpec(SkinDefs.dict(hands, "second"), 0.9, 2);
        capRadius = SkinDefs.num(hands, "capRadius", 4);
        secondsHandMode = SkinDefs.secondsModeOption(d, "secondsHandMode", SkinDefs.SECONDS_AWAKE_ONLY);

        var slots = SkinDefs.dict(d, "slots");
        slotFont = SkinDefs.font(slots, "font", Graphics.FONT_TINY);
        slotLabelFont = SkinDefs.font(slots, "labelFont", Graphics.FONT_XTINY);
        showIcons = SkinDefs.bool(slots, "showIcons", false);
        showLabels = SkinDefs.bool(slots, "showLabels", false);

        var indicator = SkinDefs.dict(d, "pageIndicator");
        pageIndicatorVisible = SkinDefs.bool(indicator, "visible", true);
        pageIndicatorX = SkinDefs.num(indicator, "x", 50);
        pageIndicatorY = SkinDefs.num(indicator, "y", 90);
        pageIndicatorDotRadius = SkinDefs.flt(indicator, "dotRadius", 1.2);

        hitboxPaddingPercent = SkinDefs.num(d, "hitboxPaddingPercent", 15);
    }

    //! Second stage: dial depth, panels and battery block from the layout resource.
    function parseLayout(d as Dictionary) as Void {
        _dial = new DialSkin(SkinDefs.dict(d, "dial"));
        _panels = new PanelSkin(SkinDefs.dict(d, "panels"));
        _battery = new BatterySkin(SkinDefs.dict(d, "battery"));
    }

    function dial() as DialSkin {
        var value = _dial;
        if (value == null) {
            value = new DialSkin({});
            _dial = value;
        }
        return value;
    }

    function panels() as PanelSkin {
        var value = _panels;
        if (value == null) {
            value = new PanelSkin({});
            _panels = value;
        }
        return value;
    }

    function battery() as BatterySkin {
        var value = _battery;
        if (value == null) {
            value = new BatterySkin({});
            _battery = value;
        }
        return value;
    }

    //! Third stage: the page blocks, loaded from a separate resource to keep the peak low.
    function parsePages(d as Dictionary) as Void {
        _weather = new WeatherSkin(SkinDefs.dict(d, "weatherPage"));
        _health = new HealthSkin(SkinDefs.dict(d, "healthPage"));
        _effects = new EffectsSkin(SkinDefs.dict(d, "effects"));
    }

    function weather() as WeatherSkin {
        var value = _weather;
        if (value == null) {
            value = new WeatherSkin({});
            _weather = value;
        }
        return value;
    }

    function health() as HealthSkin {
        var value = _health;
        if (value == null) {
            value = new HealthSkin({});
            _health = value;
        }
        return value;
    }

    function effects() as EffectsSkin {
        var value = _effects;
        if (value == null) {
            value = new EffectsSkin({});
            _effects = value;
        }
        return value;
    }

    //! Resolve the "accent" reference to the current accent colour.
    function resolveColor(value as Number) as Number {
        return (value == SkinDefs.ACCENT_REF) ? accentColor : value;
    }

    //! Apply on-device editor colour choices. Null keeps the skin value.
    function applyOverrides(accent as Number?, dataColor as Number?) as Void {
        if (accent != null) {
            accentColor = accent;
        }
        if (dataColor != null) {
            slotValueColor = dataColor;
        }
    }
}
