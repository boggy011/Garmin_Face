import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

//! Lazily loaded bitmap icons keyed by resource id.
class IconSet {
    private var _resources as Array<ResourceId>;
    private var _bitmaps as Array<BitmapResource or BitmapReference or Null>;

    function initialize(resources as Array<ResourceId>) {
        _resources = resources;
        var bitmaps = [] as Array<BitmapResource or BitmapReference or Null>;
        for (var i = 0; i < resources.size(); i++) {
            bitmaps.add(null);
        }
        _bitmaps = bitmaps;
    }

    function get(index as Number) as BitmapResource or BitmapReference {
        var bitmap = _bitmaps[index];
        if (bitmap == null) {
            bitmap = WatchUi.loadResource(_resources[index]) as BitmapResource or BitmapReference;
            _bitmaps[index] = bitmap;
        }
        return bitmap;
    }

    //! Draw an icon centred on a point.
    function drawCentered(dc as Dc, index as Number, x as Number, y as Number) as Void {
        var bitmap = get(index);
        dc.drawBitmap(x - bitmap.getWidth() / 2, y - bitmap.getHeight() / 2, bitmap);
    }

    function width(index as Number) as Number {
        return get(index).getWidth();
    }

    function height(index as Number) as Number {
        return get(index).getHeight();
    }
}

//! Icon plus value readout used by the weather and health pages. The anchor x is the
//! edge nearest the screen centre: right aligned readouts grow to the left of it.
module Readouts {
    const GAP = 3;

    function draw(dc as Dc, icons as IconSet, iconIndex as Number, anchor as Anchor, value as String, font as Graphics.FontDefinition, color as Number, width as Number, height as Number) as Void {
        var x = width * anchor.x / 100;
        var y = height * anchor.y / 100;
        var iconWidth = icons.width(iconIndex);
        var iconHeight = icons.height(iconIndex);
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        if (anchor.align == Graphics.TEXT_JUSTIFY_RIGHT) {
            dc.drawBitmap(x - iconWidth, y - iconHeight / 2, icons.get(iconIndex));
            dc.drawText(x - iconWidth - GAP, y, font, value, Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);
        } else if (anchor.align == Graphics.TEXT_JUSTIFY_LEFT) {
            dc.drawBitmap(x, y - iconHeight / 2, icons.get(iconIndex));
            dc.drawText(x + iconWidth + GAP, y, font, value, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        } else {
            var textWidth = dc.getTextWidthInPixels(value, font);
            var left = x - (iconWidth + GAP + textWidth) / 2;
            dc.drawBitmap(left, y - iconHeight / 2, icons.get(iconIndex));
            dc.drawText(left + iconWidth + GAP, y, font, value, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }
}
