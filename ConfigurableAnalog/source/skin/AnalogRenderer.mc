import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;

//! Draws dial, ticks, numerals and hands from a Skin. Holds preallocated point
//! arrays so per-frame drawing does not allocate.
class AnalogRenderer {
    private var _cx as Number;
    private var _cy as Number;
    private var _radius as Number;
    private var _pts4 as Array<Array<Number>> = [[0, 0], [0, 0], [0, 0], [0, 0]] as Array<Array<Number>>;
    private var _pts7 as Array<Array<Number>> = [[0, 0], [0, 0], [0, 0], [0, 0], [0, 0], [0, 0], [0, 0]] as Array<Array<Number>>;
    private var _clip as Array<Number> = [0, 0, 1, 1] as Array<Number>;
    private var _twoPi as Float;

    function initialize(width as Number, height as Number) {
        _cx = width / 2;
        _cy = height / 2;
        _radius = ((width < height) ? width : height) / 2;
        _twoPi = Math.PI.toFloat() * 2.0;
    }

    //! Static dial: background, dial disc, ticks and numerals.
    function drawDial(dc as Dc, skin as Skin) as Void {
        var background = skin.resolveColor(skin.backgroundColor);
        dc.setColor(background, background);
        dc.clear();
        var dial = skin.resolveColor(skin.dialColor);
        if (dial != background) {
            dc.setColor(dial, Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(_cx, _cy, _radius);
        }
        drawTicks(dc, skin);
        drawNumerals(dc, skin);
    }

    private function drawTicks(dc as Dc, skin as Skin) as Void {
        var outer = (_radius - 1).toFloat();
        for (var i = 0; i < 60; i++) {
            var major = (i % 5 == 0);
            if (!major && !skin.showMinorTicks) {
                continue;
            }
            var length = (major ? skin.tickMajorLength : skin.tickMinorLength) * _radius / 100.0;
            var inner = outer - length;
            var angle = i * _twoPi / 60.0;
            var s = Math.sin(angle);
            var c = Math.cos(angle);
            dc.setPenWidth(major ? skin.tickMajorWidth : skin.tickMinorWidth);
            dc.setColor(skin.resolveColor(major ? skin.tickMajorColor : skin.tickMinorColor), Graphics.COLOR_TRANSPARENT);
            dc.drawLine(_cx + inner * s, _cy - inner * c, _cx + outer * s, _cy - outer * c);
        }
        dc.setPenWidth(1);
    }

    private function drawNumerals(dc as Dc, skin as Skin) as Void {
        if (skin.numeralStyle == SkinDefs.NUMERALS_NONE) {
            return;
        }
        var step = (skin.numeralStyle == SkinDefs.NUMERALS_QUARTERS) ? 3 : 1;
        var r = _radius * skin.numeralRadius / 100.0;
        dc.setColor(skin.resolveColor(skin.numeralColor), Graphics.COLOR_TRANSPARENT);
        for (var h = 12; h > 0; h -= step) {
            var angle = h * _twoPi / 12.0;
            var x = _cx + r * Math.sin(angle);
            var y = _cy - r * Math.cos(angle);
            dc.drawText(x, y, skin.numeralFont, h.toString(), Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }

    //! Hour and minute hands plus the centre cap.
    function drawHourMinute(dc as Dc, skin as Skin, hour as Number, minute as Number) as Void {
        var minuteAngle = minute * _twoPi / 60.0;
        var hourAngle = ((hour % 12) * 60 + minute) * _twoPi / 720.0;
        drawHand(dc, skin, skin.hourHand, hourAngle);
        drawHand(dc, skin, skin.minuteHand, minuteAngle);
        dc.setColor(skin.resolveColor(skin.capColor), Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(_cx, _cy, skin.capRadius);
    }

    //! Seconds hand only. Used by full and partial updates.
    function drawSeconds(dc as Dc, skin as Skin, second as Number) as Void {
        drawHand(dc, skin, skin.secondHand, second * _twoPi / 60.0);
        dc.setColor(skin.resolveColor(skin.capColor), Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(_cx, _cy, skin.capRadius);
    }

    //! Clip rectangle [x, y, w, h] covering the seconds hand at the given second.
    //! Returns a reused array, callers must not keep it.
    function computeSecondsClip(skin as Skin, second as Number) as Array<Number> {
        var hand = skin.secondHand;
        var angle = second * _twoPi / 60.0;
        var s = Math.sin(angle);
        var c = Math.cos(angle);
        var length = hand.length * _radius;
        var tail = hand.tail * _radius;
        var margin = hand.width + skin.capRadius + 2;
        var tipX = _cx + length * s;
        var tipY = _cy - length * c;
        var tailX = _cx - tail * s;
        var tailY = _cy + tail * c;
        var minX = ((tipX < tailX) ? tipX : tailX) - margin;
        var minY = ((tipY < tailY) ? tipY : tailY) - margin;
        var maxX = ((tipX > tailX) ? tipX : tailX) + margin;
        var maxY = ((tipY > tailY) ? tipY : tailY) + margin;
        _clip[0] = minX.toNumber();
        _clip[1] = minY.toNumber();
        _clip[2] = (maxX - minX).toNumber() + 1;
        _clip[3] = (maxY - minY).toNumber() + 1;
        return _clip;
    }

    private function drawHand(dc as Dc, skin as Skin, hand as HandSpec, angle as Float) as Void {
        dc.setColor(skin.resolveColor(hand.color), Graphics.COLOR_TRANSPARENT);
        var s = Math.sin(angle);
        var c = Math.cos(angle);
        var length = hand.length * _radius;
        var tail = -hand.tail * _radius;
        var half = hand.width / 2.0;
        if (hand.shape == SkinDefs.SHAPE_LINE) {
            dc.setPenWidth(hand.width);
            dc.drawLine(_cx + tail * s, _cy - tail * c, _cx + length * s, _cy - length * c);
            dc.setPenWidth(1);
            return;
        }
        if (hand.shape == SkinDefs.SHAPE_DAUPHINE) {
            setPoint(_pts4, 0, tail, 0.0, s, c);
            setPoint(_pts4, 1, length * 0.35, -half, s, c);
            setPoint(_pts4, 2, length, 0.0, s, c);
            setPoint(_pts4, 3, length * 0.35, half, s, c);
            dc.fillPolygon(_pts4 as Array<[Numeric, Numeric]>);
            return;
        }
        if (hand.shape == SkinDefs.SHAPE_ARROW) {
            var body = half * 0.5;
            var head = half * 1.5;
            var shoulder = length * 0.7;
            setPoint(_pts7, 0, tail, -body, s, c);
            setPoint(_pts7, 1, shoulder, -body, s, c);
            setPoint(_pts7, 2, shoulder, -head, s, c);
            setPoint(_pts7, 3, length, 0.0, s, c);
            setPoint(_pts7, 4, shoulder, head, s, c);
            setPoint(_pts7, 5, shoulder, body, s, c);
            setPoint(_pts7, 6, tail, body, s, c);
            dc.fillPolygon(_pts7 as Array<[Numeric, Numeric]>);
            return;
        }
        setPoint(_pts4, 0, tail, -half, s, c);
        setPoint(_pts4, 1, length, -half, s, c);
        setPoint(_pts4, 2, length, half, s, c);
        setPoint(_pts4, 3, tail, half, s, c);
        dc.fillPolygon(_pts4 as Array<[Numeric, Numeric]>);
    }

    //! Write a point given distance along the hand and offset across it.
    private function setPoint(points as Array<Array<Number>>, index as Number, along as Float, across as Float, s as Decimal, c as Decimal) as Void {
        points[index][0] = (_cx + along * s + across * c).toNumber();
        points[index][1] = (_cy - along * c + across * s).toNumber();
    }
}
