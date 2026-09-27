import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;

//! Sun arc, moon arc with phase, condition icon and four readouts. Geometry and colours
//! come from skin.weather, values from WeatherCache. Per frame drawing allocates nothing.
class WeatherPageRenderer {
    enum { ICON_TEMPERATURE = 0, ICON_PRECIPITATION = 1, ICON_UV = 2, ICON_PRESSURE = 3, ICON_SUN = 4, ICON_MOON = 5 }

    private var _width as Number;
    private var _height as Number;
    private var _cx as Number;
    private var _cy as Number;
    private var _conditionIcons as IconSet;
    private var _icons as IconSet;
    private var _point as Array<Number> = [0, 0] as Array<Number>;

    function initialize(width as Number, height as Number) {
        _width = width;
        _height = height;
        _cx = width / 2;
        _cy = height / 2;
        _conditionIcons = new IconSet([
            Rez.Drawables.ic_clear, Rez.Drawables.ic_partly_cloudy, Rez.Drawables.ic_cloudy, Rez.Drawables.ic_rain,
            Rez.Drawables.ic_heavy_rain, Rez.Drawables.ic_snow, Rez.Drawables.ic_sleet, Rez.Drawables.ic_thunder,
            Rez.Drawables.ic_fog, Rez.Drawables.ic_wind
        ] as Array<ResourceId>);
        _icons = new IconSet([
            Rez.Drawables.ic_temperature, Rez.Drawables.ic_precipitation, Rez.Drawables.ic_uv, Rez.Drawables.ic_pressure,
            Rez.Drawables.ic_sun, Rez.Drawables.ic_moon
        ] as Array<ResourceId>);
    }

    function arcRadius(skin as Skin) as Number {
        return _width * skin.weather.arcRadius / 100;
    }

    //! Screen y of the horizon line (the arcs' diameter).
    function horizonY() as Number {
        return _cy;
    }

    //! Static arcs and horizon ticks.
    function drawStatic(dc as Dc, skin as Skin) as Void {
        var ws = skin.weather;
        var r = arcRadius(skin);
        dc.setPenWidth(ws.arcWidth);
        dc.setColor(skin.resolveColor(ws.sunArcColor), Graphics.COLOR_TRANSPARENT);
        dc.drawArc(_cx, _cy, r, Graphics.ARC_CLOCKWISE, 180, 0);
        dc.setColor(skin.resolveColor(ws.moonArcColor), Graphics.COLOR_TRANSPARENT);
        dc.drawArc(_cx, _cy, r, Graphics.ARC_COUNTER_CLOCKWISE, 180, 360);
        var tick = _width * 3 / 100;
        dc.setColor(skin.resolveColor(ws.horizonColor), Graphics.COLOR_TRANSPARENT);
        dc.drawLine(_cx - r - tick, _cy, _cx - r + tick, _cy);
        dc.drawLine(_cx + r - tick, _cy, _cx + r + tick, _cy);
        dc.setPenWidth(1);
    }

    //! Discs, labels, condition icon and readouts.
    function draw(dc as Dc, skin as Skin, now as Number) as Void {
        var ws = skin.weather;
        var r = arcRadius(skin);
        drawSun(dc, skin, r, now);
        drawMoon(dc, skin, r, now);
        if (Settings.getShowSunTimes()) {
            dc.setColor(skin.resolveColor(ws.labelColor), Graphics.COLOR_TRANSPARENT);
            drawLabel(dc, ws.sunriseLabel, ws.labelFont, WeatherCache.sunriseLabel);
            drawLabel(dc, ws.sunsetLabel, ws.labelFont, WeatherCache.sunsetLabel);
        }
        if (Settings.getShowMoonPhaseLabel()) {
            dc.setColor(skin.resolveColor(ws.labelColor), Graphics.COLOR_TRANSPARENT);
            drawLabel(dc, ws.phaseLabel, ws.labelFont, WeatherCache.moonPhaseLabel);
        }
        _conditionIcons.drawCentered(dc, WeatherCache.category, _width * ws.icon.x / 100, _height * ws.icon.y / 100);
        var color = skin.resolveColor(ws.readoutColor);
        Readouts.draw(dc, _icons, ICON_TEMPERATURE, ws.readouts[0], WeatherCache.temperature, ws.readoutFont, color, _width, _height);
        Readouts.draw(dc, _icons, ICON_PRECIPITATION, ws.readouts[1], WeatherCache.precipitation, ws.readoutFont, color, _width, _height);
        Readouts.draw(dc, _icons, ICON_UV, ws.readouts[2], WeatherCache.uv, ws.readoutFont, color, _width, _height);
        Readouts.draw(dc, _icons, ICON_PRESSURE, ws.readouts[3], WeatherCache.pressure, ws.readoutFont, color, _width, _height);
    }

    private function drawLabel(dc as Dc, anchor as Anchor, font as Graphics.FontDefinition, text as String) as Void {
        dc.drawText(_width * anchor.x / 100, _height * anchor.y / 100, font, text, anchor.align | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    //! Point on the top (or mirrored bottom) semicircle for a 0..1 progress, left to right.
    private function arcPoint(r as Number, progress as Float, top as Boolean) as Void {
        var angle = Math.PI * (1.0 - progress);
        _point[0] = (_cx + r * Math.cos(angle)).toNumber();
        var dy = (r * Math.sin(angle)).toNumber();
        _point[1] = top ? _cy - dy : _cy + dy;
    }

    private function drawSun(dc as Dc, skin as Skin, r as Number, now as Number) as Void {
        var ws = skin.weather;
        var rise = WeatherCache.sunrise;
        var set = WeatherCache.sunset;
        var up = false;
        var progress = 0.0;
        if (rise != null && set != null && set > rise) {
            up = now >= rise && now <= set;
            progress = clamp01((now - rise).toFloat() / (set - rise).toFloat());
        }
        arcPoint(r, progress, true);
        if (up) {
            _icons.drawCentered(dc, ICON_SUN, _point[0], _point[1]);
        } else {
            dc.setColor(skin.resolveColor(ws.sunDimColor), Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(_point[0], _point[1], _icons.width(ICON_SUN) / 3);
        }
    }

    private function drawMoon(dc as Dc, skin as Skin, r as Number, now as Number) as Void {
        var progress = moonProgress(now);
        arcPoint(r, progress, false);
        drawMoonDisc(dc, skin, _point[0], _point[1], _icons.width(ICON_MOON) / 2);
    }

    //! 0..1 position of the moon between moonrise and moonset, handling a set before rise
    //! (moon up over midnight). Horizon ends when the moon is down or times are unknown.
    private function moonProgress(now as Number) as Float {
        var rise = WeatherCache.moonRise;
        var set = WeatherCache.moonSet;
        if (rise == null || set == null) {
            return 0.5;
        }
        var start = rise;
        var end = set;
        if (set < rise) {
            if (now < set) {
                start = rise - Sources.SECONDS_PER_DAY;
            } else {
                end = set + Sources.SECONDS_PER_DAY;
            }
        }
        if (now < start) {
            return 0.0;
        }
        if (now > end) {
            return 1.0;
        }
        return clamp01((now - start).toFloat() / (end - start).toFloat());
    }

    //! Moon disc with the illuminated fraction drawn procedurally: base bitmap, unlit half,
    //! then an ellipse for the terminator (dark for a crescent, lit for a gibbous moon).
    function drawMoonDisc(dc as Dc, skin as Skin, x as Number, y as Number, radius as Number) as Void {
        var ws = skin.weather;
        var lit = skin.resolveColor(ws.moonLitColor);
        var dark = skin.resolveColor(ws.moonDarkColor);
        var k = WeatherCache.moonIllumination;
        var litOnRight = WeatherCache.moonWaxing;
        _icons.drawCentered(dc, ICON_MOON, x, y);
        dc.setColor(dark, Graphics.COLOR_TRANSPARENT);
        if (litOnRight) {
            dc.setClip(x - radius - 1, y - radius - 1, radius + 1, 2 * radius + 3);
        } else {
            dc.setClip(x, y - radius - 1, radius + 2, 2 * radius + 3);
        }
        dc.fillCircle(x, y, radius);
        dc.clearClip();
        var a = ((1.0 - 2.0 * k).abs() * radius).toNumber();
        if (a > 0) {
            dc.setColor((k < 0.5) ? dark : lit, Graphics.COLOR_TRANSPARENT);
            dc.fillEllipse(x, y, a, radius);
        }
    }

    private function clamp01(value as Float) as Float {
        if (value < 0.0) {
            return 0.0;
        }
        if (value > 1.0) {
            return 1.0;
        }
        return value;
    }
}
