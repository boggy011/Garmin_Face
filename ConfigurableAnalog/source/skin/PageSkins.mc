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

//! Parse an array of anchors, padding with defaults so there are always count entries.
function parseAnchors(d as Dictionary, key as String, count as Number, defaults as Array<Array<Number>>) as Array<Anchor> {
    var raw = SkinDefs.array(d, key);
    var anchors = [] as Array<Anchor>;
    for (var i = 0; i < count; i++) {
        var item = (i < raw.size()) ? raw[i] : null;
        var dict = (item instanceof Dictionary) ? item : {};
        anchors.add(new Anchor(dict, defaults[i][0], defaults[i][1]));
    }
    return anchors;
}

//! Skin block "weatherPage".
class WeatherSkin {
    var arcRadius as Number;
    var arcWidth as Number;
    var sunArcColor as Number;
    var moonArcColor as Number;
    var sunColor as Number;
    var sunDimColor as Number;
    var moonLitColor as Number;
    var moonDarkColor as Number;
    var horizonColor as Number;
    var labelColor as Number;
    var readoutColor as Number;
    var labelFont as Graphics.FontDefinition;
    var readoutFont as Graphics.FontDefinition;
    var sunriseLabel as Anchor;
    var sunsetLabel as Anchor;
    var phaseLabel as Anchor;
    var icon as Anchor;
    var readouts as Array<Anchor>;

    function initialize(d as Dictionary) {
        arcRadius = SkinDefs.num(d, "arcRadius", 41);
        arcWidth = SkinDefs.num(d, "arcWidth", 2);
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
        readouts = parseAnchors(d, "readouts", 4, [[30, 38], [70, 38], [30, 62], [70, 62]] as Array<Array<Number>>);
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
    var heartRateFont as Graphics.FontDefinition;
    var heartRateColor as Number;
    var heartIcon as Anchor;
    var readoutColor as Number;
    var readoutFont as Graphics.FontDefinition;
    var readouts as Array<Anchor>;

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
        readouts = parseAnchors(d, "readouts", 4, [[28, 36], [72, 36], [28, 66], [72, 66]] as Array<Array<Number>>);
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
