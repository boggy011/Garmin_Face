import Toybox.Complications;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

//! Centre heart rate panel, four readout panels (stress, body battery, pulse ox, HRV) with
//! rim gauges for the percentages, plus the two arc gauges from settings. Geometry and
//! colours from skin.health() and skin.panels, values from HealthCache.
class HealthPageRenderer {
    enum { ICON_STRESS = 0, ICON_BODY_BATTERY = 1, ICON_SPO2 = 2, ICON_HRV = 3, ICON_HEART = 4 }

    private var _width as Number;
    private var _cx as Number;
    private var _cy as Number;
    private var _icons as IconSet;
    private var _labels as Array<String?> = [null, null, null, null, null] as Array<String?>;

    function initialize(width as Number, height as Number) {
        _width = width;
        _cx = width / 2;
        _cy = height / 2;
        _icons = new IconSet([
            Rez.Drawables.ic_stress, Rez.Drawables.ic_body_battery, Rez.Drawables.ic_spo2, Rez.Drawables.ic_hrv, Rez.Drawables.ic_heart
        ] as Array<ResourceId>);
    }

    function arcRadius(skin as Skin) as Number {
        return _width * skin.health().arcRadius / 100;
    }

    //! Static gauge tracks and panel frames.
    function drawStatic(dc as Dc, skin as Skin) as Void {
        var hs = skin.health();
        var r = arcRadius(skin);
        dc.setPenWidth(hs.arcWidth);
        dc.setColor(skin.resolveColor(hs.trackColor), Graphics.COLOR_TRANSPARENT);
        dc.drawArc(_cx, _cy, r, Graphics.ARC_CLOCKWISE, 180, 0);
        dc.drawArc(_cx, _cy, r, Graphics.ARC_COUNTER_CLOCKWISE, 180, 360);
        dc.setPenWidth(1);
        Panels.drawFrame(dc, skin, _cx, _cy, Panels.centreRadius());
        for (var i = 0; i < Panels.OUTER_COUNT; i++) {
            Panels.drawFrame(dc, skin, Panels.centreX(i), Panels.centreY(i), Panels.radius());
        }
    }

    function draw(dc as Dc, skin as Skin, health as HealthCache) as Void {
        var hs = skin.health();
        var r = arcRadius(skin);
        loadLabels();
        var top = Settings.getHealthArcTop();
        var bottom = Settings.getHealthArcBottom();
        drawGauge(dc, skin, r, top, health.gaugeValue(top), true);
        drawGauge(dc, skin, r, bottom, health.gaugeValue(bottom), false);
        var color = skin.resolveColor(hs.readoutColor);
        var labelColor = skin.resolveColor(skin.slotLabelColor);
        Panels.drawContent(dc, skin, _cx, _cy, Panels.centreRadius(), _icons.get(ICON_HEART), health.heartRate, _labels[4], skin.resolveColor(hs.heartRateColor), labelColor, true);
        drawPanel(dc, skin, 0, ICON_STRESS, health.stress, _labels[0], color, labelColor, health.stressValue);
        drawPanel(dc, skin, 1, ICON_BODY_BATTERY, health.bodyBattery, _labels[1], color, labelColor, health.bodyBatteryValue);
        drawPanel(dc, skin, 2, ICON_SPO2, health.spo2, _labels[2], color, labelColor, health.spo2Value);
        drawPanel(dc, skin, 3, ICON_HRV, health.hrv, _labels[3], color, labelColor, null);
        registerRegions(health);
    }

    private function loadLabels() as Void {
        if (_labels[0] == null) {
            _labels[0] = WatchUi.loadResource(Rez.Strings.lbl_stress) as String;
            _labels[1] = WatchUi.loadResource(Rez.Strings.lbl_body_battery) as String;
            _labels[2] = WatchUi.loadResource(Rez.Strings.lbl_spo2) as String;
            _labels[3] = WatchUi.loadResource(Rez.Strings.lbl_hrv) as String;
            _labels[4] = WatchUi.loadResource(Rez.Strings.lbl_bpm) as String;
        }
    }

    private function drawPanel(dc as Dc, skin as Skin, index as Number, iconIndex as Number, value as String, label as String?, valueColor as Number, labelColor as Number, percent as Number?) as Void {
        var x = Panels.centreX(index);
        var y = Panels.centreY(index);
        var r = Panels.radius();
        if (percent != null && skin.panels.gauge) {
            Panels.drawGauge(dc, skin, x, y, r, percent, index == 0);
        }
        Panels.drawContent(dc, skin, x, y, r, _icons.get(iconIndex), value, label, valueColor, labelColor, false);
    }

    //! Press regions on the four panels. The heart rate panel is the centre cycling region.
    function registerRegions(health as HealthCache) as Void {
        var size = Panels.targetSide();
        Regions.register(Regions.HEALTH_STRESS, Panels.centreX(0), Panels.centreY(0), size, size, ComplicationLaunch.idForType(Complications.COMPLICATION_TYPE_STRESS));
        Regions.register(Regions.HEALTH_BODY_BATTERY, Panels.centreX(1), Panels.centreY(1), size, size, ComplicationLaunch.idForType(Complications.COMPLICATION_TYPE_BODY_BATTERY));
        Regions.register(Regions.HEALTH_SPO2, Panels.centreX(2), Panels.centreY(2), size, size, ComplicationLaunch.idForType(Complications.COMPLICATION_TYPE_PULSE_OX));
        Regions.register(Regions.HEALTH_HRV, Panels.centreX(3), Panels.centreY(3), size, size, health.getHrvComplicationId());
    }

    //! A 0..100 gauge along the top or bottom semicircle. Stress uses the skin's colour bands.
    private function drawGauge(dc as Dc, skin as Skin, r as Number, metric as String, value as Number?, top as Boolean) as Void {
        if (value == null) {
            return;
        }
        var hs = skin.health();
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
