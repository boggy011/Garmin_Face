import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;

//! Procedural moon phase. A light disc with a few darker craters, the unlit part painted
//! over in the dark colour (black on the dial, so only the lit shape shows), a thin outline
//! so the whole disc stays readable, and craters only where they fall on the lit side.
//! No bitmaps: it draws the same on every device, needs no palette dither on MIP and
//! costs no resource memory.
module MoonPhase {
    const POINTS = 18;

    //! Crater centres and radii in thousandths of the moon radius.
    var _craterX as Array<Number> = [-380, 300, -120, 360] as Array<Number>;
    var _craterY as Array<Number> = [-320, 220, 420, -380] as Array<Number>;
    var _craterR as Array<Number> = [190, 140, 100, 90] as Array<Number>;
    var _half as Array<Array<Number>> = [
        [0, 0], [0, 0], [0, 0], [0, 0], [0, 0], [0, 0], [0, 0], [0, 0], [0, 0], [0, 0], [0, 0], [0, 0], [0, 0], [0, 0], [0, 0], [0, 0], [0, 0], [0, 0]
    ] as Array<Array<Number>>;

    //! True when the point (dx, dy) from the centre lies on the lit side of the terminator
    //! for an illuminated fraction k. Waxing moons are lit on the right.
    function isLit(dx as Number, dy as Number, radius as Number, k as Float, waxing as Boolean) as Boolean {
        if (radius <= 0) {
            return false;
        }
        var ny = dy.toFloat() / radius;
        if (ny >= 1.0 || ny <= -1.0) {
            return false;
        }
        var chord = Math.sqrt(1.0 - ny * ny) * radius;
        var a = (1.0 - 2.0 * k).abs() * chord;
        var edge = (k < 0.5) ? a : -a;
        var toward = waxing ? dx.toFloat() : -dx.toFloat();
        return toward >= edge;
    }

    //! Draw the moon centred on (x, y). k is the illuminated fraction 0..1.
    function draw(dc as Dc, x as Number, y as Number, radius as Number, k as Float, waxing as Boolean, lit as Number, dark as Number, outline as Number, crater as Number) as Void {
        dc.setColor(lit, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(x, y, radius);
        var side = waxing ? -1.0 : 1.0;
        for (var i = 0; i < POINTS; i++) {
            var angle = Math.PI * i / (POINTS - 1) - Math.PI / 2.0;
            _half[i][0] = (x + side * (radius + 1) * Math.cos(angle)).toNumber();
            _half[i][1] = (y + (radius + 1) * Math.sin(angle)).toNumber();
        }
        dc.setColor(dark, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon(_half as Array<[Numeric, Numeric]>);
        var a = ((1.0 - 2.0 * k).abs() * radius).toNumber();
        if (a > 0) {
            dc.setColor((k < 0.5) ? dark : lit, Graphics.COLOR_TRANSPARENT);
            dc.fillEllipse(x, y, a, radius);
        }
        dc.setColor(crater, Graphics.COLOR_TRANSPARENT);
        for (var i = 0; i < _craterX.size(); i++) {
            var cx = _craterX[i] * radius / 1000;
            var cy = _craterY[i] * radius / 1000;
            var cr = _craterR[i] * radius / 1000;
            if (cr > 0 && isLit(cx, cy, radius, k, waxing)) {
                dc.fillCircle(x + cx, y + cy, cr);
            }
        }
        dc.setPenWidth(1);
        dc.setColor(outline, Graphics.COLOR_TRANSPARENT);
        dc.drawCircle(x, y, radius);
    }
}
