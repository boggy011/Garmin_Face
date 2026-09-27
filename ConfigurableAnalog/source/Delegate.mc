import Toybox.Application.WatchFaceConfig;
import Toybox.Lang;
import Toybox.WatchUi;

//! Tap regions on the dial that are not data slots.
module HitRegions {
    const CENTER = 1;
    const CENTER_DIAMETER_PERCENT = 30;

    var _cx as Number = 0;
    var _cy as Number = 0;
    var _radiusSquared as Number = 0;

    function configure(width as Number, height as Number) as Void {
        _cx = width / 2;
        _cy = height / 2;
        var radius = width * CENTER_DIAMETER_PERCENT / 200;
        _radiusSquared = radius * radius;
    }

    function contains(id as Number, x as Number, y as Number) as Boolean {
        if (id == CENTER) {
            var dx = x - _cx;
            var dy = y - _cy;
            return dx * dx + dy * dy <= _radiusSquared;
        }
        return false;
    }
}

//! Input handling: hold on the dial centre cycles pages, editor callbacks map slots.
class FaceDelegate extends WatchUi.WatchFaceDelegate {
    private var _view as FaceView;
    private var _editMode as Boolean;

    function initialize(view as FaceView, editMode as Boolean) {
        WatchFaceDelegate.initialize();
        _view = view;
        _editMode = editMode;
    }

    //! Touch and hold. Inside the centre region cycles to the next page.
    function onPress(clickEvent as ClickEvent) as Boolean {
        var coords = clickEvent.getCoordinates();
        if (HitRegions.contains(HitRegions.CENTER, coords[0], coords[1])) {
            _view.nextPage();
            WatchUi.requestUpdate();
            return true;
        }
        return false;
    }

    function onPowerBudgetExceeded(powerInfo as WatchFacePowerInfo) as Void {
        _view.disablePartialUpdates();
    }

    //! Editor mode only: a tap on a slot selects that complication.
    function onTap(clickEvent as ClickEvent) as Boolean {
        if (!_editMode) {
            return false;
        }
        var coords = clickEvent.getCoordinates();
        var uid = _view.getTappedComplicationUid(coords[0], coords[1]);
        if (uid != null) {
            setSelectedComplication(uid);
            return true;
        }
        return false;
    }

    function getComplicationDrawable(complication as ComplicationRef) as Drawable or ComplicationDrawableRef or Null {
        return _view.getComplicationHighlight(complication);
    }

    function onWatchFaceConfigEdited(options as {:configId as WatchFaceConfig.Id, :type as WatchFaceConfigType?, :committed as Boolean}) as Void {
        var configId = options[:configId] as WatchFaceConfig.Id?;
        var committed = options[:committed] as Boolean?;
        var type = options[:type] as WatchFaceConfigType?;
        Settings.onDeviceConfigEdited(configId, (committed != null) && committed);
        _view.onEditorChanged(type);
    }
}
