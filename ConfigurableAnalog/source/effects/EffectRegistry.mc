import Toybox.Lang;

//! Maps a WeatherConditions category to an effect, so the overlay always agrees with the
//! centre icon.
module EffectRegistry {
    function create(category as Number, width as Number, height as Number, skin as Skin) as WeatherEffect {
        var effect = effectFor(category);
        effect.init(width, height, skin);
        return effect;
    }

    function effectFor(category as Number) as WeatherEffect {
        switch (category) {
            case WeatherConditions.RAIN:
            case WeatherConditions.SLEET:
                return new RainEffect();
            case WeatherConditions.HEAVY_RAIN:
                return new HeavyRainEffect();
            case WeatherConditions.SNOW:
                return new SnowEffect();
            case WeatherConditions.THUNDER:
                return new ThunderEffect();
            case WeatherConditions.FOG:
                return new FogEffect();
            case WeatherConditions.WIND:
                return new WindEffect();
            default:
                return new NoEffect();
        }
    }

    //! True when the category has a visible effect.
    function isAnimated(category as Number) as Boolean {
        return !(effectFor(category) instanceof NoEffect);
    }
}
