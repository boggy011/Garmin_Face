import Toybox.Graphics;
import Toybox.Lang;

//! Three translucent bands sliding slowly. Translucency is a dither: every other row, with
//! the rows shortened towards the band edges so the bands look soft.
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
        _len[index] = _width * (0.45 + 0.15 * index);
        _y[index] = _height * (0.22 + 0.24 * index);
        _vy[index] = 0.0;
        _vx[index] = _width * (0.015 + 0.008 * index) * ((index % 2 == 0) ? 1.0 : -1.0);
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
        dc.setColor(skin.resolveColor(skin.effects().fogColor), Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1);
        var rows = _height / 24;
        for (var i = 0; i < _active; i++) {
            var length = _len[i].toNumber();
            var centreX = (_x[i] + _len[i] / 2.0).toNumber();
            var y0 = _y[i].toNumber();
            for (var row = 0; row < rows; row += 2) {
                var edge = (row < rows / 2) ? row : rows - row;
                var rowLength = length - (rows / 2 - edge) * length / rows;
                var offset = (row % 4 == 0) ? 0 : 1;
                dc.drawLine(centreX - rowLength / 2 + offset, y0 + row, centreX + rowLength / 2 + offset, y0 + row);
            }
        }
    }
}
