import Toybox.Graphics;
import Toybox.Lang;

//! A position in percent of the screen with a text alignment.
class Anchor {
    var x as Number;
    var y as Number;
    var align as Graphics.TextJustification;

    function initialize(d as Dictionary, defaultX as Number, defaultY as Number) {
        x = SkinDefs.num(d, "x", defaultX);
        y = SkinDefs.num(d, "y", defaultY);
        align = SkinDefs.justify(d, "align");
    }
}

//! Skin block "weatherPage".
class WeatherSkin {
    var arcRadius as Number;
    var arcWidth as Number;
    var arcWidthPercent as Float;
    var arcDither as Boolean;
    var sunArcColor as Number;
    var moonArcColor as Number;
    var sunColor as Number;
    var sunDimColor as Number;
    var moonLitColor as Number;
    var moonDarkColor as Number;
    var horizonColor as Number;
    var labelColor as Number;
    var readoutColor as Number;
    var labelFont as Graphics.FontType;
    var readoutFont as Graphics.FontType;
    var sunriseLabel as Anchor;
    var sunsetLabel as Anchor;
    var phaseLabel as Anchor;
    var icon as Anchor;
    var chartY as Number;

    function initialize(d as Dictionary) {
        arcRadius = SkinDefs.num(d, "arcRadius", 41);
        arcWidth = SkinDefs.num(d, "arcWidth", 2);
        arcWidthPercent = SkinDefs.flt(d, "arcWidthPercent", 2.0);
        arcDither = SkinDefs.bool(d, "arcDither", true);
        sunArcColor = SkinDefs.color(d, "sunArcColor", Graphics.COLOR_YELLOW);
        moonArcColor = SkinDefs.color(d, "moonArcColor", Graphics.COLOR_LT_GRAY);
        sunColor = SkinDefs.color(d, "sunColor", Graphics.COLOR_YELLOW);
        sunDimColor = SkinDefs.color(d, "sunDimColor", Graphics.COLOR_DK_GRAY);
        moonLitColor = SkinDefs.color(d, "moonLitColor", Graphics.COLOR_WHITE);
        moonDarkColor = SkinDefs.color(d, "moonDarkColor", Graphics.COLOR_DK_GRAY);
        horizonColor = SkinDefs.color(d, "horizonColor", Graphics.COLOR_DK_GRAY);
        labelColor = SkinDefs.color(d, "labelColor", Graphics.COLOR_LT_GRAY);
        readoutColor = SkinDefs.color(d, "readoutColor", Graphics.COLOR_WHITE);
        labelFont = SkinDefs.font(d, "labelFont", Graphics.FONT_XTINY);
        readoutFont = SkinDefs.font(d, "readoutFont", Graphics.FONT_XTINY);
        sunriseLabel = new Anchor(SkinDefs.dict(d, "sunriseLabel"), 12, 44);
        sunsetLabel = new Anchor(SkinDefs.dict(d, "sunsetLabel"), 88, 44);
        phaseLabel = new Anchor(SkinDefs.dict(d, "phaseLabel"), 50, 84);
        icon = new Anchor(SkinDefs.dict(d, "icon"), 50, 50);
        chartY = SkinDefs.num(d, "chartY", 88);
    }
}

//! Skin block "healthPage".
class HealthSkin {
    var arcRadius as Number;
    var arcWidth as Number;
    var trackColor as Number;
    var bodyBatteryColor as Number;
    var spo2Color as Number;
    var hrvColor as Number;
    var stressLowColor as Number;
    var stressMediumColor as Number;
    var stressHighColor as Number;
    var stressLowMax as Number;
    var stressMediumMax as Number;
    var heartRate as Anchor;
    var heartRateFont as Graphics.FontType;
    var heartRateColor as Number;
    var heartIcon as Anchor;
    var readoutColor as Number;
    var readoutFont as Graphics.FontType;

    function initialize(d as Dictionary) {
        arcRadius = SkinDefs.num(d, "arcRadius", 41);
        arcWidth = SkinDefs.num(d, "arcWidth", 5);
        trackColor = SkinDefs.color(d, "trackColor", Graphics.COLOR_DK_GRAY);
        bodyBatteryColor = SkinDefs.color(d, "bodyBatteryColor", Graphics.COLOR_BLUE);
        spo2Color = SkinDefs.color(d, "spo2Color", Graphics.COLOR_PINK);
        hrvColor = SkinDefs.color(d, "hrvColor", Graphics.COLOR_PURPLE);
        stressLowColor = SkinDefs.color(d, "stressLowColor", Graphics.COLOR_GREEN);
        stressMediumColor = SkinDefs.color(d, "stressMediumColor", Graphics.COLOR_YELLOW);
        stressHighColor = SkinDefs.color(d, "stressHighColor", Graphics.COLOR_RED);
        stressLowMax = SkinDefs.num(d, "stressLowMax", 25);
        stressMediumMax = SkinDefs.num(d, "stressMediumMax", 50);
        var hr = SkinDefs.dict(d, "heartRate");
        heartRate = new Anchor(hr, 50, 57);
        heartRateFont = SkinDefs.font(hr, "font", Graphics.FONT_NUMBER_MILD);
        heartRateColor = SkinDefs.color(hr, "color", Graphics.COLOR_WHITE);
        heartIcon = new Anchor(SkinDefs.dict(d, "heartIcon"), 50, 38);
        readoutColor = SkinDefs.color(d, "readoutColor", Graphics.COLOR_WHITE);
        readoutFont = SkinDefs.font(d, "readoutFont", Graphics.FONT_XTINY);
    }
}

//! Skin block "effects": particle counts and frame rates per display profile, colours.
class EffectsSkin {
    var fpsMip as Number;
    var fpsAmoled as Number;
    var rainMip as Number;
    var rainAmoled as Number;
    var snowMip as Number;
    var snowAmoled as Number;
    var rainColor as Number;
    var snowColor as Number;
    var flashColor as Number;
    var fogColor as Number;
    var windColor as Number;
    var rainSpeed as Float;
    var snowSpeed as Float;

    function initialize(d as Dictionary) {
        var mip = SkinDefs.dict(d, "mip");
        var amoled = SkinDefs.dict(d, "amoled");
        fpsMip = SkinDefs.num(mip, "fps", 6);
        fpsAmoled = SkinDefs.num(amoled, "fps", 10);
        rainMip = SkinDefs.num(mip, "rain", 40);
        rainAmoled = SkinDefs.num(amoled, "rain", 80);
        snowMip = SkinDefs.num(mip, "snow", 30);
        snowAmoled = SkinDefs.num(amoled, "snow", 60);
        rainColor = SkinDefs.color(d, "rainColor", Graphics.COLOR_BLUE);
        snowColor = SkinDefs.color(d, "snowColor", Graphics.COLOR_WHITE);
        flashColor = SkinDefs.color(d, "flashColor", Graphics.COLOR_PURPLE);
        fogColor = SkinDefs.color(d, "fogColor", Graphics.COLOR_LT_GRAY);
        windColor = SkinDefs.color(d, "windColor", Graphics.COLOR_LT_GRAY);
        rainSpeed = SkinDefs.flt(d, "rainSpeed", 1.0);
        snowSpeed = SkinDefs.flt(d, "snowSpeed", 1.0);
    }
}

//! Skin block "dial": pre rendered depth for the cached dial bitmap plus hand and cap options.
class DialSkin {
    enum { TEXTURE_NONE = 0, TEXTURE_SUNBURST = 1, TEXTURE_RINGS = 2, TEXTURE_CROSSHATCH = 3, TEXTURE_DOT_GRID = 4 }

    var texture as Number;
    var textureColor as Number;
    var textureSpacing as Number;
    var chapterRing as Boolean;
    var chapterRingRadius as Number;
    var chapterRingWidth as Number;
    var chapterRingColor as Number;
    var accentQuadrant as Number;
    var innerBezel as Boolean;
    var innerBezelRadius as Number;
    var innerBezelColor as Number;
    var subdialFrames as Boolean;
    var subdialRadius as Number;
    var subdialFill as Number;
    var subdialRim as Number;
    var handShadow as Boolean;
    var handShadowColor as Number;
    var handShadowOffset as Number;
    var centreCap as Boolean;
    var centreCapRadius as Number;
    var centreCapRim as Number;
    var centreCapFill as Number;

    function initialize(d as Dictionary) {
        texture = SkinDefs.lookup(SkinDefs.TEXTURES, d, "texture", TEXTURE_NONE);
        textureColor = SkinDefs.color(d, "textureColor", Graphics.COLOR_DK_GRAY);
        textureSpacing = SkinDefs.num(d, "textureSpacing", 3);
        var ring = SkinDefs.dict(d, "chapterRing");
        chapterRing = SkinDefs.bool(ring, "enabled", false);
        chapterRingRadius = SkinDefs.num(ring, "radius", 95);
        chapterRingWidth = SkinDefs.num(ring, "width", 1);
        chapterRingColor = SkinDefs.color(ring, "color", Graphics.COLOR_DK_GRAY);
        accentQuadrant = SkinDefs.num(ring, "accentQuadrant", -1);
        var bezel = SkinDefs.dict(d, "innerBezel");
        innerBezel = SkinDefs.bool(bezel, "enabled", false);
        innerBezelRadius = SkinDefs.num(bezel, "radius", 62);
        innerBezelColor = SkinDefs.color(bezel, "color", Graphics.COLOR_DK_GRAY);
        var frames = SkinDefs.dict(d, "subdialFrames");
        subdialFrames = SkinDefs.bool(frames, "enabled", false);
        subdialRadius = SkinDefs.num(frames, "radius", 12);
        subdialFill = SkinDefs.color(frames, "fill", Graphics.COLOR_BLACK);
        subdialRim = SkinDefs.color(frames, "rim", Graphics.COLOR_DK_GRAY);
        var shadow = SkinDefs.dict(d, "handShadow");
        handShadow = SkinDefs.bool(shadow, "enabled", false);
        handShadowColor = SkinDefs.color(shadow, "color", Graphics.COLOR_DK_GRAY);
        handShadowOffset = SkinDefs.num(shadow, "offset", 1);
        var cap = SkinDefs.dict(d, "centreCap");
        centreCap = SkinDefs.bool(cap, "enabled", true);
        centreCapRadius = SkinDefs.num(cap, "radius", 4);
        centreCapRim = SkinDefs.color(cap, "rim", Graphics.COLOR_LT_GRAY);
        centreCapFill = SkinDefs.color(cap, "fill", Graphics.COLOR_BLACK);
    }
}

//! Skin block "battery": the small battery status at the top of every page.
class BatterySkin {
    var visible as Boolean;
    var y as Number;
    var color as Number;
    var lowColor as Number;
    var lowPercent as Number;
    var font as Graphics.FontType;

    function initialize(d as Dictionary) {
        visible = SkinDefs.bool(d, "visible", true);
        y = SkinDefs.num(d, "y", 12);
        color = SkinDefs.color(d, "color", Graphics.COLOR_LT_GRAY);
        lowColor = SkinDefs.color(d, "lowColor", Graphics.COLOR_RED);
        lowPercent = SkinDefs.num(d, "lowPercent", 15);
        font = SkinDefs.font(d, "font", Graphics.FONT_XTINY);
    }
}

//! Skin block "panels": circular sub dial panels behind readouts, and the diagonal layout.
class PanelSkin {
    var diameter as Number;
    var fill as Number;
    var rim as Number;
    var tickColor as Number;
    var gauge as Boolean;
    var gaugeLowColor as Number;
    var gaugeMediumColor as Number;
    var gaugeHighColor as Number;
    var gaugeLowMax as Number;
    var gaugeMediumMax as Number;
    var spacing as Number;
    var centreDiameter as Number;
    var labelFont as Graphics.FontType;
    var valueFont as Graphics.FontType;
    var largeValueFont as Graphics.FontType;

    function initialize(d as Dictionary) {
        diameter = SkinDefs.num(d, "diameter", 24);
        fill = SkinDefs.color(d, "fill", Graphics.COLOR_BLACK);
        rim = SkinDefs.color(d, "rim", Graphics.COLOR_DK_GRAY);
        tickColor = SkinDefs.color(d, "tickColor", Graphics.COLOR_DK_GRAY);
        gauge = SkinDefs.bool(d, "gauge", true);
        gaugeLowColor = SkinDefs.color(d, "gaugeLowColor", Graphics.COLOR_RED);
        gaugeMediumColor = SkinDefs.color(d, "gaugeMediumColor", Graphics.COLOR_YELLOW);
        gaugeHighColor = SkinDefs.color(d, "gaugeHighColor", Graphics.COLOR_GREEN);
        gaugeLowMax = SkinDefs.num(d, "gaugeLowMax", 25);
        gaugeMediumMax = SkinDefs.num(d, "gaugeMediumMax", 50);
        spacing = SkinDefs.num(d, "spacing", 3);
        centreDiameter = SkinDefs.num(d, "centreDiameter", 34);
        labelFont = SkinDefs.font(d, "labelFont", Graphics.FONT_XTINY);
        valueFont = SkinDefs.font(d, "valueFont", Graphics.FONT_TINY);
        largeValueFont = SkinDefs.font(d, "largeValueFont", Graphics.FONT_NUMBER_MILD);
    }

    //! Radius (percent of screen) of the four diagonal panel centres: clear of the centre
    //! element and of each other by the configured spacing, never past the chapter ring.
    function layoutRadius(ringRadius as Number) as Number {
        var fromCentre = centreDiameter / 2 + diameter / 2 + spacing;
        var fromEachOther = (diameter + spacing) * 100 / 141;
        var radius = (fromCentre > fromEachOther) ? fromCentre : fromEachOther;
        var maximum = ringRadius - diameter / 2 - spacing;
        return (radius > maximum) ? maximum : radius;
    }
}
