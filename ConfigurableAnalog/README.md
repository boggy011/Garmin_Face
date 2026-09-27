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
3. Declare the resource in resources/skins/skins.xml as jsonData id skin_NEWID with filename NEWID.json.
4. Add the entry "NEWID" to Rez.JsonData.skin_NEWID in source/skin/SkinRegistry.mc.
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

## Tests

source/tests/Tests.mc contains Toybox.Test functions for settings coercion, page wrap around and clamping, skin JSON parsing and a memory budget check. Run them with "Monkey C: Run Tests" in VS Code or with the commands in SETUP.md.
