import Toybox.Lang;
import Toybox.System;

//! Simulator probe, compiled only through probe.jungle. Walks every skin through the generic
//! page, the weather page by day and by night, and the health page, then forces weather
//! conditions on the weather page and prints frame times. Memory is printed at every step.
//! The default monkey.jungle excludes this annotation.
(:probe)
module Probe {
    const CYCLE_SECONDS = 8;
    const STEP_GENERIC = 0;
    const STEP_WEATHER_DAY = 1;
    const STEP_WEATHER_NIGHT = 2;
    const STEP_HEALTH = 3;
    const STEPS_PER_SKIN = 4;

    var _lastCycle as Number = 0;
    var _peak as Number = 0;
    var _step as Number = -1;
    var _conditions as Array<Number> = [
        WeatherConditions.RAIN, WeatherConditions.HEAVY_RAIN, WeatherConditions.SNOW,
        WeatherConditions.THUNDER, WeatherConditions.FOG, WeatherConditions.WIND
    ] as Array<Number>;

    //! Memory mark for tracing allocation heavy paths.
    function mark(tag as String) as Void {
        System.println("mark: " + tag + " used " + System.getSystemStats().usedMemory);
    }

    function onFrame(view as FaceView, now as Number) as Void {
        var stats = System.getSystemStats();
        if (stats.usedMemory > _peak) {
            _peak = stats.usedMemory;
        }
        if (_step >= 0 && now - _lastCycle < CYCLE_SECONDS) {
            return;
        }
        _lastCycle = now;
        _step += 1;
        var skinSteps = SettingsKeys.SKIN_IDS.size() * STEPS_PER_SKIN;
        if (_step < skinSteps) {
            var skinIndex = _step / STEPS_PER_SKIN;
            var phase = _step % STEPS_PER_SKIN;
            if (phase == STEP_GENERIC) {
                view.applySkinIndex(skinIndex);
                view.jumpToPageType(PageTypes.GENERIC);
            } else if (phase == STEP_WEATHER_DAY) {
                view.jumpToPageType(PageTypes.WEATHER);
                WeatherCache.forceSky(now, true);
            } else if (phase == STEP_WEATHER_NIGHT) {
                WeatherCache.forceSky(now, false);
            } else {
                view.jumpToPageType(PageTypes.HEALTH);
            }
            System.println("probe: skin " + SettingsKeys.SKIN_IDS[skinIndex] + " step " + phase + " page type " + view.getCurrentPageType() + " used " + stats.usedMemory + " peak " + _peak + " total " + stats.totalMemory);
            return;
        }
        var index = _step - skinSteps;
        var effect = view.getEffectStats();
        System.println("probe: condition " + effect[0] + " particles " + effect[1] + " fps " + effect[2] + " draw last " + effect[3] + " ms max " + effect[4] + " ms budgetHit " + effect[5] + " used " + stats.usedMemory + " peak " + _peak + " total " + stats.totalMemory);
        if (index < _conditions.size()) {
            view.applySkinIndex(0);
            view.jumpToPageType(PageTypes.WEATHER);
            WeatherCache.forceSky(now, true);
            WeatherCache.forceCategory(_conditions[index], now);
            view.resetEffectStats();
        }
    }
}

//! No-op twin for normal builds.
(:noprobe)
module Probe {
    function mark(tag as String) as Void {
    }

    function onFrame(view as FaceView, now as Number) as Void {
    }
}
