import Toybox.Lang;
import Toybox.Test;

(:test)
function testEffectRegistryMapsEveryCategory(logger as Logger) as Boolean {
    for (var c = 0; c < WeatherConditions.CATEGORY_COUNT; c++) {
        var effect = EffectRegistry.effectFor(c);
        Test.assertMessage(effect instanceof WeatherEffect, "category " + c + " maps to an effect");
    }
    Test.assertMessage(EffectRegistry.effectFor(WeatherConditions.RAIN) instanceof RainEffect, "rain");
    Test.assertMessage(EffectRegistry.effectFor(WeatherConditions.HEAVY_RAIN) instanceof HeavyRainEffect, "heavy rain");
    Test.assertMessage(EffectRegistry.effectFor(WeatherConditions.SNOW) instanceof SnowEffect, "snow");
    Test.assertMessage(EffectRegistry.effectFor(WeatherConditions.THUNDER) instanceof ThunderEffect, "thunder");
    Test.assertMessage(EffectRegistry.effectFor(WeatherConditions.FOG) instanceof FogEffect, "fog");
    Test.assertMessage(EffectRegistry.effectFor(WeatherConditions.WIND) instanceof WindEffect, "wind");
    Test.assertMessage(EffectRegistry.effectFor(WeatherConditions.CLEAR) instanceof NoEffect, "clear has no effect");
    Test.assertMessage(!EffectRegistry.isAnimated(WeatherConditions.CLOUDY), "cloudy is not animated");
    return true;
}

function stepAndCheck(logger as Logger, category as Number, name as String) as Void {
    var skin = SkinRegistry.load("classic");
    var before = Effects.allocations;
    var effect = EffectRegistry.create(category, 280, 280, skin);
    Test.assertEqualMessage(Effects.allocations, before + 1, name + ": particle arrays allocated exactly once on create");
    for (var i = 0; i < 400; i++) {
        effect.step(166);
    }
    Test.assertEqualMessage(Effects.allocations, before + 1, name + ": no allocation while stepping");
    for (var p = 0; p < effect.getParticleCount(); p++) {
        Test.assertMessage(effect.isInBounds(p), name + ": particle " + p + " stays inside screen bounds and is recycled");
    }
    effect.freeze();
    var frozenCount = effect.getParticleCount();
    effect.step(166);
    Test.assertEqualMessage(effect.getParticleCount(), frozenCount, name + ": freeze keeps the particle set");
    effect.halveParticles();
    Test.assertMessage(effect.getParticleCount() <= (frozenCount + 1) / 2, name + ": halving reduces the active count");
    logger.debug(name + ": " + effect.getAllocatedCount() + " particles, " + effect.getFps() + " fps");
}

(:test)
function testEffectParticlesAllocatedOnceAndStayInBounds(logger as Logger) as Boolean {
    stepAndCheck(logger, WeatherConditions.RAIN, "rain");
    stepAndCheck(logger, WeatherConditions.HEAVY_RAIN, "heavy rain");
    stepAndCheck(logger, WeatherConditions.SNOW, "snow");
    stepAndCheck(logger, WeatherConditions.THUNDER, "thunder");
    stepAndCheck(logger, WeatherConditions.FOG, "fog");
    stepAndCheck(logger, WeatherConditions.WIND, "wind");
    return true;
}
