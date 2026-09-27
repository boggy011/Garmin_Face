import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.WatchUi;

//! Circular sub dial panels: static frame with rim ticks, optional gauge on the rim, and
//! the stacked icon, value and label inside. The four outer panel centres sit on the
//! diagonals at a radius computed from the screen size (PanelSkin.layoutRadius).
module Panels {
    const OUTER_COUNT = 4;
    const GAUGE_START_DEGREES = 240;
    const GAUGE_SWEEP_DEGREES = 300;

    var _width as Number = 0;
    var _height as Number = 0;
    var _x as Array<Number> = [0, 0, 0, 0, 0] as Array<Number>;
    var _y as Array<Number> = [0, 0, 0, 0, 0] as Array<Number>;
    var _radius as Number = 0;
    var _centreRadius as Number = 0;
    var _fifthWidth as Number = 0;

    //! Compute panel centres for a skin. Index 0 to 3 are top left, top right, bottom left,
    //! bottom right. Index 4 is the compact fifth readout below the bottom pair.
    function layout(skin as Skin, width as Number, height as Number) as Void {
        _width = width;
        _height = height;
        var panels = skin.panels;
        var ringPercent = skin.dial.chapterRing ? skin.dial.chapterRingRadius / 2 : 48;
        var radiusPercent = panels.layoutRadius(ringPercent);
        var offset = (width * radiusPercent / 100 * 707) / 1000;
        var cx = width / 2;
        var cy = height / 2;
        _x[0] = cx - offset;
        _y[0] = cy - offset;
        _x[1] = cx + offset;
        _y[1] = cy - offset;
        _x[2] = cx - offset;
        _y[2] = cy + offset;
        _x[3] = cx + offset;
        _y[3] = cy + offset;
        _x[4] = cx;
        _y[4] = cy + width * radiusPercent / 100 * 9 / 10;
        _radius = width * panels.diameter / 200;
        _centreRadius = width * panels.centreDiameter / 200;
        _fifthWidth = 2 * (offset - _radius) - width * panels.spacing / 100;
    }

    function centreX(index as Number) as Number {
        return _x[index];
    }

    function centreY(index as Number) as Number {
        return _y[index];
    }

    function radius() as Number {
        return _radius;
    }

    function centreRadius() as Number {
        return _centreRadius;
    }

    function fifthWidth() as Number {
        return _fifthWidth;
    }

    //! Side of the press target square inscribed in a panel, so its corners stay inside the disc.
    function targetSide() as Number {
        return _radius * 14 / 10;
    }

    //! Static frame: fill, one pixel rim, tick marks every 30 degrees.
    function drawFrame(dc as Dc, skin as Skin, x as Number, y as Number, r as Number) as Void {
        var panels = skin.panels;
        dc.setColor(skin.resolveColor(panels.fill), Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(x, y, r);
        dc.setPenWidth(1);
        dc.setColor(skin.resolveColor(panels.rim), Graphics.COLOR_TRANSPARENT);
        dc.drawCircle(x, y, r);
        dc.setColor(skin.resolveColor(panels.tickColor), Graphics.COLOR_TRANSPARENT);
        for (var i = 0; i < 12; i++) {
            var angle = i * Math.PI / 6.0;
            var s = Math.sin(angle);
            var c = Math.cos(angle);
            dc.drawLine(x + (r - 3) * s, y - (r - 3) * c, x + (r - 1) * s, y - (r - 1) * c);
        }
    }

    //! Gauge on the rim from 7 o'clock clockwise to 5 o'clock, proportional to a 0..100 value,
    //! split into the skin's low, medium and high colour bands. reverse swaps the band
    //! colours for metrics where low is good (stress).
    function drawGauge(dc as Dc, skin as Skin, x as Number, y as Number, r as Number, value as Number, reverse as Boolean) as Void {
        var panels = skin.panels;
        var v = (value < 0) ? 0 : ((value > 100) ? 100 : value);
        var lowColor = skin.resolveColor(reverse ? panels.gaugeHighColor : panels.gaugeLowColor);
        var highColor = skin.resolveColor(reverse ? panels.gaugeLowColor : panels.gaugeHighColor);
        dc.setPenWidth(3);
        drawGaugeSegment(dc, x, y, r, 0, (v < panels.gaugeLowMax) ? v : panels.gaugeLowMax, lowColor);
        drawGaugeSegment(dc, x, y, r, panels.gaugeLowMax, (v < panels.gaugeMediumMax) ? v : panels.gaugeMediumMax, skin.resolveColor(panels.gaugeMediumColor));
        drawGaugeSegment(dc, x, y, r, panels.gaugeMediumMax, v, highColor);
        dc.setPenWidth(1);
    }

    function drawGaugeSegment(dc as Dc, x as Number, y as Number, r as Number, from as Number, to as Number, color as Number) as Void {
        if (to <= from) {
            return;
        }
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        var start = GAUGE_START_DEGREES - from * GAUGE_SWEEP_DEGREES / 100;
        var end = GAUGE_START_DEGREES - to * GAUGE_SWEEP_DEGREES / 100;
        dc.drawArc(x, y, r, Graphics.ARC_CLOCKWISE, start, end);
    }

    //! Icon in the upper third, value in the middle, uppercase label in the lower third.
    function drawContent(dc as Dc, skin as Skin, x as Number, y as Number, r as Number, icon as BitmapResource or BitmapReference or Null, value as String, label as String?, valueColor as Number, labelColor as Number, large as Boolean) as Void {
        var panels = skin.panels;
        var valueFont = large ? panels.largeValueFont : panels.valueFont;
        if (icon != null || large) {
            dc.setColor(skin.resolveColor(panels.fill), Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(x, y, r - 1);
        }
        if (icon != null) {
            var maxHeight = r * 45 / 100;
            var h = icon.getHeight();
            var w = icon.getWidth();
            if (h > maxHeight && (dc has :drawScaledBitmap)) {
                var scaledWidth = w * maxHeight / h;
                dc.drawScaledBitmap(x - scaledWidth / 2, y - r * 55 / 100 - maxHeight / 2, scaledWidth, maxHeight, icon);
            } else {
                dc.drawBitmap(x - w / 2, y - r * 55 / 100 - h / 2, icon);
            }
        }
        dc.setColor(valueColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, y + r * 5 / 100, valueFont, value, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        if (label != null) {
            dc.setColor(labelColor, Graphics.COLOR_TRANSPARENT);
            dc.drawText(x, y + r * 58 / 100, panels.labelFont, label, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }
}
