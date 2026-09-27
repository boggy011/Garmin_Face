import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Test;
import Toybox.WatchUi;

function usedMemory() as Number {
    return System.getSystemStats().usedMemory;
}

(:test)
function testMemoryProbe(logger as Logger) as Boolean {
    var start = usedMemory();
    logger.debug("baseline " + start);
    var label = WatchUi.loadResource(Rez.Fonts.Label) as FontResource;
    var afterLabel = usedMemory();
    logger.debug("font Label " + (afterLabel - start));
    var value = WatchUi.loadResource(Rez.Fonts.Value) as FontResource;
    var afterValue = usedMemory();
    logger.debug("font Value " + (afterValue - afterLabel));
    var large = WatchUi.loadResource(Rez.Fonts.ValueLarge) as FontResource;
    var afterLarge = usedMemory();
    logger.debug("font ValueLarge " + (afterLarge - afterValue));
    var skin = SkinRegistry.load("classic");
    var afterSkin = usedMemory();
    logger.debug("classic skin retained " + (afterSkin - afterLarge) + " (" + skin.id + ")");
    var sport = SkinRegistry.load("sport");
    logger.debug("plus second skin " + (usedMemory() - afterSkin) + " " + sport.id);
    Test.assertMessage(label != null && value != null && large != null, "fonts alive");
    return true;
}
