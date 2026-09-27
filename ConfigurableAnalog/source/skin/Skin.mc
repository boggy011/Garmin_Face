import Toybox.Graphics;
import Toybox.Lang;

//! Constants and typed accessors used to turn a skin JSON dictionary into a Skin.
module SkinDefs {
    const ACCENT_REF = -2;

    enum { NUMERALS_NONE = 0, NUMERALS_QUARTERS = 1, NUMERALS_ALL = 2 }
    enum { SECONDS_ALWAYS = 0, SECONDS_AWAKE_ONLY = 1, SECONDS_NEVER = 2 }
    enum { SHAPE_BATON = 0, SHAPE_DAUPHINE = 1, SHAPE_ARROW = 2, SHAPE_LINE = 3 }

    var NAMED_COLORS as Dictionary<String, Number> = {
        "COLOR_WHITE" => Graphics.COLOR_WHITE,
        "COLOR_LT_GRAY" => Graphics.COLOR_LT_GRAY,
        "COLOR_DK_GRAY" => Graphics.COLOR_DK_GRAY,
        "COLOR_BLACK" => Graphics.COLOR_BLACK,
        "COLOR_RED" => Graphics.COLOR_RED,
        "COLOR_DK_RED" => Graphics.COLOR_DK_RED,
        "COLOR_ORANGE" => Graphics.COLOR_ORANGE,
        "COLOR_YELLOW" => Graphics.COLOR_YELLOW,
        "COLOR_GREEN" => Graphics.COLOR_GREEN,
        "COLOR_DK_GREEN" => Graphics.COLOR_DK_GREEN,
        "COLOR_BLUE" => Graphics.COLOR_BLUE,
        "COLOR_DK_BLUE" => Graphics.COLOR_DK_BLUE,
        "COLOR_PURPLE" => Graphics.COLOR_PURPLE,
        "COLOR_PINK" => Graphics.COLOR_PINK,
        "COLOR_TRANSPARENT" => Graphics.COLOR_TRANSPARENT
    } as Dictionary<String, Number>;

    var FONTS as Dictionary<String, Graphics.FontDefinition> = {
        "FONT_XTINY" => Graphics.FONT_XTINY,
        "FONT_TINY" => Graphics.FONT_TINY,
        "FONT_SMALL" => Graphics.FONT_SMALL,
        "FONT_MEDIUM" => Graphics.FONT_MEDIUM,
        "FONT_LARGE" => Graphics.FONT_LARGE,
        "FONT_NUMBER_MILD" => Graphics.FONT_NUMBER_MILD,
        "FONT_NUMBER_MEDIUM" => Graphics.FONT_NUMBER_MEDIUM,
        "FONT_NUMBER_HOT" => Graphics.FONT_NUMBER_HOT,
        "FONT_NUMBER_THAI_HOT" => Graphics.FONT_NUMBER_THAI_HOT,
        "FONT_SYSTEM_XTINY" => Graphics.FONT_SYSTEM_XTINY,
        "FONT_SYSTEM_TINY" => Graphics.FONT_SYSTEM_TINY,
        "FONT_SYSTEM_SMALL" => Graphics.FONT_SYSTEM_SMALL,
        "FONT_SYSTEM_MEDIUM" => Graphics.FONT_SYSTEM_MEDIUM,
        "FONT_SYSTEM_LARGE" => Graphics.FONT_SYSTEM_LARGE
    } as Dictionary<String, Graphics.FontDefinition>;

    var JUSTIFY as Dictionary<String, Graphics.TextJustification> = {
        "left" => Graphics.TEXT_JUSTIFY_LEFT,
        "center" => Graphics.TEXT_JUSTIFY_CENTER,
        "right" => Graphics.TEXT_JUSTIFY_RIGHT
    } as Dictionary<String, Graphics.TextJustification>;

    var SHAPES as Dictionary<String, Number> = {
        "baton" => SHAPE_BATON, "dauphine" => SHAPE_DAUPHINE, "arrow" => SHAPE_ARROW, "line" => SHAPE_LINE
    } as Dictionary<String, Number>;

    var NUMERAL_STYLES as Dictionary<String, Number> = {
        "none" => NUMERALS_NONE, "quarters" => NUMERALS_QUARTERS, "all" => NUMERALS_ALL
    } as Dictionary<String, Number>;

    var SECONDS_MODES as Dictionary<String, Number> = {
        "always" => SECONDS_ALWAYS, "awakeOnly" => SECONDS_AWAKE_ONLY, "never" => SECONDS_NEVER
    } as Dictionary<String, Number>;

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
            var named = NAMED_COLORS[value];
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

    function font(d as Dictionary, key as String, fallback as Graphics.FontDefinition) as Graphics.FontDefinition {
        var value = d[key];
        if (value instanceof String) {
            var found = FONTS[value];
            if (found != null) {
                return found;
            }
        }
        return fallback;
    }

    function justify(d as Dictionary, key as String) as Graphics.TextJustification {
        var value = d[key];
        if (value instanceof String) {
            var found = JUSTIFY[value];
            if (found != null) {
                return found;
            }
        }
        return Graphics.TEXT_JUSTIFY_CENTER;
    }

    function lookup(table as Dictionary<String, Number>, d as Dictionary, key as String, fallback as Number) as Number {
        var value = d[key];
        if (value instanceof String) {
            var found = table[value];
            if (found != null) {
                return found;
            }
        }
        return fallback;
    }
}

//! Geometry and colour of one hand.
class HandSpec {
    var length as Float;
    var width as Number;
    var color as Number;
    var shape as Number;
    var tail as Float;

    function initialize(d as Dictionary, defaultLength as Float, defaultWidth as Number) {
        length = SkinDefs.flt(d, "length", defaultLength);
        width = SkinDefs.num(d, "width", defaultWidth);
        color = SkinDefs.color(d, "color", Graphics.COLOR_WHITE);
        shape = SkinDefs.lookup(SkinDefs.SHAPES, d, "shape", SkinDefs.SHAPE_BATON);
        tail = SkinDefs.flt(d, "tail", 0.1);
    }
}

//! A fully parsed skin definition. Every field has a default so a partial JSON still renders.
class Skin {
    var id as String;
    var name as String;

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
    var numeralFont as Graphics.FontDefinition;
    var numeralRadius as Number;

    var hourHand as HandSpec;
    var minuteHand as HandSpec;
    var secondHand as HandSpec;
    var capRadius as Number;
    var secondsHandMode as Number;

    var slotFont as Graphics.FontDefinition;
    var slotLabelFont as Graphics.FontDefinition;
    var showIcons as Boolean;
    var showLabels as Boolean;
    var slotX as Array<Number>;
    var slotY as Array<Number>;
    var slotW as Array<Number>;
    var slotAlign as Array<Graphics.TextJustification>;

    var pageIndicatorVisible as Boolean;
    var pageIndicatorX as Number;
    var pageIndicatorY as Number;
    var pageIndicatorDotRadius as Float;

    var weather as WeatherSkin;
    var health as HealthSkin;
    var effects as EffectsSkin;

    function initialize(d as Dictionary) {
        id = SkinDefs.str(d, "id", "unknown");
        name = SkinDefs.str(d, "name", id);

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
        numeralStyle = SkinDefs.lookup(SkinDefs.NUMERAL_STYLES, numerals, "style", SkinDefs.NUMERALS_QUARTERS);
        numeralFont = SkinDefs.font(numerals, "font", Graphics.FONT_MEDIUM);
        numeralRadius = SkinDefs.num(numerals, "radius", 76);

        var hands = SkinDefs.dict(d, "hands");
        hourHand = new HandSpec(SkinDefs.dict(hands, "hour"), 0.5, 8);
        minuteHand = new HandSpec(SkinDefs.dict(hands, "minute"), 0.8, 6);
        secondHand = new HandSpec(SkinDefs.dict(hands, "second"), 0.9, 2);
        capRadius = SkinDefs.num(hands, "capRadius", 4);
        secondsHandMode = SkinDefs.lookup(SkinDefs.SECONDS_MODES, d, "secondsHandMode", SkinDefs.SECONDS_AWAKE_ONLY);

        var slots = SkinDefs.dict(d, "slots");
        slotFont = SkinDefs.font(slots, "font", Graphics.FONT_TINY);
        slotLabelFont = SkinDefs.font(slots, "labelFont", Graphics.FONT_XTINY);
        showIcons = SkinDefs.bool(slots, "showIcons", false);
        showLabels = SkinDefs.bool(slots, "showLabels", false);
        slotX = [] as Array<Number>;
        slotY = [] as Array<Number>;
        slotW = [] as Array<Number>;
        slotAlign = [] as Array<Graphics.TextJustification>;
        var positions = SkinDefs.array(slots, "positions");
        for (var i = 0; i < SettingsKeys.SLOTS_PER_PAGE; i++) {
            var raw = (i < positions.size()) ? positions[i] : null;
            var position = (raw instanceof Dictionary) ? raw : {};
            slotX.add(SkinDefs.num(position, "x", 50));
            slotY.add(SkinDefs.num(position, "y", 20 + i * 15));
            slotW.add(SkinDefs.num(position, "w", 30));
            slotAlign.add(SkinDefs.justify(position, "align"));
        }

        var indicator = SkinDefs.dict(d, "pageIndicator");
        pageIndicatorVisible = SkinDefs.bool(indicator, "visible", true);
        pageIndicatorX = SkinDefs.num(indicator, "x", 50);
        pageIndicatorY = SkinDefs.num(indicator, "y", 90);
        pageIndicatorDotRadius = SkinDefs.flt(indicator, "dotRadius", 1.2);

        weather = new WeatherSkin(SkinDefs.dict(d, "weatherPage"));
        health = new HealthSkin(SkinDefs.dict(d, "healthPage"));
        effects = new EffectsSkin(SkinDefs.dict(d, "effects"));
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

    //! Unique colours used by the static dial and page backgrounds, for a small buffered bitmap palette.
    function getDialPalette() as Array<Number> {
        var candidates = [
            backgroundColor, dialColor, tickMajorColor, tickMinorColor, numeralColor,
            weather.sunArcColor, weather.moonArcColor, weather.horizonColor, health.trackColor
        ] as Array<Number>;
        var palette = [] as Array<Number>;
        for (var i = 0; i < candidates.size(); i++) {
            var resolved = resolveColor(candidates[i]);
            if (palette.indexOf(resolved) < 0) {
                palette.add(resolved);
            }
        }
        return palette;
    }
}
