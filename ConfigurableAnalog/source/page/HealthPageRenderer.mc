import Toybox.Complications;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

//! Centre heart rate panel, four readout panels (stress, body battery, pulse ox, HRV) with
//! thin single colour rim gauges for the percentages, and a discreet six hour chart of the
//! metric chosen in settings. Geometry and colours from skin.health() and skin.panels(),
//! values from HealthCache.
class HealthPageRenderer {
    enum { ICON_STRESS = 0, ICON_BODY_BATTERY = 1, ICON_SPO2 = 2, ICON_HRV = 3, ICON_HEART = 4 }

    private var _width as Number;
    private var _cx as Number;
    private var _cy as Number;
    private var _icons as IconSet;
    private var _labels as Array<String?> = [null, null, null, null, null] as Array<String?>;
    private var _chartLabel as String? = null;
    private var _chartLabelMetric as String = "";

    function initialize(width as Number, height as Number) {
        _width = width;
        _cx = width / 2;
        _cy = height / 2;
        _icons = new IconSet([
            Rez.Drawables.ic_stress, Rez.Drawables.ic_body_battery, Rez.Drawables.ic_spo2, Rez.Drawables.ic_hrv, Rez.Drawables.ic_heart
        ] as Array<ResourceId>);
    }

    //! Static layer: panel frames only. The dial ring is the page's single circle.
    function drawStatic(dc as Dc, skin as Skin) as Void {
        dc.setPenWidth(1);
        Panels.drawFrame(dc, skin, _cx, _cy, Panels.centreRadius());
        for (var i = 0; i < Panels.OUTER_COUNT; i++) {
            Panels.drawFrame(dc, skin, Panels.centreX(i), Panels.centreY(i), Panels.radius());
        }
    }

    function draw(dc as Dc, skin as Skin, health as HealthCache) as Void {
        var hs = skin.health();
        loadLabels();
        var color = skin.resolveColor(hs.readoutColor);
        var labelColor = skin.resolveColor(skin.slotLabelColor);
        Panels.drawContent(dc, skin, _cx, _cy, Panels.centreRadius(), _icons.get(ICON_HEART), health.heartRate, _labels[4], skin.resolveColor(hs.heartRateColor), labelColor, true);
        drawPanel(dc, skin, 0, ICON_STRESS, health.stress, _labels[0], color, labelColor, health.stressValue);
        drawPanel(dc, skin, 1, ICON_BODY_BATTERY, health.bodyBattery, _labels[1], color, labelColor, health.bodyBatteryValue);
        drawPanel(dc, skin, 2, ICON_SPO2, health.spo2, _labels[2], color, labelColor, health.spo2Value);
        drawPanel(dc, skin, 3, ICON_HRV, health.hrv, _labels[3], color, labelColor, null);
        drawChart(dc, skin, health);
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

    //! Panel with a thin single colour gauge on its rim for percentages.
    private function drawPanel(dc as Dc, skin as Skin, index as Number, iconIndex as Number, value as String, label as String?, valueColor as Number, labelColor as Number, percent as Number?) as Void {
        var x = Panels.centreX(index);
        var y = Panels.centreY(index);
        var r = Panels.radius();
        if (percent != null && skin.panels().gauge) {
            var v = (percent < 0) ? 0 : ((percent > 100) ? 100 : percent);
            dc.setPenWidth(2);
            Panels.drawGaugeSegment(dc, x, y, r, 0, v, skin.resolveColor(skin.health().gaugeColor));
            dc.setPenWidth(1);
        }
        Panels.drawContent(dc, skin, x, y, r, _icons.get(iconIndex), value, label, valueColor, labelColor, false);
    }

    //! Six hour trend of the metric chosen in settings: half hour bars in dark grey scaled
    //! between the lowest and highest value, the newest bar lighter, a short label above.
    private function drawChart(dc as Dc, skin as Skin, health as HealthCache) as Void {
        if (health.chartCount < 2) {
            return;
        }
        var hs = skin.health();
        var bars = health.chartBars;
        var count = bars.size();
        var low = 0;
        var high = 0;
        var newest = -1;
        for (var i = 0; i < count; i++) {
            var v = bars[i];
            if (v > 0) {
                low = (low == 0 || v < low) ? v : low;
                high = (v > high) ? v : high;
                newest = i;
            }
        }
        var span = high - low;
        var floor = low - ((span < 10) ? (10 - span) : span / 4);
        var chartWidth = _width * 40 / 100;
        var chartHeight = _width * 7 / 100;
        var left = _cx - chartWidth / 2;
        var baseY = _width * hs.chartY / 100 + chartHeight / 2;
        var barWidth = chartWidth / count;
        for (var i = 0; i < count; i++) {
            var v = bars[i];
            if (v <= 0) {
                continue;
            }
            var h = (chartHeight * (v - floor) / (high - floor + 1));
            h = (h < 1) ? 1 : h;
            dc.setColor(skin.resolveColor((i == newest) ? hs.chartLatestColor : hs.chartColor), Graphics.COLOR_TRANSPARENT);
            dc.fillRectangle(left + i * barWidth + 1, baseY - h, barWidth - 2, h);
        }
        dc.setColor(skin.resolveColor(hs.chartColor), Graphics.COLOR_TRANSPARENT);
        dc.drawLine(left, baseY, left + chartWidth, baseY);
        var label = chartLabel(health.chartMetric);
        if (label != null) {
            dc.setColor(skin.resolveColor(skin.slotLabelColor), Graphics.COLOR_TRANSPARENT);
            dc.drawText(_cx, _width * hs.chartLabelY / 100, skin.panels().labelFont, label, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }

    private function chartLabel(metric as String) as String? {
        if (!metric.equals(_chartLabelMetric)) {
            _chartLabelMetric = metric;
            var id = Rez.Strings.chart_bodyBattery;
            if (metric.equals(HealthMetrics.STRESS)) {
                id = Rez.Strings.chart_stress;
            } else if (metric.equals(HealthMetrics.SPO2)) {
                id = Rez.Strings.chart_spo2;
            } else if (metric.equals(HealthMetrics.HEART_RATE)) {
                id = Rez.Strings.chart_heartRate;
            }
            _chartLabel = WatchUi.loadResource(id) as String;
        }
        return _chartLabel;
    }

    //! Press regions on the four panels. The heart rate panel is the centre cycling region.
    function registerRegions(health as HealthCache) as Void {
        var size = Panels.targetSide();
        Regions.register(Regions.HEALTH_STRESS, Panels.centreX(0), Panels.centreY(0), size, size, ComplicationLaunch.idForType(Complications.COMPLICATION_TYPE_STRESS));
        Regions.register(Regions.HEALTH_BODY_BATTERY, Panels.centreX(1), Panels.centreY(1), size, size, ComplicationLaunch.idForType(Complications.COMPLICATION_TYPE_BODY_BATTERY));
        Regions.register(Regions.HEALTH_SPO2, Panels.centreX(2), Panels.centreY(2), size, size, ComplicationLaunch.idForType(Complications.COMPLICATION_TYPE_PULSE_OX));
        Regions.register(Regions.HEALTH_HRV, Panels.centreX(3), Panels.centreY(3), size, size, health.getHrvComplicationId());
    }
}
