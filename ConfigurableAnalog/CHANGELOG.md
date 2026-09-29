# Changelog

## 1.2.0, 2026-09-29

1. Chapter ring and hour numerals moved to the edge of the display on every page; the ticks under the numerals are left out so the numerals fit.
2. Health page: the coloured arc gauges are gone. Panel gauges are a thin light grey line, and a discreet six hour bar chart sits above the 6 with a short label. The chart shows body battery by default; the new "Health page chart" setting picks stress, pulse ox or heart rate instead. It replaces the two health arc settings.
3. Page indicator moved from the bottom to just below the battery readout, since the 6 numeral now sits at the bottom edge. Weather condition icon moved down slightly to make room.

## 1.1.0, 2026-09-29

1. Fix: health page and slot readouts for stress, body battery, pulse ox and heart rate no longer flip to a dash when the newest sensor sample is empty; the newest sample with a value in the recent window is used.
2. Weather page redesign for MIP displays: sun and moon arcs removed, condition icon moved between the 12 numeral and the centre, procedural moon phase with craters and a short phase name between the lower panels, sunrise and sunset labels are the press targets for the sunrise app.
3. Contour dial texture and the dithered condition discs are off on MIP displays (skin keys with a Mip suffix), kept on AMOLED.
4. Battery readout moved up to 18 percent from the top.

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
