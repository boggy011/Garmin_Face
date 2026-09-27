import Toybox.Graphics;
import Toybox.Lang;

//! Streaks drifting horizontally plus two cloud outlines moving left to right.
class WindEffect extends WeatherEffect {
    const CLOUDS = 2;

    function initialize() {
        WeatherEffect.initialize();
    }

    function init(width as Number, height as Number, skin as Skin) as Void {
        WeatherEffect.init(width, height, skin);
        var base = Effects.isAmoled() ? skin.effects.rainAmoled : skin.effects.rainMip;
        allocate((base / 2 * Effects.intensityScale() + 0.5).toNumber() + CLOUDS);
    }

    protected function spawn(index as Number, initial as Boolean) as Void {
        var cloud = index < CLOUDS;
        _vy[index] = 0.0;
        if (cloud) {
            _len[index] = _width * 0.16;
            _vx[index] = _width * (0.05 + 0.03 * index);
            _y[index] = _height * (0.18 + 0.12 * index);
        } else {
            _len[index] = _width * (0.05 + 0.08 * Effects.random());
            _vx[index] = _width * (0.4 + 0.5 * Effects.random());
            _y[index] = Effects.randomBelow(_height).toFloat();
        }
        _x[index] = initial ? Effects.randomBelow(_width).toFloat() : -_len[index];
    }

    function step(dtMs as Number) as Void {
        if (_frozen) {
            return;
        }
        var dt = dtMs / 1000.0;
        for (var i = 0; i < _active; i++) {
            _x[i] += _vx[i] * dt;
            if (_x[i] > _width + _len[i]) {
                spawn(i, false);
            }
        }
    }

    function draw(dc as Dc) as Void {
        var skin = _skin;
        if (skin == null) {
            return;
        }
        dc.setColor(skin.resolveColor(skin.effects.windColor), Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1);
        for (var i = 0; i < _active; i++) {
            var x = _x[i].toNumber();
            var y = _y[i].toNumber();
            var len = _len[i].toNumber();
            if (i < CLOUDS) {
                var r = len / 4;
                dc.drawArc(x, y, r, Graphics.ARC_COUNTER_CLOCKWISE, 0, 180);
                dc.drawArc(x + r * 2, y - r / 2, r + r / 2, Graphics.ARC_COUNTER_CLOCKWISE, 0, 180);
                dc.drawArc(x + r * 4, y, r, Graphics.ARC_COUNTER_CLOCKWISE, 0, 180);
                dc.drawLine(x - r, y, x + r * 5, y);
            } else {
                dc.drawLine(x, y, x + len, y);
            }
        }
    }
}
