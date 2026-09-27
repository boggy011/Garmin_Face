import Toybox.Application;
import Toybox.Lang;

//! Current page index with wrap around navigation and persistence in Storage.
class PageManager {
    const STORAGE_KEY = "currentPage";

    private var _index as Number = 0;
    private var _pages as Array<Page> = [] as Array<Page>;

    function initialize() {
    }

    //! Restore the persisted page index. Call once from View.onLayout.
    function restore() as Void {
        var stored = Storage.getValue(STORAGE_KEY);
        if (stored instanceof Number) {
            _index = stored;
        }
        clamp();
    }

    //! Rebuild pages from Settings.
    function rebuild() as Void {
        var count = Settings.getPageCount();
        var slots = [] as Array<Array<String>>;
        var types = [] as Array<Number>;
        for (var p = 0; p < count; p++) {
            slots.add(Settings.getPageSlots(p));
            types.add(Settings.getPageType(p));
        }
        rebuildTyped(types, slots);
    }

    //! Rebuild generic pages from explicit slot ids, one array per page.
    function rebuildWith(slotsByPage as Array<Array<String>>) as Void {
        var types = [] as Array<Number>;
        for (var p = 0; p < slotsByPage.size(); p++) {
            types.add(PageTypes.GENERIC);
        }
        rebuildTyped(types, slotsByPage);
    }

    //! Rebuild pages from explicit types and slot ids.
    function rebuildTyped(types as Array<Number>, slotsByPage as Array<Array<String>>) as Void {
        var pages = [] as Array<Page>;
        for (var p = 0; p < slotsByPage.size(); p++) {
            pages.add(new Page(types[p], slotsByPage[p]));
        }
        _pages = pages;
        clamp();
    }

    function getPageCount() as Number {
        return _pages.size();
    }

    function getIndex() as Number {
        return _index;
    }

    function setIndex(index as Number) as Void {
        if (index >= 0 && index < _pages.size() && index != _index) {
            _index = index;
            persist();
        }
    }

    //! Advance, wrapping from the last page to the first.
    function next() as Void {
        var count = _pages.size();
        if (count == 0) {
            return;
        }
        _index = (_index + 1) % count;
        persist();
    }

    //! Go back, wrapping from the first page to the last. Unused by the UI, kept for completeness.
    function prev() as Void {
        var count = _pages.size();
        if (count == 0) {
            return;
        }
        _index = (_index + count - 1) % count;
        persist();
    }

    function getCurrentPage() as Page {
        if (_pages.size() == 0) {
            return new Page(PageTypes.GENERIC, [] as Array<String>);
        }
        return _pages[_index];
    }

    //! Editor complication id for a slot on the current page.
    function uidFor(slot as Number) as Number {
        return SettingsKeys.complicationUid(_index, slot);
    }

    //! Clamp to page 0 when the page count dropped below the current index.
    private function clamp() as Void {
        if (_index < 0 || _index >= _pages.size()) {
            _index = 0;
            persist();
        }
    }

    private function persist() as Void {
        Storage.setValue(STORAGE_KEY, _index);
    }
}
