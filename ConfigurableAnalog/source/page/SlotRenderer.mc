import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

//! Draws slot values at skin defined positions and the page indicator.
//! Records each slot's bounding box for tap hit testing in the on-device editor.
class SlotRenderer {
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

    //! Draw one slot: slots one to four inside their diagonal panel (icon, value, label, optional
    //! gauge for percentage sources), slot five as a compact stack below. When suppressed is true
    //! only the bounding box and press region are updated (the editor draws the slot itself).
    function drawSlot(dc as Dc, skin as Skin, pageIndex as Number, index as Number, source as DataSource, suppressed as Boolean) as Void {
        var x = Panels.centreX(index);
        var y = Panels.centreY(index);
        var inPanel = index < Panels.OUTER_COUNT;
        var r = Panels.radius();
        var w = inPanel ? 2 * r : Panels.fifthWidth();
        var h = inPanel ? 2 * r : dc.getFontHeight(skin.slotFont) + dc.getFontHeight(skin.slotLabelFont);
        var box = _boxes[index];
        box[0] = x - w / 2;
        box[1] = y - h / 2;
        box[2] = w;
        box[3] = h;
        var target = inPanel ? Panels.targetSide() : w;
        Regions.register(SettingsKeys.complicationUid(pageIndex, index), x, y, target, inPanel ? target : h, ComplicationLaunch.idForType(source.getComplicationType()));
        if (suppressed) {
            return;
        }
        var value = source.isSupported() ? source.getValue() : Sources.PLACEHOLDER;
        var icon = skin.showIcons ? source.getIcon() : null;
        var label = (skin.showLabels && !source.getId().equals(SettingsKeys.EMPTY_SOURCE_ID)) ? source.getShortLabel() : null;
        var dynamicLabel = source.getDynamicLabel();
        if (dynamicLabel != null && label != null) {
            label = dynamicLabel;
        }
        var valueColor = skin.resolveColor(skin.slotValueColor);
        var labelColor = skin.resolveColor(skin.slotLabelColor);
        if (inPanel) {
            var percent = source.getPercent();
            if (skin.panels().gauge && percent != null) {
                Panels.drawGauge(dc, skin, x, y, r, percent, source.getId().equals("Stress"));
            }
            Panels.drawContent(dc, skin, x, y, r, icon, value, label, valueColor, labelColor, false);
        } else {
            Panels.drawContent(dc, skin, x, y, h / 2, null, value, label, valueColor, labelColor, false);
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
    private var _pageIndex as Number;
    private var _index as Number;
    private var _source as DataSource;

    function initialize(renderer as SlotRenderer, skin as Skin, pageIndex as Number, index as Number, source as DataSource) {
        var box = renderer.getBox(index);
        Drawable.initialize({:locX => box[0], :locY => box[1], :width => box[2], :height => box[3]});
        _renderer = renderer;
        _skin = skin;
        _pageIndex = pageIndex;
        _index = index;
        _source = source;
    }

    function draw(dc as Dc) as Void {
        _renderer.drawSlot(dc, _skin, _pageIndex, _index, _source, false);
    }

    function getBoundingBox() as Graphics.BoundingBox {
        var box = new Graphics.BoundingBox();
        box.addRectangle(locX.toNumber(), locY.toNumber(), width.toNumber(), height.toNumber());
        return box;
    }
}
