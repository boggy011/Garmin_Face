import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;

//! Short angled lines falling, angle from the wind bearing when Weather provides it.
class RainEffect extends WeatherEffect {
    protected var _countScale as Float = 1.0;
    protected var _lengthScale as Float = 1.0;
    protected var _speedScale as Float = 1.0;
    protected var _drift as Float = 0.0;

    function initialize() {
        WeatherEffect.initialize();
    }

    function init(width as Number, height as Number, skin as Skin) as Void {
        WeatherEffect.init(width, height, skin);
        var base = Effects.isAmoled() ? skin.effects.rainAmoled : skin.effects.rainMip;
        var bearing = WeatherCache.windBearing;
        if (bearing != null) {
            _drift = -Math.sin(bearing * Math.PI / 180.0).toFloat() * 0.35;
        }
        allocate((base * _countScale * Effects.intensityScale() + 0.5).toNumber());
    }

    protected function spawn(index as Number, initial as Boolean) as Void {
        var skin = _skin;
        var speedFactor = (skin != null) ? skin.effects.rainSpeed : 1.0;
        var speed = _height * (0.9 + 0.4 * Effects.random()) * _speedScale * speedFactor;
        _len[index] = _height * (0.04 + 0.03 * Effects.random()) * _lengthScale;
        _vy[index] = speed;
        _vx[index] = speed * _drift;
        _x[index] = Effects.randomBelow(_width).toFloat();
        _y[index] = initial ? Effects.randomBelow(_height).toFloat() : -_len[index];
    }

    function draw(dc as Dc) as Void {
        var skin = _skin;
        if (skin == null) {
            return;
        }
        dc.setColor(skin.resolveColor(skin.effects.rainColor), Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1);
        for (var i = 0; i < _active; i++) {
            var x = _x[i];
            var y = _y[i];
            var len = _len[i];
            dc.drawLine(x, y, x + len * _drift, y + len);
        }
    }
}

//! More, longer and faster drops plus splash dots on the horizon line.
class HeavyRainEffect extends RainEffect {
    const SPLASHES = 4;

    function initialize() {
        RainEffect.initialize();
        _countScale = 1.6;
        _lengthScale = 1.5;
        _speedScale = 1.4;
    }

    function draw(dc as Dc) as Void {
        RainEffect.draw(dc);
        var skin = _skin;
        if (skin == null || _frozen) {
            return;
        }
        dc.setColor(skin.resolveColor(skin.effects.rainColor), Graphics.COLOR_TRANSPARENT);
        for (var i = 0; i < SPLASHES; i++) {
            if (Effects.randomBelow(3) == 0) {
                var x = Effects.randomBelow(_width);
                dc.drawPoint(x, _horizon - 1);
                dc.drawPoint(x - 2, _horizon - 2);
                dc.drawPoint(x + 2, _horizon - 2);
            }
        }
    }
}
