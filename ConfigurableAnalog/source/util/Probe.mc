import Toybox.Lang;
import Toybox.System;

//! Simulator probe, compiled only through probe.jungle: cycles pages automatically every
//! few seconds and prints used and peak memory per page type so the numbers can be read
//! from the monkeydo output. The default monkey.jungle excludes this annotation.
(:probe)
module Probe {
    const CYCLE_SECONDS = 10;
    var _lastCycle as Number = 0;
    var _peak as Number = 0;

    function onFrame(view as FaceView, now as Number) as Void {
        var stats = System.getSystemStats();
        if (stats.usedMemory > _peak) {
            _peak = stats.usedMemory;
        }
        if (_lastCycle == 0) {
            _lastCycle = now;
        }
        if (now - _lastCycle >= CYCLE_SECONDS) {
            System.println("probe: page type " + view.getCurrentPageType() + " used " + stats.usedMemory + " peak " + _peak + " total " + stats.totalMemory);
            _lastCycle = now;
            view.nextPage();
        }
    }
}

//! No-op twin for normal builds.
(:noprobe)
module Probe {
    function onFrame(view as FaceView, now as Number) as Void {
    }
}
