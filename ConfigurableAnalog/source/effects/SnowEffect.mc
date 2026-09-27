import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;

//! Slow drifting flakes with a sinusoidal horizontal wobble, two sizes.
class SnowEffect extends WeatherEffect {
    private var _phase as Array<Float> = [] as Array<Float>;
    private var _time as Float = 0.0;

    function initialize() {
        WeatherEffect.initialize();
    }

    function init(width as Number, height as Number, skin as Skin) as Void {
        WeatherEffect.init(width, height, skin);
        var base = Effects.isAmoled() ? skin.effects.snowAmoled : skin.effects.snowMip;
        var n = (base * Effects.intensityScale() + 0.5).toNumber();
        var phase = new [(n < 1) ? 1 : n] as Array<Float>;
        for (var i = 0; i < phase.size(); i++) {
            phase[i] = Effects.random() * 6.283;
        }
        _phase = phase;
        allocate(n);
    }

    protected function spawn(index as Number, initial as Boolean) as Void {
        var skin = _skin;
        var speedFactor = (skin != null) ? skin.effects.snowSpeed : 1.0;
        _len[index] = (index % 2 == 0) ? 1.0 : 2.0;
        _vy[index] = _height * (0.08 + 0.07 * Effects.random()) * speedFactor;
        _vx[index] = 0.0;
        _x[index] = Effects.randomBelow(_width).toFloat();
        _y[index] = initial ? Effects.randomBelow(_height).toFloat() : -3.0;
    }

    function step(dtMs as Number) as Void {
        if (_frozen) {
            return;
        }
        _time += dtMs / 1000.0;
        WeatherEffect.step(dtMs);
    }

    function draw(dc as Dc) as Void {
        var skin = _skin;
        if (skin == null) {
            return;
        }
        dc.setColor(skin.resolveColor(skin.effects.snowColor), Graphics.COLOR_TRANSPARENT);
        var amplitude = _width * 0.02;
        for (var i = 0; i < _active; i++) {
            var wobble = amplitude * Math.sin(_time * 1.5 + _phase[i]);
            var x = (_x[i] + wobble).toNumber();
            var y = _y[i].toNumber();
            var radius = _len[i].toNumber();
            dc.fillCircle(x, y, radius);
        }
    }
}
