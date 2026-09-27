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
    private var _topo as IconSet = new IconSet([Rez.Drawables.bg_topo] as Array<ResourceId>);

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
        drawTexture(dc, skin);
        drawChapterRing(dc, skin);
        drawTicks(dc, skin);
        drawNumerals(dc, skin);
        if (skin.dial().innerBezel) {
            dc.setPenWidth(1);
            dc.setColor(skin.resolveColor(skin.dial().innerBezelColor), Graphics.COLOR_TRANSPARENT);
            dc.drawCircle(_cx, _cy, _radius * skin.dial().innerBezelRadius / 100);
        }
    }

    //! Ring, ticks and numerals only, redrawn over an animated overlay so the overlay
    //! stays behind the time markers.
    function drawForeground(dc as Dc, skin as Skin) as Void {
        drawChapterRing(dc, skin);
        drawTicks(dc, skin);
        drawNumerals(dc, skin);
    }

    //! Pre rendered depth: radial lines, dithered rings, crosshatch or a dot grid.
    private function drawTexture(dc as Dc, skin as Skin) as Void {
        var dial = skin.dial();
        if (dial.texture == DialSkin.TEXTURE_NONE) {
            return;
        }
        if (dial.texture == DialSkin.TEXTURE_TOPO) {
            var bitmap = _topo.get(0);
            dc.drawBitmap(_cx - bitmap.getWidth() / 2, _cy - bitmap.getHeight() / 2, bitmap);
            return;
        }
        dc.setColor(skin.resolveColor(dial.textureColor), Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1);
        var spacing = (dial.textureSpacing < 2) ? 2 : dial.textureSpacing;
        if (dial.texture == DialSkin.TEXTURE_SUNBURST) {
            var count = 360 / spacing;
            for (var i = 0; i < count; i++) {
                var angle = i * _twoPi / count;
                dc.drawLine(_cx, _cy, _cx + _radius * Math.sin(angle), _cy - _radius * Math.cos(angle));
            }
        } else if (dial.texture == DialSkin.TEXTURE_RINGS) {
            var gap = spacing;
            var r = _radius;
            while (r > _radius / 4) {
                dc.drawCircle(_cx, _cy, r);
                r -= gap;
                gap += 1;
            }
        } else if (dial.texture == DialSkin.TEXTURE_CROSSHATCH) {
            var step = spacing * 3;
            var size = _radius * 2;
            for (var offset = -size; offset <= size; offset += step) {
                dc.drawLine(_cx - _radius + offset, _cy - _radius, _cx + _radius + offset, _cy + _radius);
                dc.drawLine(_cx + _radius - offset, _cy - _radius, _cx - _radius - offset, _cy + _radius);
            }
        } else if (dial.texture == DialSkin.TEXTURE_DOT_GRID) {
            var step = spacing * 3;
            for (var y = _cy - _radius; y <= _cy + _radius; y += step) {
                for (var x = _cx - _radius; x <= _cx + _radius; x += step) {
                    dc.drawPoint(x, y);
                }
            }
        }
        var background = skin.resolveColor(skin.backgroundColor);
        dc.setColor(background, Graphics.COLOR_TRANSPARENT);
        var inner = _radius * 22 / 100;
        dc.fillCircle(_cx, _cy, inner);
    }

    //! Outer ring with a minute track, long marks every five minutes in the numeral silver.
    private function drawChapterRing(dc as Dc, skin as Skin) as Void {
        var dial = skin.dial();
        if (!dial.chapterRing) {
            return;
        }
        var r = _radius * dial.chapterRingRadius / 100;
        dc.setPenWidth(dial.chapterRingWidth);
        dc.setColor(skin.resolveColor(dial.chapterRingColor), Graphics.COLOR_TRANSPARENT);
        dc.drawCircle(_cx, _cy, r);
        for (var i = 0; i < 60; i++) {
            var major = (i % 5 == 0);
            var length = major ? _radius * 6 / 100 : _radius * 3 / 100;
            var angle = i * _twoPi / 60.0;
            var s = Math.sin(angle);
            var c = Math.cos(angle);
            dc.setPenWidth(major ? 2 : 1);
            dc.setColor(skin.resolveColor(major ? skin.tickMajorColor : dial.chapterRingColor), Graphics.COLOR_TRANSPARENT);
            dc.drawLine(_cx + (r - length) * s, _cy - (r - length) * c, _cx + r * s, _cy - r * c);
        }
        if (dial.accentQuadrant >= 0 && dial.accentQuadrant < 4) {
            dc.setPenWidth(dial.chapterRingWidth + 1);
            dc.setColor(skin.accentColor, Graphics.COLOR_TRANSPARENT);
            var startDegrees = 90 - dial.accentQuadrant * 90;
            dc.drawArc(_cx, _cy, r, Graphics.ARC_CLOCKWISE, startDegrees, startDegrees - 90);
        }
        dc.setPenWidth(1);
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
        if (skin.dial().handShadow) {
            var offset = skin.dial().handShadowOffset;
            _cx += offset;
            _cy += offset;
            drawHand(dc, skin, skin.hourHand, hourAngle, skin.dial().handShadowColor);
            drawHand(dc, skin, skin.minuteHand, minuteAngle, skin.dial().handShadowColor);
            _cx -= offset;
            _cy -= offset;
        }
        drawHand(dc, skin, skin.hourHand, hourAngle, null);
        drawHand(dc, skin, skin.minuteHand, minuteAngle, null);
        drawCap(dc, skin);
    }

    //! Centre cap: filled disc with a rim when enabled, else the plain cap colour.
    private function drawCap(dc as Dc, skin as Skin) as Void {
        var dial = skin.dial();
        if (dial.centreCap) {
            dc.setColor(skin.resolveColor(dial.centreCapRim), Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(_cx, _cy, dial.centreCapRadius);
            dc.setColor(skin.resolveColor(dial.centreCapFill), Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(_cx, _cy, (dial.centreCapRadius > 2) ? dial.centreCapRadius - 2 : 1);
        } else {
            dc.setColor(skin.resolveColor(skin.capColor), Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(_cx, _cy, skin.capRadius);
        }
    }

    //! Seconds hand only. Used by full and partial updates.
    function drawSeconds(dc as Dc, skin as Skin, second as Number) as Void {
        var angle = second * _twoPi / 60.0;
        drawHand(dc, skin, skin.secondHand, angle, null);
        if (skin.secondHand.counterweight > 0) {
            var tail = skin.secondHand.tail * _radius * 0.7;
            dc.setColor(skin.resolveColor(skin.secondHand.color), Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(_cx - tail * Math.sin(angle), _cy + tail * Math.cos(angle), skin.secondHand.counterweight);
        }
        drawCap(dc, skin);
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
        var margin = hand.width + skin.capRadius + skin.dial().centreCapRadius + 2;
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

    //! Draw one hand, in its own colour or in an override colour (used for the shadow pass).
    private function drawHand(dc as Dc, skin as Skin, hand as HandSpec, angle as Float, colorOverride as Number?) as Void {
        dc.setColor((colorOverride != null) ? colorOverride : skin.resolveColor(hand.color), Graphics.COLOR_TRANSPARENT);
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
        if (hand.shape == SkinDefs.SHAPE_SKELETON) {
            setPoint(_pts4, 0, tail, -half, s, c);
            setPoint(_pts4, 1, length, -half, s, c);
            setPoint(_pts4, 2, length, half, s, c);
            setPoint(_pts4, 3, tail, half, s, c);
            dc.fillPolygon(_pts4 as Array<[Numeric, Numeric]>);
            if (colorOverride == null && half > 2.0) {
                var inset = half - 2.0;
                var innerStart = length * 0.25;
                var innerEnd = length * 0.82;
                dc.setColor(skin.resolveColor(skin.dial().subdialFill), Graphics.COLOR_TRANSPARENT);
                setPoint(_pts4, 0, innerStart, -inset, s, c);
                setPoint(_pts4, 1, innerEnd, -inset, s, c);
                setPoint(_pts4, 2, innerEnd, inset, s, c);
                setPoint(_pts4, 3, innerStart, inset, s, c);
                dc.fillPolygon(_pts4 as Array<[Numeric, Numeric]>);
            }
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
