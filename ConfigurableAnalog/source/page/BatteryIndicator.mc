import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;

//! Small battery glyph with the percentage, drawn at the top of every page below the 12
//! numeral. Position, colours and font come from the skin's battery block.
module BatteryIndicator {
    var _text as String = "";
    var _minute as Number = -1;
    var _percent as Number = 0;

    //! Refresh the cached text once per minute so drawing allocates nothing.
    function refresh(now as Number) as Void {
        var minute = now / 60;
        if (minute == _minute) {
            return;
        }
        _minute = minute;
        _percent = System.getSystemStats().battery.toNumber();
        _text = _percent.toString() + "%";
    }

    function draw(dc as Dc, skin as Skin, width as Number, height as Number) as Void {
        var battery = skin.battery();
        if (!battery.visible) {
            return;
        }
        var cx = width / 2;
        var cy = height * battery.y / 100;
        var glyphWidth = width * 7 / 100;
        var glyphHeight = width * 35 / 1000;
        var gap = 3;
        var textWidth = dc.getTextWidthInPixels(_text, battery.font);
        var left = cx - (glyphWidth + gap + textWidth) / 2;
        var top = cy - glyphHeight / 2;
        var color = skin.resolveColor((_percent <= battery.lowPercent) ? battery.lowColor : battery.color);
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1);
        dc.drawRectangle(left, top, glyphWidth - 2, glyphHeight);
        dc.fillRectangle(left + glyphWidth - 2, cy - glyphHeight / 4, 2, glyphHeight / 2);
        var fill = (glyphWidth - 6) * _percent / 100;
        if (fill > 0) {
            dc.fillRectangle(left + 2, top + 2, fill, glyphHeight - 4);
        }
        dc.drawText(left + glyphWidth + gap, cy, battery.font, _text, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}
