import Toybox.Complications;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Test;
import Toybox.Time;

function layoutPage(type as Number, size as Number) as Void {
    DataSourceRegistry.init();
    var skin = SkinRegistry.load("classic");
    Regions.configure(size, size);
    Regions.setMinimumSizePercent(skin.hitboxPaddingPercent);
    var buffer = Graphics.createBufferedBitmap({:width => size, :height => size}).get() as BufferedBitmap;
    var dc = buffer.getDc();
    var renderer = new PageRenderer(size, size);
    var health = new HealthCache();
    health.refresh();
    var now = Time.now().value();
    WeatherCache.refresh(now);
    var pages = new PageManager();
    pages.rebuildTyped([type] as Array<Number>, [SettingsKeys.defaultSlotIds(0)] as Array<Array<String>>);
    pages.setIndex(0);
    Regions.reset();
    renderer.drawStatic(dc, skin, pages.getCurrentPage(), false);
    renderer.draw(dc, skin, pages.getCurrentPage(), pages, null, now, health);
}

(:test)
function testRegionsHitTestInsideAndGaps(logger as Logger) as Boolean {
    Regions.configure(280, 280);
    Regions.setMinimumSizePercent(15);
    var weather = ComplicationLaunch.idForType(Complications.COMPLICATION_TYPE_CURRENT_WEATHER);
    Test.assertMessage(weather != null, "simulator exposes the current weather complication");
    Test.assertMessage(Regions.register(7, 60, 60, 10, 10, weather), "region registered away from the centre");
    Test.assertMessage(Regions.hitTest(60, 60) == 7, "point inside returns the id");
    Test.assertMessage(Regions.hitTest(60 + 20, 60) == 7, "minimum size widens the target to 15 percent");
    Test.assertMessage(Regions.hitTest(60 + 22, 60) == null, "just outside the target is a gap");
    Test.assertMessage(Regions.hitTest(5, 275) == null, "far corner is a gap");
    Test.assertMessage(!Regions.register(8, 140, 140, 10, 10, weather), "a region on the centre circle is refused");
    Test.assertMessage(!Regions.register(9, 65, 65, 10, 10, weather), "an overlapping region is refused");
    Test.assertMessage(!Regions.register(10, 220, 60, 10, 10, null), "a region without launch target is skipped");
    Test.assertMessage(Regions.centerContains(140, 140), "centre contains the middle");
    Test.assertMessage(!Regions.centerContains(140, 140 - 43), "centre circle radius is 15 percent");
    Test.assertEqualMessage(Regions.overlapCount(), 0, "no overlaps in the table");
    return true;
}

(:test)
function testWeatherAndHealthRegionsDoNotOverlap(logger as Logger) as Boolean {
    var sizes = [280, 454] as Array<Number>;
    var types = [PageTypes.WEATHER, PageTypes.HEALTH, PageTypes.GENERIC] as Array<Number>;
    for (var s = 0; s < sizes.size(); s++) {
        for (var t = 0; t < types.size(); t++) {
            layoutPage(types[t], sizes[s]);
            logger.debug("page type " + types[t] + " at " + sizes[s] + " px: " + Regions.getCount() + " regions, " + Regions.getRefusedCount() + " refused");
            Test.assertEqualMessage(Regions.overlapCount(), 0, "page type " + types[t] + ": regions do not overlap each other or the centre");
            Test.assertMessage(Regions.getCount() >= 3, "page type " + types[t] + ": at least three launch regions registered");
        }
    }
    layoutPage(PageTypes.WEATHER, 280);
    Test.assertMessage(Regions.hitTest(140, 140) == null, "weather icon inside the centre circle is not a launch region");
    Test.assertMessage(Regions.hitTest(140, 86) == null, "condition icon above the centre is not a launch region");
    Test.assertMessage(Regions.hitTest(73, 129) == Regions.WEATHER_SUNRISE, "sunrise label on the left is a launch region");
    return true;
}
