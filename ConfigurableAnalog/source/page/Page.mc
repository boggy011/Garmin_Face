import Toybox.Lang;

//! Page kinds. Values match the order of page_types in tools/sources.yaml.
module PageTypes {
    enum { GENERIC = 0, WEATHER = 1, HEALTH = 2 }

    function fromId(id as String) as Number {
        var index = SettingsKeys.PAGE_TYPE_IDS.indexOf(id);
        return (index < 0) ? GENERIC : index;
    }
}

//! One page: a type plus a fixed number of slots resolved to DataSources. Only generic
//! pages draw the slots, the other types keep them so the editor ids stay stable.
class Page {
    private var _type as Number;
    private var _sources as Array<DataSource>;

    function initialize(type as Number, sourceIds as Array<String>) {
        _type = type;
        var sources = [] as Array<DataSource>;
        for (var i = 0; i < SettingsKeys.SLOTS_PER_PAGE; i++) {
            var id = (i < sourceIds.size()) ? sourceIds[i] : SettingsKeys.EMPTY_SOURCE_ID;
            sources.add(DataSourceRegistry.get(id));
        }
        _sources = sources;
    }

    function getType() as Number {
        return _type;
    }

    function getSource(slot as Number) as DataSource {
        return _sources[slot];
    }
}
