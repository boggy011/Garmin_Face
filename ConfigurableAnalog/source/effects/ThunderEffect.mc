import Toybox.Graphics;
import Toybox.Lang;

//! Rain plus a discreet lightning bolt every 4 to 12 seconds: a thick stroke for one frame,
//! then a thin one for two frames, no full screen flash.
class ThunderEffect extends RainEffect {
    const FLASH_FRAMES = 1;
    const BOLT_FRAMES = 2;
    const BOLT_POINTS = 6;

    private var _msToFlash as Number = 6000;
    private var _flashFrames as Number = 0;
    private var _boltFrames as Number = 0;
    private var _boltX as Array<Number> = [0, 0, 0, 0, 0, 0] as Array<Number>;
    private var _boltY as Array<Number> = [0, 0, 0, 0, 0, 0] as Array<Number>;

    function initialize() {
        RainEffect.initialize();
    }

    function init(width as Number, height as Number, skin as Skin) as Void {
        RainEffect.init(width, height, skin);
        scheduleFlash();
    }

    private function scheduleFlash() as Void {
        _msToFlash = 4000 + Effects.randomBelow(8000);
    }

    function step(dtMs as Number) as Void {
        if (_frozen) {
            return;
        }
        RainEffect.step(dtMs);
        if (_flashFrames > 0) {
            _flashFrames -= 1;
            return;
        }
        if (_boltFrames > 0) {
            _boltFrames -= 1;
            return;
        }
        _msToFlash -= dtMs;
        if (_msToFlash <= 0) {
            _flashFrames = FLASH_FRAMES;
            _boltFrames = BOLT_FRAMES;
            buildBolt();
            scheduleFlash();
        }
    }

    //! Zigzag from a random point near the top down to the horizon.
    private function buildBolt() as Void {
        var x = _width / 4 + Effects.randomBelow(_width / 2);
        var y = _height / 12;
        var stepY = (_horizon - y) / (BOLT_POINTS - 1);
        for (var i = 0; i < BOLT_POINTS; i++) {
            _boltX[i] = x;
            _boltY[i] = y;
            x += Effects.randomBelow(_width / 8) - _width / 16;
            y += stepY;
        }
    }

    function draw(dc as Dc) as Void {
        RainEffect.draw(dc);
        var skin = _skin;
        if (skin == null) {
            return;
        }
        var flash = skin.resolveColor(skin.effects().flashColor);
        if (_flashFrames > 0 || _boltFrames > 0) {
            dc.setColor(flash, Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth((_flashFrames > 0) ? 3 : 1);
            for (var i = 1; i < BOLT_POINTS; i++) {
                dc.drawLine(_boltX[i - 1], _boltY[i - 1], _boltX[i], _boltY[i]);
            }
            dc.setPenWidth(1);
        }
    }
}
