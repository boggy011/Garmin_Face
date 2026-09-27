import Toybox.Application;
import Toybox.Application.WatchFaceConfig;
import Toybox.Lang;
import Toybox.WatchUi;

//! Application entry point. Returns the watch face view and its delegate.
class ConfigurableAnalogApp extends Application.AppBase {
    private var _editMode as Boolean = false;
    private var _view as FaceView?;

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state as Dictionary?) as Void {
        var configId = null as WatchFaceConfig.Id?;
        if (state != null) {
            var editing = state[:launchedFromWatchFaceSettingsEditor] as Boolean?;
            _editMode = (editing != null) && editing;
            configId = state[:configId] as WatchFaceConfig.Id?;
        }
        DataSourceRegistry.init();
        Settings.start(configId, _editMode);
    }

    function getInitialView() as [Views] or [Views, InputDelegates] {
        var view = new FaceView();
        _view = view;
        return [view, new FaceDelegate(view, _editMode)];
    }

    //! Phone settings changed. Applied live, no restart.
    function onSettingsChanged() as Void {
        Settings.onPhoneSettingsChanged();
        var view = _view;
        if (view != null) {
            view.reloadSettings();
        }
        WatchUi.requestUpdate();
    }
}
