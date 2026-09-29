import Toybox.ActivityMonitor;
import Toybox.Complications;
import Toybox.Lang;
import Toybox.SensorHistory;
import Toybox.System;
import Toybox.Time;
import Toybox.WatchUi;

//! Heart rate, stress, body battery, pulse ox and HRV for the health page. Refreshed once
//! per minute from onUpdate. Sensor history is walked back from the newest sample to the
//! newest one that carries a value, because on a real watch the latest stress or body
//! battery sample is often empty (not measured while moving) and pulse ox only measures a
//! few times a day. HRV comes from a system complication when the device offers one,
//! found at runtime by label because the SDK has no dedicated HRV complication type.
//! Health metric ids, matching the healthArcTop/healthArcBottom options in tools/sources.yaml.
module HealthMetrics {
    const BODY_BATTERY = "bodyBattery";
    const STRESS = "stress";
    const SPO2 = "spo2";
    const HRV = "hrv";
    const HEART_RATE = "heartRate";
}

class HealthCache {
    const SPO2_WINDOW_SECONDS = 12 * 3600;
    const CHART_BARS = 12;
    const CHART_WINDOW_SECONDS = 6 * 3600;
    const CHART_REFRESH_MINUTES = 10;

    var heartRate as String = Sources.PLACEHOLDER;
    var stress as String = Sources.PLACEHOLDER;
    var bodyBattery as String = Sources.PLACEHOLDER;
    var spo2 as String = Sources.PLACEHOLDER;
    var hrv as String = Sources.PLACEHOLDER;
    var stressValue as Number?;
    var bodyBatteryValue as Number?;
    var spo2Value as Number?;
    var hrvValue as Number?;
    //! Six hour chart of the metric chosen in settings, one bar per half hour, oldest first.
    //! Zero means no sample in that half hour.
    var chartBars as Array<Number> = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0] as Array<Number>;
    var chartCount as Number = 0;
    var chartMetric as String = "";
    private var _chartSums as Array<Number> = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0] as Array<Number>;
    private var _chartCounts as Array<Number> = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0] as Array<Number>;
    private var _chartMinute as Number = -1;

    private var _lastMinute as Number = -1;
    private var _hrvId as Complications.Id?;
    private var _hrvLogged as Boolean = false;

    function initialize() {
        findHrvComplication();
    }

    //! Refresh once per wall clock minute. Returns true when refreshed.
    function refreshIfDue(now as Number) as Boolean {
        var minute = now / 60;
        if (minute == _lastMinute) {
            return false;
        }
        _lastMinute = minute;
        refresh();
        var metric = Settings.getHealthChart();
        if (_chartMinute < 0 || minute - _chartMinute >= CHART_REFRESH_MINUTES || !metric.equals(chartMetric)) {
            _chartMinute = minute;
            refreshChart(metric, now);
        }
        return true;
    }

    function refresh() as Void {
        heartRate = Sources.formatNumber(Sources.latestHeartRate());
        stressValue = latestSample(HealthMetrics.STRESS);
        bodyBatteryValue = latestSample(HealthMetrics.BODY_BATTERY);
        spo2Value = latestSample(HealthMetrics.SPO2);
        stress = Sources.formatNumber(stressValue);
        bodyBattery = Sources.formatNumber(bodyBatteryValue);
        spo2 = Sources.formatNumber(spo2Value);
        hrv = Sources.formatNumber(hrvValue);
    }

    //! Id of the HRV complication found at startup, for launch regions. Null when absent.
    function getHrvComplicationId() as Complications.Id? {
        return _hrvId;
    }

    //! Bucket the last six hours of the chosen metric into half hour averages.
    function refreshChart(metric as String, now as Number) as Void {
        chartMetric = metric;
        chartCount = 0;
        for (var i = 0; i < CHART_BARS; i++) {
            chartBars[i] = 0;
            _chartSums[i] = 0;
            _chartCounts[i] = 0;
        }
        if (metric.equals(HealthMetrics.HEART_RATE)) {
            collectHeartRate(now);
        } else {
            collectHistory(historyIterator(metric, CHART_WINDOW_SECONDS), now);
        }
        for (var i = 0; i < CHART_BARS; i++) {
            if (_chartCounts[i] > 0) {
                chartBars[i] = _chartSums[i] / _chartCounts[i];
                chartCount += 1;
            }
        }
    }

    private function addChartSample(value as Number, when as Number, now as Number) as Void {
        var age = now - when;
        if (value <= 0 || age < 0 || age >= CHART_WINDOW_SECONDS) {
            return;
        }
        var bucket = CHART_BARS - 1 - age / (CHART_WINDOW_SECONDS / CHART_BARS);
        _chartSums[bucket] += value;
        _chartCounts[bucket] += 1;
    }

    private function collectHistory(iterator as SensorHistory.SensorHistoryIterator?, now as Number) as Void {
        if (iterator == null) {
            return;
        }
        var sample = iterator.next();
        while (sample != null) {
            var data = sample.data;
            var when = sample.when;
            if (data != null && when != null) {
                addChartSample(data.toNumber(), when.value(), now);
            }
            sample = iterator.next();
        }
    }

    private function collectHeartRate(now as Number) as Void {
        if (!(ActivityMonitor has :getHeartRateHistory)) {
            return;
        }
        var iterator = ActivityMonitor.getHeartRateHistory(new Time.Duration(CHART_WINDOW_SECONDS), true);
        var sample = iterator.next();
        while (sample != null) {
            var rate = sample.heartRate;
            var when = sample.when;
            if (rate != null && rate != ActivityMonitor.INVALID_HR_SAMPLE && when != null) {
                addChartSample(rate, when.value(), now);
            }
            sample = iterator.next();
        }
    }

    //! SensorHistory iterator for a metric over a window, null when the device lacks it.
    private function historyIterator(metric as String, seconds as Number) as SensorHistory.SensorHistoryIterator? {
        if (!(Toybox has :SensorHistory)) {
            return null;
        }
        var options = {:period => new Time.Duration(seconds), :order => SensorHistory.ORDER_NEWEST_FIRST};
        if (metric.equals(HealthMetrics.STRESS) && (SensorHistory has :getStressHistory)) {
            return SensorHistory.getStressHistory(options);
        }
        if (metric.equals(HealthMetrics.BODY_BATTERY) && (SensorHistory has :getBodyBatteryHistory)) {
            return SensorHistory.getBodyBatteryHistory(options);
        }
        if (metric.equals(HealthMetrics.SPO2) && (SensorHistory has :getOxygenSaturationHistory)) {
            return SensorHistory.getOxygenSaturationHistory(options);
        }
        return null;
    }

    //! Newest SensorHistory sample of a metric that carries a value, gated with has checks.
    private function latestSample(metric as String) as Number? {
        var seconds = metric.equals(HealthMetrics.SPO2) ? SPO2_WINDOW_SECONDS : Sources.HISTORY_WINDOW_SECONDS;
        return Sources.latestHistoryValue(historyIterator(metric, seconds), Sources.HISTORY_MAX_SAMPLES);
    }

    //! Look for a complication labelled HRV and subscribe to it, else log once.
    private function findHrvComplication() as Void {
        if (!(Toybox has :Complications) || !(Complications has :getComplications)) {
            logMissingHrv();
            return;
        }
        try {
            var iterator = Complications.getComplications();
            var complication = iterator.next();
            while (complication != null) {
                if (isHrv(complication)) {
                    _hrvId = complication.complicationId;
                    break;
                }
                complication = iterator.next();
            }
        } catch (e) {
            _hrvId = null;
        }
        var id = _hrvId;
        if (id == null) {
            logMissingHrv();
            return;
        }
        try {
            Complications.subscribeToUpdates(id);
            Complications.registerComplicationChangeCallback(method(:onComplicationChanged));
            readHrv(id);
        } catch (e) {
            _hrvId = null;
            logMissingHrv();
        }
    }

    private function isHrv(complication as Complications.Complication) as Boolean {
        var labels = [complication.longLabel, complication.shortLabel] as Array<String?>;
        for (var i = 0; i < labels.size(); i++) {
            var label = labels[i];
            if (label != null && label.toUpper().find("HRV") != null) {
                return true;
            }
        }
        return false;
    }

    private function logMissingHrv() as Void {
        if (!_hrvLogged) {
            System.println("HealthCache: no HRV complication on this device, showing a dash");
            _hrvLogged = true;
        }
    }

    function onComplicationChanged(id as Complications.Id) as Void {
        var hrvId = _hrvId;
        if (hrvId != null && id.equals(hrvId)) {
            readHrv(id);
            hrv = Sources.formatNumber(hrvValue);
            WatchUi.requestUpdate();
        }
    }

    private function readHrv(id as Complications.Id) as Void {
        var value = Complications.getComplication(id).value;
        if (value instanceof Number) {
            hrvValue = value;
        } else if (value instanceof Float) {
            hrvValue = value.toNumber();
        } else {
            hrvValue = null;
        }
    }
}
