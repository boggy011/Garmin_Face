import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

//! Draws slot values at skin defined positions and the page indicator.
//! Records each slot's bounding box for tap hit testing in the on-device editor.
class SlotRenderer {
    private const ICON_GAP = 4;

    private var _width as Number;
    private var _height as Number;
    private var _boxes as Array<Array<Number>>;

    function initialize(width as Number, height as Number) {
        _width = width;
        _height = height;
        var boxes = [] as Array<Array<Number>>;
        for (var i = 0; i < SettingsKeys.SLOTS_PER_PAGE; i++) {
            boxes.add([0, 0, 0, 0] as Array<Number>);
        }
        _boxes = boxes;
    }

    //! Draw one slot. When suppressed is true only the bounding box is updated
    //! (the editor draws the highlighted slot itself).
    function drawSlot(dc as Dc, skin as Skin, index as Number, source as DataSource, suppressed as Boolean) as Void {
        var x = _width * skin.slotX[index] / 100;
        var y = _height * skin.slotY[index] / 100;
        var w = _width * skin.slotW[index] / 100;
        var align = skin.slotAlign[index];
        var font = skin.slotFont;
        var fontHeight = dc.getFontHeight(font);
        var labelHeight = skin.showLabels ? dc.getFontHeight(skin.slotLabelFont) : 0;

        var box = _boxes[index];
        box[0] = (align == Graphics.TEXT_JUSTIFY_LEFT) ? x : ((align == Graphics.TEXT_JUSTIFY_RIGHT) ? x - w : x - w / 2);
        box[1] = y - fontHeight / 2;
        box[2] = w;
        box[3] = fontHeight + labelHeight;
        if (suppressed) {
            return;
        }

        var value = source.isSupported() ? source.getValue() : Sources.PLACEHOLDER;
        var icon = skin.showIcons ? source.getIcon() : null;
        var textX = x;
        if (icon != null) {
            var iconWidth = icon.getWidth();
            var textWidth = dc.getTextWidthInPixels(value, font);
            var total = iconWidth + ICON_GAP + textWidth;
            var left = (align == Graphics.TEXT_JUSTIFY_LEFT) ? x : ((align == Graphics.TEXT_JUSTIFY_RIGHT) ? x - total : x - total / 2);
            dc.drawBitmap(left, y - icon.getHeight() / 2, icon);
            textX = left + iconWidth + ICON_GAP;
            dc.setColor(skin.resolveColor(skin.slotValueColor), Graphics.COLOR_TRANSPARENT);
            dc.drawText(textX, y, font, value, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        } else {
            dc.setColor(skin.resolveColor(skin.slotValueColor), Graphics.COLOR_TRANSPARENT);
            dc.drawText(textX, y, font, value, align | Graphics.TEXT_JUSTIFY_VCENTER);
        }
        if (skin.showLabels) {
            dc.setColor(skin.resolveColor(skin.slotLabelColor), Graphics.COLOR_TRANSPARENT);
            dc.drawText(x, y + fontHeight / 2 + labelHeight / 2, skin.slotLabelFont, source.getLabel(), align | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }

    //! Slot index under a point, or null.
    function hitTest(x as Number, y as Number) as Number? {
        for (var i = 0; i < _boxes.size(); i++) {
            var box = _boxes[i];
            if (x >= box[0] && x < box[0] + box[2] && y >= box[1] && y < box[1] + box[3]) {
                return i;
            }
        }
        return null;
    }

    //! Last computed bounding box [x, y, w, h] for a slot.
    function getBox(index as Number) as Array<Number> {
        return _boxes[index];
    }

    //! A row of dots, one per page, the active one filled.
    function drawPageIndicator(dc as Dc, skin as Skin, index as Number, count as Number) as Void {
        if (!skin.pageIndicatorVisible || count <= 1) {
            return;
        }
        var radius = (_width * skin.pageIndicatorDotRadius / 100.0).toNumber();
        if (radius < 2) {
            radius = 2;
        }
        var spacing = radius * 3;
        var cx = _width * skin.pageIndicatorX / 100;
        var cy = _height * skin.pageIndicatorY / 100;
        var x = cx - spacing * (count - 1) / 2;
        dc.setColor(skin.resolveColor(skin.pageIndicatorColor), Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1);
        for (var i = 0; i < count; i++) {
            if (i == index) {
                dc.fillCircle(x, cy, radius);
            } else {
                dc.drawCircle(x, cy, radius);
            }
            x += spacing;
        }
    }
}

//! Drawable handed to the on-device editor so it can animate the selected slot.
class SlotHighlightDrawable extends WatchUi.Drawable {
    private var _renderer as SlotRenderer;
    private var _skin as Skin;
    private var _index as Number;
    private var _source as DataSource;

    function initialize(renderer as SlotRenderer, skin as Skin, index as Number, source as DataSource) {
        var box = renderer.getBox(index);
        Drawable.initialize({:locX => box[0], :locY => box[1], :width => box[2], :height => box[3]});
        _renderer = renderer;
        _skin = skin;
        _index = index;
        _source = source;
    }

    function draw(dc as Dc) as Void {
        _renderer.drawSlot(dc, _skin, _index, _source, false);
    }

    function getBoundingBox() as Graphics.BoundingBox {
        var box = new Graphics.BoundingBox();
        box.addRectangle(locX.toNumber(), locY.toNumber(), width.toNumber(), height.toNumber());
        return box;
    }
}
