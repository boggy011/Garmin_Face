import Toybox.Activity;
import Toybox.ActivityMonitor;
import Toybox.Complications;
import Toybox.Lang;
import Toybox.SensorHistory;
import Toybox.System;
import Toybox.WatchUi;

//! Heart rate, stress, body battery, pulse ox and HRV for the health page. Refreshed once
//! per minute from onUpdate. HRV comes from a system complication when the device offers
//! one, found at runtime by label because the SDK has no dedicated HRV complication type.
//! Health metric ids, matching the healthArcTop/healthArcBottom options in tools/sources.yaml.
module HealthMetrics {
    const BODY_BATTERY = "bodyBattery";
    const STRESS = "stress";
    const SPO2 = "spo2";
    const HRV = "hrv";
}

class HealthCache {

    var heartRate as String = Sources.PLACEHOLDER;
    var stress as String = Sources.PLACEHOLDER;
    var bodyBattery as String = Sources.PLACEHOLDER;
    var spo2 as String = Sources.PLACEHOLDER;
    var hrv as String = Sources.PLACEHOLDER;
    var stressValue as Number?;
    var bodyBatteryValue as Number?;
    var spo2Value as Number?;
    var hrvValue as Number?;

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
        return true;
    }

    function refresh() as Void {
        heartRate = Sources.formatNumber(readHeartRate());
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

    //! Numeric value of a metric id for the arc gauges, null when unavailable.
    function gaugeValue(metric as String) as Number? {
        if (metric.equals(HealthMetrics.BODY_BATTERY)) {
            return bodyBatteryValue;
        }
        if (metric.equals(HealthMetrics.STRESS)) {
            return stressValue;
        }
        if (metric.equals(HealthMetrics.SPO2)) {
            return spo2Value;
        }
        if (metric.equals(HealthMetrics.HRV)) {
            return hrvValue;
        }
        return null;
    }

    private function readHeartRate() as Number? {
        var rate = Activity.getActivityInfo().currentHeartRate;
        if (rate == null && (ActivityMonitor has :getHeartRateHistory)) {
            var sample = ActivityMonitor.getHeartRateHistory(1, true).next();
            if (sample != null && sample.heartRate != ActivityMonitor.INVALID_HR_SAMPLE) {
                rate = sample.heartRate;
            }
        }
        return rate;
    }

    //! Newest SensorHistory sample of a metric as an integer, gated with has checks.
    private function latestSample(metric as String) as Number? {
        if (!(Toybox has :SensorHistory)) {
            return null;
        }
        var iterator = null as SensorHistory.SensorHistoryIterator?;
        var options = {:period => 1, :order => SensorHistory.ORDER_NEWEST_FIRST};
        if (metric.equals(HealthMetrics.STRESS) && (SensorHistory has :getStressHistory)) {
            iterator = SensorHistory.getStressHistory(options);
        } else if (metric.equals(HealthMetrics.BODY_BATTERY) && (SensorHistory has :getBodyBatteryHistory)) {
            iterator = SensorHistory.getBodyBatteryHistory(options);
        } else if (metric.equals(HealthMetrics.SPO2) && (SensorHistory has :getOxygenSaturationHistory)) {
            iterator = SensorHistory.getOxygenSaturationHistory(options);
        }
        if (iterator == null) {
            return null;
        }
        var sample = iterator.next();
        if (sample == null) {
            return null;
        }
        var data = sample.data;
        if (data == null) {
            return null;
        }
        return data.toNumber();
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
