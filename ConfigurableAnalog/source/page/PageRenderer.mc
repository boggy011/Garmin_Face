import Toybox.Graphics;
import Toybox.Lang;

//! Dispatches static and per minute drawing to the renderer of the page's type.
class PageRenderer {
    private var _width as Number;
    private var _height as Number;
    private var _generic as GenericPageRenderer;
    private var _weather as WeatherPageRenderer;
    private var _health as HealthPageRenderer;

    function initialize(width as Number, height as Number) {
        _width = width;
        _height = height;
        _generic = new GenericPageRenderer(width, height);
        _weather = new WeatherPageRenderer(width, height);
        _health = new HealthPageRenderer(width, height);
    }

    //! Static page background, drawn into the cached dial bitmap when the page or skin changes.
    function drawStatic(dc as Dc, skin as Skin, page as Page, night as Boolean) as Void {
        Panels.layout(skin, _width, _height);
        var type = page.getType();
        if (type == PageTypes.WEATHER) {
            _weather.drawStatic(dc, skin, night);
        } else if (type == PageTypes.HEALTH) {
            _health.drawStatic(dc, skin);
        } else {
            _generic.drawStatic(dc, skin);
        }
    }

    //! Dynamic content, once per minute (or per second while awake).
    function draw(dc as Dc, skin as Skin, page as Page, pages as PageManager, selectedUid as Number?, now as Number, health as HealthCache) as Void {
        var type = page.getType();
        if (type == PageTypes.WEATHER) {
            _weather.draw(dc, skin, now);
        } else if (type == PageTypes.HEALTH) {
            _health.draw(dc, skin, health);
        } else {
            _generic.draw(dc, skin, page, pages, selectedUid);
        }
    }

    function getGeneric() as GenericPageRenderer {
        return _generic;
    }

    function getWeather() as WeatherPageRenderer {
        return _weather;
    }
}

//! The five slot page: slots one to four in the diagonal panels, slot five compact below.
class GenericPageRenderer {
    private var _slots as SlotRenderer;

    function initialize(width as Number, height as Number) {
        _slots = new SlotRenderer(width, height);
    }

    //! Panel frames behind the four outer slots.
    function drawStatic(dc as Dc, skin as Skin) as Void {
        for (var i = 0; i < Panels.OUTER_COUNT; i++) {
            Panels.drawFrame(dc, skin, Panels.centreX(i), Panels.centreY(i), Panels.radius());
        }
    }

    function draw(dc as Dc, skin as Skin, page as Page, pages as PageManager, selectedUid as Number?) as Void {
        for (var i = 0; i < SettingsKeys.SLOTS_PER_PAGE; i++) {
            var suppressed = (selectedUid != null) && (selectedUid == pages.uidFor(i));
            _slots.drawSlot(dc, skin, pages.getIndex(), i, page.getSource(i), suppressed);
        }
    }

    function getSlotRenderer() as SlotRenderer {
        return _slots;
    }
}
