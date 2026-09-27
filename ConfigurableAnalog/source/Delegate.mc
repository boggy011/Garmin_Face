import Toybox.Application.WatchFaceConfig;
import Toybox.Lang;
import Toybox.WatchUi;

//! Input handling: hold on the dial centre cycles pages, editor callbacks map slots.
class FaceDelegate extends WatchUi.WatchFaceDelegate {
    private var _view as FaceView;
    private var _editMode as Boolean;

    function initialize(view as FaceView, editMode as Boolean) {
        WatchFaceDelegate.initialize();
        _view = view;
        _editMode = editMode;
    }

    //! Touch and hold. The centre region cycles pages, any other registered region opens
    //! the native app of its complication.
    function onPress(clickEvent as ClickEvent) as Boolean {
        var coords = clickEvent.getCoordinates();
        if (Regions.centerContains(coords[0], coords[1])) {
            _view.nextPage();
            WatchUi.requestUpdate();
            return true;
        }
        var regionId = Regions.hitTest(coords[0], coords[1]);
        if (regionId != null) {
            var launch = Regions.launchIdFor(regionId);
            if (launch != null && ComplicationLaunch.launch(launch)) {
                return true;
            }
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
