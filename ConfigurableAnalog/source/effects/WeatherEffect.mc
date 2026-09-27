import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;

//! Counters and helpers shared by the effects. Tests read the allocation counter.
module Effects {
    //! Number of particle array allocations since start. Must only grow when an effect is created.
    var allocations as Number = 0;

    //! Random float in [0, 1).
    function random() as Float {
        return (Math.rand() % 10000).toFloat() / 10000.0;
    }

    //! Random integer in [0, max).
    function randomBelow(max as Number) as Number {
        if (max <= 0) {
            return 0;
        }
        return Math.rand() % max;
    }

    //! Particle budget scale for the effectsIntensity setting.
    function intensityScale() as Float {
        var intensity = Settings.getEffectsIntensity();
        if (intensity.equals("low")) {
            return 0.5;
        }
        if (intensity.equals("high")) {
            return 1.5;
        }
        return 1.0;
    }

    //! AMOLED profile when the device needs burn in protection, MIP profile otherwise.
    function isAmoled() as Boolean {
        return Display.isAmoled();
    }
}

//! Base class of the animated weather overlays. A particle model with fixed size arrays
//! allocated once in init. step advances the simulation, draw renders the current state,
//! freeze keeps the last frame for the static face.
class WeatherEffect {
    protected var _width as Number = 0;
    protected var _height as Number = 0;
    protected var _horizon as Number = 0;
    protected var _skin as Skin?;
    protected var _frozen as Boolean = false;
    protected var _fps as Number = 6;
    protected var _count as Number = 0;
    protected var _active as Number = 0;
    protected var _x as Array<Float> = [] as Array<Float>;
    protected var _y as Array<Float> = [] as Array<Float>;
    protected var _vx as Array<Float> = [] as Array<Float>;
    protected var _vy as Array<Float> = [] as Array<Float>;
    protected var _len as Array<Float> = [] as Array<Float>;

    function initialize() {
    }

    //! Allocate particle storage once. Subclasses call allocate from their init.
    function init(width as Number, height as Number, skin as Skin) as Void {
        _width = width;
        _height = height;
        _horizon = height / 2;
        _skin = skin;
        _fps = Effects.isAmoled() ? skin.effects().fpsAmoled : skin.effects().fpsMip;
    }

    protected function allocate(count as Number) as Void {
        var n = (count < 1) ? 1 : count;
        var x = new [n] as Array<Float>;
        var y = new [n] as Array<Float>;
        var vx = new [n] as Array<Float>;
        var vy = new [n] as Array<Float>;
        var len = new [n] as Array<Float>;
        for (var i = 0; i < n; i++) {
            x[i] = 0.0;
            y[i] = 0.0;
            vx[i] = 0.0;
            vy[i] = 0.0;
            len[i] = 0.0;
        }
        _x = x;
        _y = y;
        _vx = vx;
        _vy = vy;
        _len = len;
        _count = n;
        _active = n;
        Effects.allocations += 1;
        for (var i = 0; i < n; i++) {
            spawn(i, true);
        }
    }

    //! Place particle i. Subclasses override. initial scatters over the whole screen.
    protected function spawn(index as Number, initial as Boolean) as Void {
    }

    //! Advance by dtMs milliseconds. Base implementation integrates velocity and recycles
    //! particles that leave the screen. No allocations.
    function step(dtMs as Number) as Void {
        if (_frozen) {
            return;
        }
        var dt = dtMs / 1000.0;
        for (var i = 0; i < _active; i++) {
            _x[i] += _vx[i] * dt;
            _y[i] += _vy[i] * dt;
            if (_y[i] > _height + _len[i] || _y[i] < -_len[i] - _height || _x[i] < -_len[i] - _width || _x[i] > _width + _len[i] + _width) {
                spawn(i, false);
            }
            if (_x[i] < 0.0) {
                _x[i] += _width;
            } else if (_x[i] >= _width) {
                _x[i] -= _width;
            }
        }
    }

    function draw(dc as Dc) as Void {
    }

    //! Keep the current frame, stop advancing.
    function freeze() as Void {
        _frozen = true;
    }

    function unfreeze() as Void {
        _frozen = false;
    }

    function getFps() as Number {
        return _fps;
    }

    //! Frame budget in milliseconds.
    function getBudgetMs() as Number {
        return 1000 / ((_fps < 1) ? 1 : _fps);
    }

    //! Halve the number of simulated particles for the rest of the session.
    function halveParticles() as Void {
        _active = _active / 2;
        if (_active < 1) {
            _active = 1;
        }
    }

    function getParticleCount() as Number {
        return _active;
    }

    function getAllocatedCount() as Number {
        return _count;
    }

    //! True when particle i is inside the screen bounds plus its own length. Used by tests.
    function isInBounds(index as Number) as Boolean {
        var margin = _len[index] + 1.0;
        return _x[index] >= -margin && _x[index] <= _width + margin && _y[index] >= -margin - _height * 0.1 && _y[index] <= _height + margin;
    }
}

//! Nothing to animate (clear, cloudy, partly cloudy).
class NoEffect extends WeatherEffect {
    function initialize() {
        WeatherEffect.initialize();
    }

    function init(width as Number, height as Number, skin as Skin) as Void {
        WeatherEffect.init(width, height, skin);
        _fps = 0;
    }
}
