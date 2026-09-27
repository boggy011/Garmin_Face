# Changelog

## 1.0.0, 2026-09-27

First store release. Git history for this project consists of the session commits ("update"), so the entries below are written from the delivered features rather than from commit messages.

1. Analog watch face for fenix 8 Solar 51 mm and 47 mm, fenix 8 47 mm and 51 mm, and fenix 8 43 mm, minimum Connect IQ 5.1.
2. Three skins: Classic, Minimal and Sport. Skins define colours, hands (baton, dauphine, arrow, line, skeleton), chapter ring, textures, panels, fonts and page layouts. The dial is rendered once into a cached bitmap.
3. Up to six pages, cycled by holding the centre of the dial, with the current page remembered across restarts. Page types: generic (five readouts), weather and health.
4. Twenty data sources for the generic page, each in a circular panel with icon, value and label, and a rim gauge for percentages. Includes the next calendar event with a scrolling title.
5. Weather page: sun arc with sunrise and sunset, moon arc with the real phase and locally computed moonrise and moonset, stylised condition disc with a large icon, temperature, rain chance, UV, pressure, six hour pressure trend, and a star field at night.
6. Animated weather effects behind the dial while the watch is awake: rain, heavy rain, snow, thunder, fog and wind, with a frame budget that reduces particles automatically.
7. Health page: heart rate in the centre, stress, body battery, pulse ox and HRV panels, two configurable arc gauges.
8. Hold any readout to open its native app. Support for the on device watch face editor (skin as style, complication per field) kept in sync with phone settings.
9. Phone settings for skin, page count and types, slot contents, seconds hand mode, second time zone, pressure unit, health arcs, weather refresh interval, sun time and moon phase labels, effects, and a debug colour swatch grid.
10. Small battery readout on every page.
