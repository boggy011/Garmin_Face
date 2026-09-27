import Toybox.Graphics;
import Toybox.Lang;

//! Body battery and stress gauges on the arcs, heart rate in the centre, four readouts.
//! Geometry and colours from skin.health, values from HealthCache.
class HealthPageRenderer {
    enum { ICON_STRESS = 0, ICON_BODY_BATTERY = 1, ICON_SPO2 = 2, ICON_HRV = 3, ICON_HEART = 4 }

    private var _width as Number;
    private var _height as Number;
    private var _cx as Number;
    private var _cy as Number;
    private var _icons as IconSet;

    function initialize(width as Number, height as Number) {
        _width = width;
        _height = height;
        _cx = width / 2;
        _cy = height / 2;
        _icons = new IconSet([
            Rez.Drawables.ic_stress, Rez.Drawables.ic_body_battery, Rez.Drawables.ic_spo2, Rez.Drawables.ic_hrv, Rez.Drawables.ic_heart
        ] as Array<ResourceId>);
    }

    function arcRadius(skin as Skin) as Number {
        return _width * skin.health.arcRadius / 100;
    }

    //! Static gauge tracks.
    function drawStatic(dc as Dc, skin as Skin) as Void {
        var hs = skin.health;
        var r = arcRadius(skin);
        dc.setPenWidth(hs.arcWidth);
        dc.setColor(skin.resolveColor(hs.trackColor), Graphics.COLOR_TRANSPARENT);
        dc.drawArc(_cx, _cy, r, Graphics.ARC_CLOCKWISE, 180, 0);
        dc.drawArc(_cx, _cy, r, Graphics.ARC_COUNTER_CLOCKWISE, 180, 360);
        dc.setPenWidth(1);
    }

    function draw(dc as Dc, skin as Skin, health as HealthCache) as Void {
        var hs = skin.health;
        var r = arcRadius(skin);
        var top = Settings.getHealthArcTop();
        var bottom = Settings.getHealthArcBottom();
        drawGauge(dc, skin, r, top, health.gaugeValue(top), true);
        drawGauge(dc, skin, r, bottom, health.gaugeValue(bottom), false);
        _icons.drawCentered(dc, ICON_HEART, _width * hs.heartIcon.x / 100, _height * hs.heartIcon.y / 100);
        dc.setColor(skin.resolveColor(hs.heartRateColor), Graphics.COLOR_TRANSPARENT);
        dc.drawText(_width * hs.heartRate.x / 100, _height * hs.heartRate.y / 100, hs.heartRateFont, health.heartRate, hs.heartRate.align | Graphics.TEXT_JUSTIFY_VCENTER);
        var color = skin.resolveColor(hs.readoutColor);
        Readouts.draw(dc, _icons, ICON_STRESS, hs.readouts[0], health.stress, hs.readoutFont, color, _width, _height);
        Readouts.draw(dc, _icons, ICON_BODY_BATTERY, hs.readouts[1], health.bodyBattery, hs.readoutFont, color, _width, _height);
        Readouts.draw(dc, _icons, ICON_SPO2, hs.readouts[2], health.spo2, hs.readoutFont, color, _width, _height);
        Readouts.draw(dc, _icons, ICON_HRV, hs.readouts[3], health.hrv, hs.readoutFont, color, _width, _height);
    }

    //! A 0..100 gauge along the top or bottom semicircle. Stress uses the skin's colour bands.
    private function drawGauge(dc as Dc, skin as Skin, r as Number, metric as String, value as Number?, top as Boolean) as Void {
        if (value == null) {
            return;
        }
        var hs = skin.health;
        var v = value;
        if (v < 0) {
            v = 0;
        }
        if (v > 100) {
            v = 100;
        }
        dc.setPenWidth(hs.arcWidth);
        if (metric.equals(HealthMetrics.STRESS)) {
            drawSegment(dc, r, 0, minNumber(v, hs.stressLowMax), skin.resolveColor(hs.stressLowColor), top);
            drawSegment(dc, r, hs.stressLowMax, minNumber(v, hs.stressMediumMax), skin.resolveColor(hs.stressMediumColor), top);
            drawSegment(dc, r, hs.stressMediumMax, v, skin.resolveColor(hs.stressHighColor), top);
        } else {
            var color = hs.bodyBatteryColor;
            if (metric.equals(HealthMetrics.SPO2)) {
                color = hs.spo2Color;
            } else if (metric.equals(HealthMetrics.HRV)) {
                color = hs.hrvColor;
            }
            drawSegment(dc, r, 0, v, skin.resolveColor(color), top);
        }
        dc.setPenWidth(1);
    }

    //! Arc segment between two percentages. Top arcs run left to right over the top,
    //! bottom arcs left to right under the bottom.
    private function drawSegment(dc as Dc, r as Number, from as Number, to as Number, color as Number, top as Boolean) as Void {
        if (to <= from) {
            return;
        }
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        var startDegrees = 180 - from * 180 / 100;
        var endDegrees = 180 - to * 180 / 100;
        if (top) {
            dc.drawArc(_cx, _cy, r, Graphics.ARC_CLOCKWISE, startDegrees, endDegrees);
        } else {
            dc.drawArc(_cx, _cy, r, Graphics.ARC_COUNTER_CLOCKWISE, 360 - startDegrees, 360 - endDegrees);
        }
    }

    private function minNumber(a as Number, b as Number) as Number {
        return (a < b) ? a : b;
    }
}
