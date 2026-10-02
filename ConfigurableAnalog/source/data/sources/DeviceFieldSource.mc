import Toybox.ActivityMonitor;
import Toybox.Lang;
import Toybox.System;

//! Slot sources read from the device itself: battery days left and step goal progress.
//! One class, the kind picks the field.
class DeviceFieldSource extends DataSource {
    enum { KIND_BATTERY_DAYS = 0, KIND_STEP_GOAL = 1 }

    private var _id as String;
    private var _kind as Number;

    function initialize(id as String, labelRez as ResourceId, shortRez as ResourceId, iconRez as ResourceId?, kind as Number) {
        DataSource.initialize(labelRez, shortRez, iconRez);
        _id = id;
        _kind = kind;
    }

    function getId() as String {
        return _id;
    }

    function isSupported() as Boolean {
        return (_kind == KIND_BATTERY_DAYS) ? (System.Stats has :batteryInDays) : true;
    }

    //! Steps as a percentage of the daily goal, uncapped, or null without a goal.
    private function goalPercent() as Number? {
        var info = ActivityMonitor.getInfo();
        var steps = info.steps;
        var goal = info.stepGoal;
        if (steps == null || goal == null || goal <= 0) {
            return null;
        }
        return (steps as Number) * 100 / (goal as Number);
    }

    function getPercent() as Number? {
        if (_kind != KIND_STEP_GOAL) {
            return null;
        }
        var percent = goalPercent();
        return (percent != null && percent > 100) ? 100 : percent;
    }

    function getValue() as String {
        if (_kind == KIND_BATTERY_DAYS) {
            var days = System.getSystemStats().batteryInDays as Float?;
            if (days == null) {
                return Sources.PLACEHOLDER;
            }
            var whole = days.toNumber() as Number;
            return whole.toString() + "D";
        }
        var percent = goalPercent();
        return (percent == null) ? Sources.PLACEHOLDER : percent.toString() + "%";
    }
}
