import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;

//! Flakes of three sizes drifting down with a sinusoidal wobble: a dot, a small plus, and a
//! six armed star for the largest.
class SnowEffect extends WeatherEffect {
    private var _phase as Array<Float> = [] as Array<Float>;
    private var _time as Float = 0.0;

    function initialize() {
        WeatherEffect.initialize();
    }

    function init(width as Number, height as Number, skin as Skin) as Void {
        WeatherEffect.init(width, height, skin);
        var base = Effects.isAmoled() ? skin.effects().snowAmoled : skin.effects().snowMip;
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
        var speedFactor = (skin != null) ? skin.effects().snowSpeed : 1.0;
        _len[index] = (1 + index % 3).toFloat();
        _vy[index] = _height * (0.05 + 0.03 * _len[index]) * speedFactor;
        _vx[index] = 0.0;
        _x[index] = Effects.randomBelow(_width).toFloat();
        _y[index] = initial ? Effects.randomBelow(_height).toFloat() : -4.0;
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
        dc.setColor(skin.resolveColor(skin.effects().snowColor), Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1);
        var amplitude = _width * 0.015;
        for (var i = 0; i < _active; i++) {
            var wobble = amplitude * Math.sin(_time * 1.2 + _phase[i]);
            var x = (_x[i] + wobble).toNumber();
            var y = _y[i].toNumber();
            var size = _len[i].toNumber();
            if (size == 1) {
                dc.drawPoint(x, y);
            } else if (size == 2) {
                dc.drawLine(x - 1, y, x + 1, y);
                dc.drawLine(x, y - 1, x, y + 1);
            } else {
                dc.drawLine(x - 2, y, x + 2, y);
                dc.drawLine(x - 1, y - 2, x + 1, y + 2);
                dc.drawLine(x + 1, y - 2, x - 1, y + 2);
            }
        }
    }
}
