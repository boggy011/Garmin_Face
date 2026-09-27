import Toybox.Graphics;
import Toybox.Lang;

//! Three horizontal translucent bands sliding slowly. Translucency is approximated with
//! dithered lines (every other row) which also reads correctly on MIP.
class FogEffect extends WeatherEffect {
    const BANDS = 3;

    function initialize() {
        WeatherEffect.initialize();
    }

    function init(width as Number, height as Number, skin as Skin) as Void {
        WeatherEffect.init(width, height, skin);
        allocate(BANDS);
    }

    protected function spawn(index as Number, initial as Boolean) as Void {
        _len[index] = _width * (0.5 + 0.2 * index);
        _y[index] = _height * (0.2 + 0.25 * index);
        _vy[index] = 0.0;
        _vx[index] = _width * (0.02 + 0.01 * index) * ((index % 2 == 0) ? 1.0 : -1.0);
        _x[index] = initial ? Effects.randomBelow(_width).toFloat() : ((_vx[index] > 0.0) ? -_len[index] : _width.toFloat());
    }

    function step(dtMs as Number) as Void {
        if (_frozen) {
            return;
        }
        var dt = dtMs / 1000.0;
        for (var i = 0; i < _active; i++) {
            _x[i] += _vx[i] * dt;
            if (_x[i] > _width) {
                _x[i] = -_len[i];
            } else if (_x[i] < -_len[i]) {
                _x[i] = _width.toFloat();
            }
        }
    }

    function draw(dc as Dc) as Void {
        var skin = _skin;
        if (skin == null) {
            return;
        }
        dc.setColor(skin.resolveColor(skin.effects.fogColor), Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1);
        var thickness = _height / 14;
        for (var i = 0; i < _active; i++) {
            var x0 = _x[i].toNumber();
            var x1 = (_x[i] + _len[i]).toNumber();
            var y0 = _y[i].toNumber();
            for (var y = y0; y < y0 + thickness; y += 2) {
                dc.drawLine(x0, y, x1, y);
            }
        }
    }
}
