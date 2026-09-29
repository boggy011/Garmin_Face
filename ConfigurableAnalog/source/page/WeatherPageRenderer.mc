import Toybox.Complications;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

//! Condition icon between the 12 numeral and the centre, moon phase below the centre with
//! its name, sunrise and sunset labels, four readout panels, pressure trend chart and a
//! star field at night. Geometry and colours come from skin.weather() and skin.panels(),
//! values from WeatherCache. Per frame drawing allocates nothing.
class WeatherPageRenderer {
    enum { ICON_TEMPERATURE = 0, ICON_PRECIPITATION = 1, ICON_UV = 2, ICON_PRESSURE = 3, ICON_SUNRISE = 4, ICON_SUNSET = 5 }
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
    private var _starX as Array<Number>;
    private var _starY as Array<Number>;
    private var _labels as Array<String?> = [null, null, null, null] as Array<String?>;
    private var _night as Boolean = false;

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
            Rez.Drawables.icon_sunrise, Rez.Drawables.icon_sunset
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

    function isNight(now as Number) as Boolean {
        return !SkyState.isUp(now, WeatherCache.sunrise, WeatherCache.sunset);
    }

    //! Static layer: star field at night and the panel frames.
    function drawStatic(dc as Dc, skin as Skin, night as Boolean) as Void {
        var ws = skin.weather();
        _night = night;
        if (night) {
            dc.setColor(skin.resolveColor(ws.labelColor), Graphics.COLOR_TRANSPARENT);
            for (var i = 0; i < STARS; i++) {
                dc.drawPoint(_starX[i], _starY[i]);
            }
        }
        dc.setPenWidth(1);
        for (var i = 0; i < Panels.OUTER_COUNT; i++) {
            Panels.drawFrame(dc, skin, Panels.centreX(i), Panels.centreY(i), Panels.radius());
        }
    }

    function draw(dc as Dc, skin as Skin, now as Number) as Void {
        var ws = skin.weather();
        loadLabels();
        drawCondition(dc, ws);
        drawMoon(dc, skin, ws);
        if (Settings.getShowSunTimes()) {
            drawSunTimes(dc, skin, ws);
        }
        var color = skin.resolveColor(ws.readoutColor);
        var labelColor = skin.resolveColor(ws.labelColor);
        drawPanel(dc, skin, 0, ICON_TEMPERATURE, WeatherCache.temperature, _labels[0], skin.accentColor, labelColor);
        drawPanel(dc, skin, 1, ICON_PRECIPITATION, WeatherCache.precipitation, _labels[1], color, labelColor);
        drawPanel(dc, skin, 2, ICON_UV, WeatherCache.uv, _labels[2], color, labelColor);
        drawPanel(dc, skin, 3, ICON_PRESSURE, WeatherCache.pressure, _labels[3], color, labelColor);
        drawPressureTrend(dc, skin);
        registerRegions(ws);
    }

    private function loadLabels() as Void {
        if (_labels[0] == null) {
            _labels[0] = WatchUi.loadResource(Rez.Strings.lbl_temperature) as String;
            _labels[1] = WatchUi.loadResource(Rez.Strings.lbl_precipitation) as String;
            _labels[2] = WatchUi.loadResource(Rez.Strings.lbl_uv) as String;
            _labels[3] = WatchUi.loadResource(Rez.Strings.lbl_pressure) as String;
        }
    }

    //! Condition icon on the top half, over a stylised sky disc where the skin asks for one
    //! on this display type. Clear skies at night use the moon icon.
    private function drawCondition(dc as Dc, ws as WeatherSkin) as Void {
        var index = (_night && WeatherCache.category == WeatherConditions.CLEAR) ? CLEAR_NIGHT_ICON : WeatherCache.category;
        var x = _width * ws.icon.x / 100;
        var y = _height * ws.icon.y / 100;
        if (ws.conditionBackground) {
            _backgrounds.drawCentered(dc, index, x, y);
        }
        _conditionIcons.drawCentered(dc, index, x, y);
    }

    //! Moon phase disc with its name below, from the cached astronomy.
    private function drawMoon(dc as Dc, skin as Skin, ws as WeatherSkin) as Void {
        var x = _width * ws.moon.x / 100;
        var y = _height * ws.moon.y / 100;
        var radius = _width * ws.moonDiameter / 200;
        MoonPhase.draw(dc, x, y, radius, WeatherCache.moonIllumination, WeatherCache.moonWaxing, skin.resolveColor(ws.moonLitColor), skin.resolveColor(ws.moonDarkColor), skin.resolveColor(ws.moonOutlineColor), skin.resolveColor(ws.moonCraterColor));
        if (Settings.getShowMoonPhaseLabel()) {
            dc.setColor(skin.resolveColor(ws.labelColor), Graphics.COLOR_TRANSPARENT);
            drawLabel(dc, ws.phaseLabel, ws.labelFont, WeatherCache.moonPhaseLabel);
        }
    }

    private function drawPanel(dc as Dc, skin as Skin, index as Number, iconIndex as Number, value as String, label as String?, valueColor as Number, labelColor as Number) as Void {
        Panels.drawContent(dc, skin, Panels.centreX(index), Panels.centreY(index), Panels.radius(), _icons.get(iconIndex), value, label, valueColor, labelColor, false);
    }

    //! Sunrise on the left and sunset on the right, small icon then time.
    private function drawSunTimes(dc as Dc, skin as Skin, ws as WeatherSkin) as Void {
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

    //! Press regions: the readout panels open the weather app, the sunrise and sunset labels
    //! open the sunrise and sunset app. The condition icon and the moon sit too close to the
    //! centre cycling circle for targets of their own.
    function registerRegions(ws as WeatherSkin) as Void {
        var weather = ComplicationLaunch.idForType(Complications.COMPLICATION_TYPE_CURRENT_WEATHER);
        var side = Panels.targetSide();
        Regions.register(Regions.WEATHER_TEMPERATURE, Panels.centreX(0), Panels.centreY(0), side, side, weather);
        Regions.register(Regions.WEATHER_PRECIPITATION, Panels.centreX(1), Panels.centreY(1), side, side, weather);
        Regions.register(Regions.WEATHER_UV, Panels.centreX(2), Panels.centreY(2), side, side, weather);
        Regions.register(Regions.WEATHER_PRESSURE, Panels.centreX(3), Panels.centreY(3), side, side, ComplicationLaunch.idForType(Complications.COMPLICATION_TYPE_ALTITUDE));
        if (Settings.getShowSunTimes()) {
            var sun = ComplicationLaunch.idForType(Complications.COMPLICATION_TYPE_SUNRISE);
            var band = Regions.getMinimumSize();
            Regions.register(Regions.WEATHER_SUNRISE, _width * ws.sunriseLabel.x / 100, _height * ws.sunriseLabel.y / 100, band, band, sun);
            Regions.register(Regions.WEATHER_SUNSET, _width * ws.sunsetLabel.x / 100, _height * ws.sunsetLabel.y / 100, band, band, sun);
        }
    }

    private function drawLabel(dc as Dc, anchor as Anchor, font as Graphics.FontType, text as String) as Void {
        dc.drawText(_width * anchor.x / 100, _height * anchor.y / 100, font, text, anchor.align | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}
