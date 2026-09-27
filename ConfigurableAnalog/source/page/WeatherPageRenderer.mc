import Toybox.Complications;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.WatchUi;

//! Sun arc, moon arc with phase, condition icon, sunrise and sunset labels, four readout
//! panels, pressure trend chart, night star field. Geometry and colours come from
//! skin.weather() and skin.panels(), values from WeatherCache. Per frame drawing allocates nothing.
class WeatherPageRenderer {
    enum { ICON_TEMPERATURE = 0, ICON_PRECIPITATION = 1, ICON_UV = 2, ICON_PRESSURE = 3, ICON_SUN = 4, ICON_MOON = 5, ICON_MOON_LARGE = 6, ICON_SUNRISE = 7, ICON_SUNSET = 8 }
    const STARS = 30;
    const BARS = 12;
    const CLEAR_NIGHT_ICON = 10;

    private var _width as Number;
    private var _height as Number;
    private var _cx as Number;
    private var _cy as Number;
    private var _conditionIcons as IconSet;
    private var _backgrounds as IconSet;
    private var _icons as IconSet;
    private var _point as Array<Number> = [0, 0] as Array<Number>;
    private var _starX as Array<Number>;
    private var _starY as Array<Number>;
    private var _labels as Array<String?> = [null, null, null, null] as Array<String?>;
    private var _night as Boolean = false;
    private var _half as Array<Array<Number>> = [
        [0, 0], [0, 0], [0, 0], [0, 0], [0, 0], [0, 0], [0, 0], [0, 0], [0, 0], [0, 0], [0, 0], [0, 0], [0, 0], [0, 0], [0, 0], [0, 0], [0, 0], [0, 0]
    ] as Array<Array<Number>>;

    function initialize(width as Number, height as Number) {
        _width = width;
        _height = height;
        _cx = width / 2;
        _cy = height / 2;
        _conditionIcons = new IconSet([
            Rez.Drawables.ic_clear, Rez.Drawables.ic_partly_cloudy, Rez.Drawables.ic_cloudy, Rez.Drawables.ic_rain,
            Rez.Drawables.ic_heavy_rain, Rez.Drawables.ic_snow, Rez.Drawables.ic_sleet, Rez.Drawables.ic_thunder,
            Rez.Drawables.ic_fog, Rez.Drawables.ic_wind, Rez.Drawables.ic_clear_night
        ] as Array<ResourceId>);
        _backgrounds = new IconSet([
            Rez.Drawables.bg_clear, Rez.Drawables.bg_partly_cloudy, Rez.Drawables.bg_cloudy, Rez.Drawables.bg_rain,
            Rez.Drawables.bg_heavy_rain, Rez.Drawables.bg_snow, Rez.Drawables.bg_sleet, Rez.Drawables.bg_thunder,
            Rez.Drawables.bg_fog, Rez.Drawables.bg_wind, Rez.Drawables.bg_clear_night
        ] as Array<ResourceId>);
        _icons = new IconSet([
            Rez.Drawables.ic_temperature, Rez.Drawables.ic_precipitation, Rez.Drawables.ic_uv, Rez.Drawables.ic_pressure,
            Rez.Drawables.ic_sun, Rez.Drawables.ic_moon, Rez.Drawables.ic_moon_large, Rez.Drawables.icon_sunrise, Rez.Drawables.icon_sunset
        ] as Array<ResourceId>);
        _starX = new [STARS] as Array<Number>;
        _starY = new [STARS] as Array<Number>;
        seedStars(width);
    }

    //! Fixed star positions in the top half of the dial, from a small linear congruential
    //! generator so the field is stable between redraws.
    function seedStars(seed as Number) as Void {
        var state = seed * 7919 + 17;
        var limit = _width * 44 / 100;
        var placed = 0;
        while (placed < STARS) {
            state = (state * 1103515245 + 12345) & 0x7FFFFFFF;
            var x = (state % (2 * limit)) - limit;
            state = (state * 1103515245 + 12345) & 0x7FFFFFFF;
            var y = -(state % limit) - 4;
            if (x * x + y * y < limit * limit) {
                _starX[placed] = _cx + x;
                _starY[placed] = _cy + y;
                placed += 1;
            }
        }
    }

    function arcRadius(skin as Skin) as Number {
        return _width * skin.weather().arcRadius / 100;
    }

    function isNight(now as Number) as Boolean {
        return !SkyState.isUp(now, WeatherCache.sunrise, WeatherCache.sunset);
    }

    //! Static layer: star field at night, arcs, horizon ticks, panel frames.
    function drawStatic(dc as Dc, skin as Skin, night as Boolean) as Void {
        var ws = skin.weather();
        var r = arcRadius(skin);
        _night = night;
        if (night) {
            dc.setColor(skin.resolveColor(ws.labelColor), Graphics.COLOR_TRANSPARENT);
            for (var i = 0; i < STARS; i++) {
                dc.drawPoint(_starX[i], _starY[i]);
            }
        }
        var maxWidth = (_width * ws.arcWidthPercent / 100.0).toNumber();
        drawTaperedArc(dc, r, skin.resolveColor(ws.sunArcColor), maxWidth, ws.arcDither, true);
        drawTaperedArc(dc, r, skin.resolveColor(ws.moonArcColor), maxWidth, ws.arcDither, false);
        var tick = _width * 3 / 100;
        dc.setColor(skin.resolveColor(ws.horizonColor), Graphics.COLOR_TRANSPARENT);
        dc.drawLine(_cx - r - tick, _cy, _cx - r + tick, _cy);
        dc.drawLine(_cx + r - tick, _cy, _cx + r + tick, _cy);
        dc.setPenWidth(1);
        for (var i = 0; i < Panels.OUTER_COUNT; i++) {
            Panels.drawFrame(dc, skin, Panels.centreX(i), Panels.centreY(i), Panels.radius());
        }
    }

    //! Semicircle band that is widest at the zenith and one pixel at the horizon ends. With
    //! dither on, every other ring of the band is skipped in a checker pattern so the band
    //! reads as translucent, and one dashed ring in the dimmed colour outside each edge softens
    //! the border. Static, drawn once per page or skin change.
    private function drawTaperedArc(dc as Dc, r as Number, color as Number, maxWidth as Number, dither as Boolean, top as Boolean) as Void {
        var steps = 36;
        var edge = SkinDefs.dimColor(color);
        dc.setPenWidth(1);
        for (var i = 0; i < steps; i++) {
            var a0 = 180.0 * i / steps;
            var a1 = 180.0 * (i + 1) / steps;
            var mid = (a0 + a1) / 2.0 * Math.PI / 180.0;
            var width = 1 + ((maxWidth - 1) * Math.sin(mid)).toNumber();
            var half = width / 2;
            var stride = dither ? 2 : 1;
            for (var off = -half - 1; off <= half + 1; off += 1) {
                var border = (off < -half) || (off > half);
                if (border) {
                    if (i % 2 == 1) {
                        continue;
                    }
                    dc.setColor(edge, Graphics.COLOR_TRANSPARENT);
                } else {
                    if (dither && ((off + half + i) % stride != 0)) {
                        continue;
                    }
                    dc.setColor(color, Graphics.COLOR_TRANSPARENT);
                }
                if (top) {
                    dc.drawArc(_cx, _cy, r + off, Graphics.ARC_CLOCKWISE, 180 - a0, 180 - a1);
                } else {
                    dc.drawArc(_cx, _cy, r + off, Graphics.ARC_COUNTER_CLOCKWISE, 180 + a0, 180 + a1);
                }
            }
        }
    }

    //! Kept for callers that do not know the sky state.
    function drawStaticDefault(dc as Dc, skin as Skin) as Void {
        drawStatic(dc, skin, _night);
    }

    function draw(dc as Dc, skin as Skin, now as Number) as Void {
        var ws = skin.weather();
        var r = arcRadius(skin);
        loadLabels();
        drawSun(dc, skin, r, now);
        drawMoon(dc, skin, r, now);
        if (Settings.getShowSunTimes()) {
            drawSunTimes(dc, skin, r);
        }
        var conditionIcon = (_night && WeatherCache.category == WeatherConditions.CLEAR) ? CLEAR_NIGHT_ICON : WeatherCache.category;
        var iconX = _width * ws.icon.x / 100;
        var iconY = _height * ws.icon.y / 100;
        if (ws.conditionBackground) {
            _backgrounds.drawCentered(dc, conditionIcon, iconX, iconY);
        }
        _conditionIcons.drawCentered(dc, conditionIcon, iconX, iconY);
        if (Settings.getShowMoonPhaseLabel() && SkyState.isUp(now, WeatherCache.moonRise, WeatherCache.moonSet)) {
            dc.setColor(skin.resolveColor(ws.labelColor), Graphics.COLOR_TRANSPARENT);
            drawLabel(dc, ws.phaseLabel, Graphics.FONT_XTINY, WeatherCache.moonPhaseLabel);
        }
        var color = skin.resolveColor(ws.readoutColor);
        var labelColor = skin.resolveColor(ws.labelColor);
        drawPanel(dc, skin, 0, ICON_TEMPERATURE, WeatherCache.temperature, _labels[0], skin.accentColor, labelColor, null);
        drawPanel(dc, skin, 1, ICON_PRECIPITATION, WeatherCache.precipitation, _labels[1], color, labelColor, null);
        drawPanel(dc, skin, 2, ICON_UV, WeatherCache.uv, _labels[2], color, labelColor, null);
        drawPanel(dc, skin, 3, ICON_PRESSURE, WeatherCache.pressure, _labels[3], color, labelColor, null);
        drawPressureTrend(dc, skin);
        registerRegions(dc, skin, r);
    }

    private function loadLabels() as Void {
        if (_labels[0] == null) {
            _labels[0] = WatchUi.loadResource(Rez.Strings.lbl_temperature) as String;
            _labels[1] = WatchUi.loadResource(Rez.Strings.lbl_precipitation) as String;
            _labels[2] = WatchUi.loadResource(Rez.Strings.lbl_uv) as String;
            _labels[3] = WatchUi.loadResource(Rez.Strings.lbl_pressure) as String;
        }
    }

    private function drawPanel(dc as Dc, skin as Skin, index as Number, iconIndex as Number, value as String, label as String?, valueColor as Number, labelColor as Number, percent as Number?) as Void {
        var x = Panels.centreX(index);
        var y = Panels.centreY(index);
        var r = Panels.radius();
        if (percent != null && skin.panels().gauge) {
            Panels.drawGauge(dc, skin, x, y, r, percent, false);
        }
        Panels.drawContent(dc, skin, x, y, r, _icons.get(iconIndex), value, label, valueColor, labelColor, false);
    }

    //! Sunrise on the left and sunset on the right, small icon then time, level with the arc ends.
    private function drawSunTimes(dc as Dc, skin as Skin, r as Number) as Void {
        var ws = skin.weather();
        var font = ws.labelFont;
        var gap = 2;
        dc.setColor(skin.resolveColor(ws.labelColor), Graphics.COLOR_TRANSPARENT);
        var y = _height * ws.sunriseLabel.y / 100;
        var leftX = _width * ws.sunriseLabel.x / 100;
        var rightX = _width * ws.sunsetLabel.x / 100;
        var riseIcon = _icons.get(ICON_SUNRISE);
        var setIcon = _icons.get(ICON_SUNSET);
        var riseWidth = riseIcon.getWidth() + gap + dc.getTextWidthInPixels(WeatherCache.sunriseLabel, font);
        var setWidth = setIcon.getWidth() + gap + dc.getTextWidthInPixels(WeatherCache.sunsetLabel, font);
        var riseStart = leftX - riseWidth / 2;
        var setStart = rightX - setWidth / 2;
        dc.drawBitmap(riseStart, y - riseIcon.getHeight() / 2, riseIcon);
        dc.drawText(riseStart + riseIcon.getWidth() + gap, y, font, WeatherCache.sunriseLabel, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawBitmap(setStart, y - setIcon.getHeight() / 2, setIcon);
        dc.drawText(setStart + setIcon.getWidth() + gap, y, font, WeatherCache.sunsetLabel, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    //! Twelve bars, baseline at the six hour mean, accent above and muted below.
    private function drawPressureTrend(dc as Dc, skin as Skin) as Void {
        if (WeatherCache.pressureBarCount < 2) {
            return;
        }
        var ws = skin.weather();
        var chartWidth = _width * 40 / 100;
        var chartHeight = _height * 8 / 100;
        var left = _cx - chartWidth / 2;
        var baseY = _height * ws.chartY / 100;
        var barWidth = chartWidth / BARS;
        var span = 0.0;
        for (var i = 0; i < BARS; i++) {
            var bar = WeatherCache.pressureBars[i];
            if (bar > 0.0) {
                var delta = (bar - WeatherCache.pressureBaseline).abs();
                if (delta > span) {
                    span = delta;
                }
            }
        }
        if (span < 50.0) {
            span = 50.0;
        }
        dc.setPenWidth(1);
        dc.setColor(skin.resolveColor(ws.labelColor), Graphics.COLOR_TRANSPARENT);
        dc.drawLine(left, baseY, left + chartWidth, baseY);
        for (var i = 0; i < BARS; i++) {
            var bar = WeatherCache.pressureBars[i];
            if (bar <= 0.0) {
                continue;
            }
            var delta = bar - WeatherCache.pressureBaseline;
            var h = ((delta.abs() / span) * (chartHeight / 2)).toNumber();
            if (h < 1) {
                h = 1;
            }
            var x = left + i * barWidth + 1;
            if (delta >= 0.0) {
                dc.setColor(skin.accentColor, Graphics.COLOR_TRANSPARENT);
                dc.fillRectangle(x, baseY - h, barWidth - 2, h);
            } else {
                dc.setColor(skin.resolveColor(ws.labelColor), Graphics.COLOR_TRANSPARENT);
                dc.fillRectangle(x, baseY, barWidth - 2, h);
            }
        }
    }

    //! Press regions: readout panels, sun and moon arcs. The icon sits inside the centre circle.
    function registerRegions(dc as Dc, skin as Skin, r as Number) as Void {
        var weather = ComplicationLaunch.idForType(Complications.COMPLICATION_TYPE_CURRENT_WEATHER);
        var side = Panels.targetSide();
        Regions.register(Regions.WEATHER_TEMPERATURE, Panels.centreX(0), Panels.centreY(0), side, side, weather);
        Regions.register(Regions.WEATHER_PRECIPITATION, Panels.centreX(1), Panels.centreY(1), side, side, weather);
        Regions.register(Regions.WEATHER_UV, Panels.centreX(2), Panels.centreY(2), side, side, weather);
        Regions.register(Regions.WEATHER_PRESSURE, Panels.centreX(3), Panels.centreY(3), side, side, ComplicationLaunch.idForType(Complications.COMPLICATION_TYPE_ALTITUDE));
        var band = Regions.getMinimumSize();
        Regions.register(Regions.WEATHER_SUN_ARC, _cx, _cy - r + band / 4, band, band, weather);
        Regions.register(Regions.WEATHER_MOON_ARC, _cx, _cy + r - band / 4, band, band, ComplicationLaunch.idForType(Complications.COMPLICATION_TYPE_SUNRISE));
    }

    private function drawLabel(dc as Dc, anchor as Anchor, font as Graphics.FontType, text as String) as Void {
        dc.drawText(_width * anchor.x / 100, _height * anchor.y / 100, font, text, anchor.align | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    //! Point on the top (or mirrored bottom) semicircle for a 0..1 progress, left to right.
    private function arcPoint(r as Number, progress as Float, top as Boolean) as Void {
        var angle = Math.PI * (1.0 - progress);
        _point[0] = (_cx + r * Math.cos(angle)).toNumber();
        var dy = (r * Math.sin(angle)).toNumber();
        _point[1] = top ? _cy - dy : _cy + dy;
    }

    //! Sun disc with a two ring dithered glow, only between sunrise and sunset.
    private function drawSun(dc as Dc, skin as Skin, r as Number, now as Number) as Void {
        var progress = SkyState.progress(now, WeatherCache.sunrise, WeatherCache.sunset);
        if (progress == null) {
            return;
        }
        arcPoint(r, progress, true);
        var x = _point[0];
        var y = _point[1];
        var glow = _icons.width(ICON_SUN) / 2;
        dc.setColor(skin.resolveColor(skin.weather().sunColor), Graphics.COLOR_TRANSPARENT);
        for (var ring = 1; ring <= 2; ring++) {
            var rr = glow + 2 * ring + 1;
            for (var step = 0; step < 24; step += ring) {
                var angle = step * Math.PI / 12.0;
                dc.drawPoint(x + rr * Math.cos(angle), y + rr * Math.sin(angle));
            }
        }
        _icons.drawCentered(dc, ICON_SUN, x, y);
    }

    //! Moon disc on the bottom arc while it is above the horizon, larger at night.
    private function drawMoon(dc as Dc, skin as Skin, r as Number, now as Number) as Void {
        var progress = SkyState.progress(now, WeatherCache.moonRise, WeatherCache.moonSet);
        if (progress == null) {
            return;
        }
        arcPoint(r, progress, false);
        var icon = _night ? ICON_MOON_LARGE : ICON_MOON;
        drawMoonDisc(dc, skin, _point[0], _point[1], icon, _icons.width(icon) / 2);
    }

    //! Moon disc with the illuminated fraction drawn procedurally: base bitmap, unlit half,
    //! then an ellipse for the terminator (dark for a crescent, lit for a gibbous moon).
    function drawMoonDisc(dc as Dc, skin as Skin, x as Number, y as Number, icon as Number, radius as Number) as Void {
        var ws = skin.weather();
        var lit = skin.resolveColor(ws.moonLitColor);
        var dark = skin.resolveColor(ws.moonDarkColor);
        var k = WeatherCache.moonIllumination;
        var litOnRight = WeatherCache.moonWaxing;
        _icons.drawCentered(dc, icon, x, y);
        dc.setColor(dark, Graphics.COLOR_TRANSPARENT);
        var side = litOnRight ? -1.0 : 1.0;
        var count = _half.size();
        for (var i = 0; i < count; i++) {
            var angle = Math.PI * i / (count - 1) - Math.PI / 2.0;
            _half[i][0] = (x + side * (radius + 1) * Math.cos(angle)).toNumber();
            _half[i][1] = (y + (radius + 1) * Math.sin(angle)).toNumber();
        }
        dc.fillPolygon(_half as Array<[Numeric, Numeric]>);
        var a = ((1.0 - 2.0 * k).abs() * radius).toNumber();
        if (a > 0) {
            dc.setColor((k < 0.5) ? dark : lit, Graphics.COLOR_TRANSPARENT);
            dc.fillEllipse(x, y, a, radius);
        }
    }
}
