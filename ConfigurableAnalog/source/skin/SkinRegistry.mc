import Toybox.Lang;
import Toybox.WatchUi;

//! Maps skin ids to their JSON resources and loads them on demand. Each skin is three
//! resources (core, layout, pages) parsed one after the other so only a third of the
//! definition is in memory as a dictionary at any time. Only the active skin is kept.
//! Style ids for the on-device editor are 1-based positions in SettingsKeys.SKIN_IDS.
module SkinRegistry {
    var _resources as Dictionary<String, Array<ResourceId>>?;

    function resources() as Dictionary<String, Array<ResourceId>> {
        var map = _resources;
        if (map == null) {
            map = {
                "classic" => [Rez.JsonData.skin_classic, Rez.JsonData.skin_classic_layout, Rez.JsonData.skin_classic_pages] as Array<ResourceId>,
                "minimal" => [Rez.JsonData.skin_minimal, Rez.JsonData.skin_minimal_layout, Rez.JsonData.skin_minimal_pages] as Array<ResourceId>,
                "sport" => [Rez.JsonData.skin_sport, Rez.JsonData.skin_sport_layout, Rez.JsonData.skin_sport_pages] as Array<ResourceId>
            } as Dictionary<String, Array<ResourceId>>;
            _resources = map;
        }
        return map;
    }

    //! Load and parse a skin. Unknown ids fall back to the default skin.
    function load(id as String) as Skin {
        var map = resources();
        var rez = map[id];
        if (rez == null) {
            rez = map[SettingsKeys.DEFAULT_SKIN_ID] as Array<ResourceId>;
        }
        var skin = new Skin(WatchUi.loadResource(rez[0]) as Dictionary);
        skin.parseLayout(WatchUi.loadResource(rez[1]) as Dictionary);
        skin.parsePages(WatchUi.loadResource(rez[2]) as Dictionary);
        return skin;
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
