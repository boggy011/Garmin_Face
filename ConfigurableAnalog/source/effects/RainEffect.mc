import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;

//! Small drops of two or three sizes drifting down slowly in a muted colour, with the
//! horizontal drift taken from the wind bearing when Weather provides it.
class RainEffect extends WeatherEffect {
    protected var _countScale as Float = 1.0;
    protected var _sizeScale as Float = 1.0;
    protected var _speedScale as Float = 1.0;
    protected var _drift as Float = 0.0;

    function initialize() {
        WeatherEffect.initialize();
    }

    function init(width as Number, height as Number, skin as Skin) as Void {
        WeatherEffect.init(width, height, skin);
        var base = Effects.isAmoled() ? skin.effects().rainAmoled : skin.effects().rainMip;
        var bearing = WeatherCache.windBearing;
        if (bearing != null) {
            _drift = -Math.sin(bearing * Math.PI / 180.0).toFloat() * 0.25;
        }
        allocate((base * _countScale * Effects.intensityScale() + 0.5).toNumber());
    }

    protected function spawn(index as Number, initial as Boolean) as Void {
        var skin = _skin;
        var speedFactor = (skin != null) ? skin.effects().rainSpeed : 1.0;
        var size = 1.0 + (index % 3) * 0.5 * _sizeScale;
        var speed = _height * (0.35 + 0.15 * size) * _speedScale * speedFactor;
        _len[index] = size;
        _vy[index] = speed;
        _vx[index] = speed * _drift;
        _x[index] = Effects.randomBelow(_width).toFloat();
        _y[index] = initial ? Effects.randomBelow(_height).toFloat() : -4.0;
    }

    function draw(dc as Dc) as Void {
        var skin = _skin;
        if (skin == null) {
            return;
        }
        dc.setColor(skin.resolveColor(skin.effects().rainColor), Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1);
        for (var i = 0; i < _active; i++) {
            var x = _x[i].toNumber();
            var y = _y[i].toNumber();
            var size = _len[i];
            if (size < 1.5) {
                dc.drawPoint(x, y);
            } else if (size < 2.0) {
                dc.drawLine(x, y - 1, x, y + 1);
            } else {
                dc.fillCircle(x, y, 1);
                dc.drawPoint(x, y - 2);
            }
        }
    }
}

//! A few more and slightly larger drops, plus short streaks for the largest ones.
class HeavyRainEffect extends RainEffect {
    function initialize() {
        RainEffect.initialize();
        _countScale = 1.3;
        _sizeScale = 1.3;
        _speedScale = 1.2;
    }

    function draw(dc as Dc) as Void {
        RainEffect.draw(dc);
        var skin = _skin;
        if (skin == null) {
            return;
        }
        dc.setColor(skin.resolveColor(skin.effects().rainColor), Graphics.COLOR_TRANSPARENT);
        for (var i = 0; i < _active; i += 3) {
            var x = _x[i].toNumber();
            var y = _y[i].toNumber();
            dc.drawLine(x, y - 4, x + (_len[i] * _drift).toNumber(), y);
        }
    }
}
