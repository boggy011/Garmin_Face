import Toybox.Lang;
import Toybox.WatchUi;

//! Maps skin ids to their JSON resources and loads them on demand. Only the active
//! skin is kept in memory. Style ids for the on-device editor are 1-based positions
//! in SettingsKeys.SKIN_IDS, which the generated watchface_config.xml uses too.
module SkinRegistry {
    var _resources as Dictionary<String, ResourceId>?;

    function resources() as Dictionary<String, ResourceId> {
        var map = _resources;
        if (map == null) {
            map = {
                "classic" => Rez.JsonData.skin_classic,
                "minimal" => Rez.JsonData.skin_minimal,
                "sport" => Rez.JsonData.skin_sport
            } as Dictionary<String, ResourceId>;
            _resources = map;
        }
        return map;
    }

    //! Load and parse a skin. Unknown ids fall back to the default skin.
    function load(id as String) as Skin {
        var map = resources();
        var rez = map[id];
        if (rez == null) {
            rez = map[SettingsKeys.DEFAULT_SKIN_ID] as ResourceId;
        }
        var data = WatchUi.loadResource(rez) as Dictionary;
        return new Skin(data);
    }

    function exists(id as String) as Boolean {
        return resources().hasKey(id);
    }

    //! Skin id for an editor style id, or null when out of range.
    function skinIdForStyle(styleId as Number) as String? {
        var index = styleId - 1;
        if (index >= 0 && index < SettingsKeys.SKIN_IDS.size()) {
            return SettingsKeys.SKIN_IDS[index];
        }
        return null;
    }

    //! Editor style id for a skin id (1-based).
    function styleIdForSkin(id as String) as Number {
        return SettingsKeys.SKIN_IDS.indexOf(id) + 1;
    }
}
