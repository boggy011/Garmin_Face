import Toybox.Graphics;
import Toybox.Lang;

//! A few short curved streaks drifting left to right at different speeds.
class WindEffect extends WeatherEffect {
    function initialize() {
        WeatherEffect.initialize();
    }

    function init(width as Number, height as Number, skin as Skin) as Void {
        WeatherEffect.init(width, height, skin);
        var base = Effects.isAmoled() ? skin.effects().rainAmoled : skin.effects().rainMip;
        allocate((base / 4 * Effects.intensityScale() + 0.5).toNumber());
    }

    protected function spawn(index as Number, initial as Boolean) as Void {
        _vy[index] = 0.0;
        _len[index] = _width * (0.03 + 0.03 * Effects.random());
        _vx[index] = _width * (0.25 + 0.35 * Effects.random());
        _y[index] = (_height * 0.15 + Effects.randomBelow((_height * 7 / 10).toNumber())).toFloat();
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
        dc.setColor(skin.resolveColor(skin.effects().windColor), Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1);
        for (var i = 0; i < _active; i++) {
            var x = _x[i].toNumber();
            var y = _y[i].toNumber();
            var r = _len[i].toNumber();
            dc.drawArc(x, y + r, r, Graphics.ARC_COUNTER_CLOCKWISE, 20, 110);
            dc.drawArc(x + r, y + r + 2, r * 2 / 3, Graphics.ARC_COUNTER_CLOCKWISE, 30, 100);
        }
    }
}
