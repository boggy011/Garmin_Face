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
