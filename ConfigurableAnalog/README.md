# ConfigurableAnalog

Data driven analog watch face for the fenix 8 family, written in Monkey C with strict type checking.
Rendering code reads a skin definition (JSON resource) and a page definition (settings) and draws.
Adding a skin or a data source never touches the renderer.

Targets: fenix8solar51mm (primary), fenix8solar47mm, fenix847mm, fenix843mm. Minimum API level 5.0.0.

## Layout

source/App.mc returns the view and delegate. source/View.mc orchestrates drawing, sleep state and partial updates.
source/Delegate.mc handles hold to cycle pages and the on-device editor callbacks, plus the HitRegions module.
source/skin holds Skin (parsed JSON), SkinRegistry (id to resource) and AnalogRenderer (dial, ticks, numerals, hands).
source/page holds Page (five slots), PageManager (index, wrap around, persistence) and SlotRenderer (values, icons, labels, page indicator).
source/data holds DataSource (base class and shared helpers), DataSourceRegistry and one file per source under sources/.
source/settings holds Settings (validated accessors over phone settings merged with the on-device editor) and the generated SettingsKeys.
resources/skins holds one JSON per skin, resources/settings and resources/strings/generated_strings.xml are generated.
resources-round-WxH folders only override the launcher icon at each screen's native size.
tools/sources.yaml is the single source of truth for sources, skins, defaults and settings. tools/gen_settings.py renders it.

## How to add a skin

1. Copy resources/skins/classic.json to resources/skins/NEWID.json and set "id" to NEWID.
2. Edit the fields. Colours are Graphics.COLOR_* names, "0xRRGGBB" values from the 64 colour MIP palette (each channel 00, 55, AA or FF), or "accent" to follow the accent colour. Fonts are Graphics.FONT_* names. Positions are percent of the screen. Hand shapes are baton, dauphine, arrow or line. secondsHandMode is always, awakeOnly or never. pageIndicator.visible may be false.
3. Run python3 tools/gen_settings.py: it splits the file into resources/skins/gen/NEWID_core.json and NEWID_pages.json and rewrites resources/skins/skins.xml (never edit those three by hand).
4. Add "NEWID" => [Rez.JsonData.skin_NEWID, Rez.JsonData.skin_NEWID_pages] to source/skin/SkinRegistry.mc.
5. Append the skin (id and label) to skins in tools/sources.yaml. Append only, phone settings store the position in the list.
6. Run python3 tools/gen_settings.py and build. The generator rejects colours outside the palette and missing registry entries.

## How to add a data source

1. Create source/data/sources/NewId.mc with class NewIdSource extends DataSource. Call DataSource.initialize(Rez.Strings.src_NewId, Rez.Drawables.icon_newid) or pass null for no icon. Override getId to return "NewId" and getValue to return a formatted String or Sources.PLACEHOLDER. Override isSupported with has checks when the API may be missing. Override getComplicationType when a Toybox.Complications type matches, this is what the on-device editor can select.
2. Optionally add resources/drawables/icon_newid.svg (white on transparent, 22 px) and declare it in resources/drawables/drawables.xml.
3. Register it in source/data/DataSourceRegistry.mc with register(new NewIdSource()).
4. Append the source (id, label, complication or null) to sources in tools/sources.yaml. Append only.
5. Run python3 tools/gen_settings.py and build. The generator fails when the class file or the registry entry is missing.

## How settings map to code

Phone settings live in resources/settings/properties.xml and settings.xml, both generated. Connect IQ list settings only work on number properties, so every choice is stored as a 0-based index into the matching list in SettingsKeys.mc: skinId into SKIN_IDS, secondsHandMode into SECONDS_HAND_MODES, pageNslotM into SOURCE_IDS. The order of those lists is the order in tools/sources.yaml, which is why entries are append only.

Settings.reload reads every property through coerceChoice (index or id string, else default), coerceNumber (clamped, else default) and coerceSourceId (must be registered). pageCount is clamped to 1 to 6. Application.onSettingsChanged calls Settings.onPhoneSettingsChanged and View.reloadSettings, so changes apply without restart.

PageManager.rebuild asks Settings.getPageSlots(page) for each active page and builds Page objects whose slots resolve through DataSourceRegistry.get(id). View.onUpdate draws the five slots of the current page at the positions the skin defines. Slot content therefore comes from settings, slot placement from the skin.

secondsHandMode "skin" defers to the skin JSON, any other value overrides it. secondTimeZoneOffsetMinutes is read by SecondTimeZoneSource.

## On-device editor

resources/settings/watchface_config.xml is generated. Styles 1 to N are the skins in list order. Each slot is a complication with id page times 10 plus slot (1-based), allowing every source that has a complication mapping, with the page default marked as default. Data colour and accent colour are allowAny.

Settings merges WatchFaceConfig.getSettings over the phone properties with last writer wins. A phone change marks phone as the source, a committed on-device edit marks device as the source and mirrors skin and slots back into Properties so the phone shows the same values. In editor mode the device config is always shown live. The delegate maps taps to slots through SlotRenderer bounding boxes and hands the editor a SlotHighlightDrawable. Sources without a complication mapping (Empty, Distance, SecondTimeZone) can only be chosen from the phone.

## Navigation

Touch and hold inside the dial centre (a circle of 30 percent of the screen diameter, HitRegions.CENTER) calls PageManager.next, which wraps from the last page to the first. The index is persisted in Application.Storage under "currentPage" and restored in View.onLayout. There is no auto return. The page indicator draws one dot per active page at the skin position.

## Power

The static dial is drawn once per skin load into a BufferedBitmap with a palette limited to the dial colours. Each minute the view blits the dial, draws slots and hands into a second full screen buffer and copies it to the screen. In low power mode the seconds hand is drawn by onPartialUpdate inside a clip rectangle around the hand, restoring the previous area from the face buffer, only when the effective seconds mode is always. When the system reports the power budget exceeded, partial updates stop. Hand polygons use preallocated point arrays. The only per update allocations are the value strings the data sources format.

## Icons

Page icons are authored as SVG under assets/icons/src (64 px artboard, 2 px strokes, light palette, transparent background) and rasterised per device by tools/gen_icons.py from tools/icons.yaml, which maps every icon to a size group in percent of the screen width. Output goes to resources-DEVICE/drawables/ic_NAME.png plus a generated icons.xml. MIP devices get colours snapped to the 64 colour palette and one bit alpha.

To add an icon:

1. Draw assets/icons/src/NAME.svg in the same style.
2. Add NAME to icons in tools/icons.yaml with a size group (or add a group).
3. Run uv run tools/gen_icons.py (uv installs cairosvg, pillow and pyyaml in an isolated environment). Without uv, install cairosvg or rsvg-convert and run python3 tools/gen_icons.py.
4. Reference Rez.Drawables.ic_NAME from an IconSet in the renderer that needs it.

The generic page slot icons under resources/drawables are plain white SVGs and are not part of this pipeline.

## Pages

Page types are generic (five slots), weather and health, chosen per page with the pageNtype setting. The weather page shows the condition icon between the 12 numeral and the centre (over a stylised sky disc on AMOLED only), the moon phase below the centre drawn procedurally by MoonPhase.mc (Astronomy.mc computes phase, moonrise and moonset locally) with a short phase name, sunrise and sunset times, four readouts (temperature, precipitation chance, UV, pressure) and the pressure trend, refreshed at most every weatherRefreshMinutes into WeatherCache. Skin keys with a Mip suffix (textureMip, conditionBackgroundMip, moonLitColorMip, moonCraterColorMip) override the plain key on MIP displays, which is how the contour texture and the dithered discs stay off the reflective screens. The health page shows heart rate and four readouts with thin single colour rim gauges, plus a discreet six hour chart of the metric chosen in the healthChart setting (body battery, stress, pulse ox or heart rate), refreshed once per minute into HealthCache (the chart every ten minutes). HRV comes from a system complication when the device exposes one. Weather effects (rain, heavy rain, snow, thunder, fog, wind) animate on the weather page while awake, particle counts and frame rate come from the skin's effects block and the effectsIntensity setting.

Holding a readout opens its native app through Complications.exitTo. Regions are registered by the renderers (Regions.mc), never overlap the centre cycling circle, and sized to at least hitboxPaddingPercent of the screen width.

The generic page's NextEvent source reads the system calendar complication (time as the value, event title as the label). Every page carries a small battery readout at the top (skin block battery). Weather effects draw behind the chapter ring, numerals, panel contents and hands.

## Skin options for depth and panels

The dial block of a skin pre renders depth into the cached dial bitmap: texture (none, sunburst, concentricRings, crosshatch, dotGrid), chapterRing (minute track with long fifth marks in the silver numeral colour, optional accentQuadrant 0 to 3), innerBezel, subdialFrames, handShadow and centreCap. Hands may use the shapes baton, dauphine, arrow, line and skeleton (silver outline with a dark cut out); the seconds hand may carry a counterweight.

The panels block defines the circular readout panels: diameter and centreDiameter in percent of the screen, fill, rim and tickColor, gauge on or off with gaugeLow/Medium/High colours and thresholds, spacing, and the fonts (valueFont, largeValueFont, labelFont). Fonts are Graphics.FONT_* names or @Value, @ValueLarge and @Label, the bitmap fonts rendered by tools/gen_fonts.py from tools/fonts.yaml. Panel positions are never written in a skin: PanelSkin.layoutRadius places the four outer panels on the diagonals at a radius that keeps them clear of the centre element, of each other and of the chapter ring, on every screen size.

Colour rule: each skin has one accent colour, used by the seconds hand, the active page dot, the top health arc, the temperature value, the pressure bars above the baseline and the centre cap core. Numerals and major ticks are the silver 0xAAAAAA, the only silver on the 64 colour palette. See docs/design-notes.md for the reasoning and the reference faces.

## Tools

tools/gen_settings.py renders settings, strings, editor config and SettingsKeys.mc from tools/sources.yaml. tools/gen_icons.py rasterises icons. tools/simrun.py runs a .prg in the simulator for a bounded time, prints its console output and takes timed screenshots (uv run tools/simrun.py bin/x.prg fenix8solar51mm --shots "generic@5"). tools/screenshot.py captures the simulator window into docs/screens. probe.jungle builds a variant that cycles pages and forces weather conditions while logging memory and frame times.

## Tests

source/tests/Tests.mc contains Toybox.Test functions for settings coercion, page wrap around and clamping, skin JSON parsing and a memory budget check. Run them with "Monkey C: Run Tests" in VS Code or with the commands in SETUP.md.
