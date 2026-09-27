import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Test;
import Toybox.Time;

(:test)
function testSettingsCoerceNumber(logger as Logger) as Boolean {
    Test.assertEqualMessage(Settings.coerceNumber(null, 1, 6, 3), 3, "null falls back");
    Test.assertEqualMessage(Settings.coerceNumber("abc", 1, 6, 3), 3, "non numeric string falls back");
    Test.assertEqualMessage(Settings.coerceNumber(9, 1, 6, 3), 6, "clamped to max");
    Test.assertEqualMessage(Settings.coerceNumber(-4, 1, 6, 3), 1, "clamped to min");
    Test.assertEqualMessage(Settings.coerceNumber("4", 1, 6, 3), 4, "numeric string parsed");
    Test.assertEqualMessage(Settings.coerceNumber(2.7, 1, 6, 3), 2, "float truncated");
    Test.assertEqualMessage(Settings.coerceNumber(true, 1, 6, 3), 3, "boolean falls back");
    return true;
}

(:test)
function testSettingsCoerceChoice(logger as Logger) as Boolean {
    var options = ["skin", "always", "never"] as Array<String>;
    Test.assertEqualMessage(Settings.coerceChoice(1, options, "skin"), "always", "index maps to id");
    Test.assertEqualMessage(Settings.coerceChoice(2.0, options, "skin"), "never", "float index maps to id");
    Test.assertEqualMessage(Settings.coerceChoice("always", options, "skin"), "always", "id string kept");
    Test.assertEqualMessage(Settings.coerceChoice(3, options, "skin"), "skin", "out of range index falls back");
    Test.assertEqualMessage(Settings.coerceChoice(-1, options, "skin"), "skin", "negative index falls back");
    Test.assertEqualMessage(Settings.coerceChoice("bogus", options, "skin"), "skin", "unknown id falls back");
    Test.assertEqualMessage(Settings.coerceChoice(null, options, "skin"), "skin", "null falls back");
    return true;
}

(:test)
function testSettingsCoerceSourceId(logger as Logger) as Boolean {
    DataSourceRegistry.init();
    Test.assertEqualMessage(Settings.coerceSourceId("Steps", "Empty"), "Steps", "registered id kept");
    Test.assertEqualMessage(Settings.coerceSourceId("NoSuchSource", "Empty"), "Empty", "unknown id falls back");
    Test.assertEqualMessage(Settings.coerceSourceId(SettingsKeys.SOURCE_IDS.indexOf("Battery"), "Empty"), "Battery", "index maps to registered id");
    Test.assertEqualMessage(Settings.coerceSourceId(999, "Battery"), "Battery", "out of range index falls back");
    return true;
}

(:test)
function testPageManagerWrapAround(logger as Logger) as Boolean {
    DataSourceRegistry.init();
    var empty = ["Empty", "Empty", "Empty", "Empty", "Empty"] as Array<String>;
    var manager = new PageManager();
    manager.rebuildWith([empty, empty, empty] as Array<Array<String>>);
    manager.setIndex(0);
    Test.assertEqualMessage(manager.getPageCount(), 3, "three pages");
    manager.next();
    manager.next();
    Test.assertEqualMessage(manager.getIndex(), 2, "advanced to last page");
    manager.next();
    Test.assertEqualMessage(manager.getIndex(), 0, "wraps to first page");
    manager.prev();
    Test.assertEqualMessage(manager.getIndex(), 2, "prev wraps to last page");
    manager.rebuildWith([empty, empty] as Array<Array<String>>);
    Test.assertEqualMessage(manager.getIndex(), 0, "clamped to 0 when page count shrinks below index");
    Test.assertEqualMessage(manager.uidFor(4), 15, "editor id encodes page and slot");
    return true;
}

(:test)
function testSkinJsonParsing(logger as Logger) as Boolean {
    var skin = SkinRegistry.load("classic");
    Test.assertEqualMessage(skin.id, "classic", "id parsed");
    Test.assertEqualMessage(skin.backgroundColor, Graphics.COLOR_BLACK, "named colour parsed");
    Test.assertEqualMessage(skin.hourHand.shape, SkinDefs.SHAPE_BATON, "hand shape parsed");
    Test.assertEqualMessage(skin.secondHand.color, SkinDefs.ACCENT_REF, "accent reference parsed");
    Test.assertEqualMessage(skin.resolveColor(skin.secondHand.color), Graphics.COLOR_RED, "accent resolves to skin accent");
    Test.assertEqualMessage(skin.slotX.size(), 5, "five slot positions");
    Test.assertEqualMessage(skin.secondsHandMode, SkinDefs.SECONDS_AWAKE_ONLY, "seconds mode parsed");
    Test.assertEqualMessage(SkinDefs.parseColor("0xFF5500", 0), 0xFF5500, "hex string parsed");
    Test.assertEqualMessage(SkinDefs.parseColor("bogus", 7), 7, "unknown colour falls back");
    var fallback = SkinRegistry.load("no-such-skin");
    Test.assertEqualMessage(fallback.id, SettingsKeys.DEFAULT_SKIN_ID, "unknown skin id loads the default skin");
    var bare = new Skin({});
    Test.assertEqualMessage(bare.slotX.size(), 5, "empty definition still has five slots");
    Test.assertEqualMessage(bare.numeralStyle, SkinDefs.NUMERALS_QUARTERS, "empty definition uses defaults");
    return true;
}

(:test)
function testMemoryBudget(logger as Logger) as Boolean {
    DataSourceRegistry.init();
    var skin = SkinRegistry.load("sport");
    var manager = new PageManager();
    manager.rebuildWith(SettingsKeys.DEFAULT_SLOTS);
    var stats = System.getSystemStats();
    logger.debug("skin " + skin.id + ", memory used " + stats.usedMemory + " of " + stats.totalMemory + " bytes, free " + stats.freeMemory);
    Test.assertMessage(stats.freeMemory > 8192, "at least 8 KB free after loading a skin and every page");
    return true;
}

(:test)
function testPageTypesMatchGeneratedOrder(logger as Logger) as Boolean {
    Test.assertEqualMessage(PageTypes.fromId("generic"), PageTypes.GENERIC, "generic is 0");
    Test.assertEqualMessage(PageTypes.fromId("weather"), PageTypes.WEATHER, "weather is 1");
    Test.assertEqualMessage(PageTypes.fromId("health"), PageTypes.HEALTH, "health is 2");
    Test.assertEqualMessage(PageTypes.fromId("bogus"), PageTypes.GENERIC, "unknown ids fall back to generic");
    Test.assertEqualMessage(SettingsKeys.PAGE_TYPE_IDS.size(), 3, "three page types generated");
    Test.assertEqualMessage(Settings.coerceBoolean(null, true), true, "null boolean falls back");
    Test.assertEqualMessage(Settings.coerceBoolean(0, true), false, "0 is false");
    Test.assertEqualMessage(Settings.coerceBoolean("true", false), true, "string true");
    return true;
}

(:test)
function testPageRenderersDrawEveryPageType(logger as Logger) as Boolean {
    DataSourceRegistry.init();
    var skin = SkinRegistry.load("classic");
    var buffer = Graphics.createBufferedBitmap({:width => 280, :height => 280}).get() as BufferedBitmap;
    var dc = buffer.getDc();
    var renderer = new PageRenderer(280, 280);
    var health = new HealthCache();
    health.refresh();
    var now = Time.now().value();
    WeatherCache.refresh(now);
    var pages = new PageManager();
    var types = [PageTypes.GENERIC, PageTypes.WEATHER, PageTypes.HEALTH] as Array<Number>;
    var slots = [SettingsKeys.DEFAULT_SLOTS[0], SettingsKeys.DEFAULT_SLOTS[1], SettingsKeys.DEFAULT_SLOTS[2]] as Array<Array<String>>;
    pages.rebuildTyped(types, slots);
    for (var i = 0; i < 3; i++) {
        pages.setIndex(i);
        var page = pages.getCurrentPage();
        Test.assertEqualMessage(page.getType(), types[i], "page " + i + " has the requested type");
        renderer.drawStatic(dc, skin, page);
        renderer.draw(dc, skin, page, pages, null, now, health);
    }
    logger.debug("weather category " + WeatherCache.category + ", moon phase " + WeatherCache.moonPhase + " (" + WeatherCache.moonPhaseLabel + "), rise " + WeatherCache.moonRise + " set " + WeatherCache.moonSet);
    return true;
}
