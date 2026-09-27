import Toybox.Graphics;
import Toybox.Lang;

//! Debug overlay: the 64 colour MIP palette (every channel 0x00, 0x55, 0xAA, 0xFF) as an
//! 8 by 8 grid, for photographing the real display and choosing colours empirically.
//! Row major: index = r * 16 + g * 4 + b.
module Swatches {
    var LEVELS as Array<Number> = [0x00, 0x55, 0xAA, 0xFF];

    function draw(dc as Dc, width as Number, height as Number) as Void {
        var cell = (width < height ? width : height) * 72 / 100 / 8;
        var left = width / 2 - cell * 4;
        var top = height / 2 - cell * 4;
        for (var index = 0; index < 64; index++) {
            var r = LEVELS[index / 16];
            var g = LEVELS[(index / 4) % 4];
            var b = LEVELS[index % 4];
            dc.setColor((r << 16) | (g << 8) | b, Graphics.COLOR_TRANSPARENT);
            dc.fillRectangle(left + (index % 8) * cell, top + (index / 8) * cell, cell, cell);
        }
    }
}
