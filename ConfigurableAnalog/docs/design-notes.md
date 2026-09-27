# Design notes

Pass 1, 2026-09-27. Patterns seen in reference analog faces and what this face adopts.

## References reviewed

1. SwissRailwayClock (ahuggel, GitHub). Iconic Swiss railway dial: black batons on white, thick minute track with every fifth mark longer, red lollipop seconds hand, no numerals. README confirms a ticking (not sweeping) always on seconds hand on MIP, a 3D effect option, dark mode, and on device settings. Pattern taken: strong minute track with long fifth marks, a single accent colour reserved for the seconds hand.
2. Aviatorlike (shortattentionspan fork of Oliver Bar's Aviator-like). Aviation style: outer chapter ring with numerals, inner 24 hour or minute ring, sub dial style data panels, features can be overlaid on the hands. Pattern taken: chapter ring plus sub dial panels for data, hands that stay readable over data.
3. ElPrimero (Zenith El Primero homage on the Connect IQ store). Chronograph layout: three overlapping sub dials at 3, 6 and 9 with contrasting fills and thin rims, tachymeter style outer ring, baton hands with lume, thin seconds hand with counterweight. Pattern taken: dark sub dial panels with a lighter rim, counterweighted seconds hand.
4. Sundance. Analog face known for its sunrise to sunset arc with a sun marker and day and night halves. Pattern taken: the sun arc on the weather page was already modelled on this, the night star field and larger moon come from the same idea.
5. Crystal (warmsound, GitHub). Digital, not analog, but the most installed Connect IQ face: LCD style goal meters on the flanks, icon above value data fields, one accent colour per theme, strict use of the device palette. Pattern taken: icon stacked above the value, one accent colour per skin, palette discipline.
6. Store and guide picks for fenix 8 (WatchFaceKit guide, Android Authority, Wareable): Rondo Analog, SHN Analog, Classic Nine, 4Nine, Samurai Style. Common traits: textured dark dials (titanium, Damascus steel, sunburst), silver numerals and markers rather than pure white, a steel hand set with one coloured seconds hand, a date or data window at 3 or 6, sub dial panels with rims, and a chapter ring near the bezel. Pattern taken: silver markers, dial texture, chapter ring, panels.

Sources: github.com/ahuggel/SwissRailwayClock, github.com/shortattentionspan/Aviatorlike, github.com/warmsound/crystal-face, watchfacekit.com/guides/best-watch-faces-fenix-8/, androidauthority.com/garmin-watch-faces-3063702/, wareable.com/features/best-garmin-watch-faces-to-download-7227. Store pages were not fetched directly (the store is dynamic), descriptions come from the guides and the projects' own READMEs.

## Adopted in this pass

1. Silver markers. Numerals and major ticks use one silver value defined per skin (numeralColor, tickMajorColor). On the 64 colour MIP palette the only silver is 0xAAAAAA (channel values are limited to 00, 55, AA, FF, so 0xC0C0C0 rounds to 0xAAAAAA and 0xCCCCCC is not representable). AMOLED skins can use any value, they keep 0xAAAAAA for consistency.
2. Dial texture pre rendered into the cached dial bitmap: sunburst (radial lines alternating two near shades), concentric rings (dithered, the MIP stand in for a gradient), crosshatch, dot grid, or none. Zero cost per minute because the texture lives in the BufferedBitmap that is drawn once per skin or page change.
3. Chapter ring near the bezel with a minute track (short mark per minute, long mark every five minutes) and hour numerals just inside it.
4. Inner bezel circle separating the readout area from the dial.
5. Sub dial frames behind readouts: dark fill, one pixel lighter rim.
6. Hand shadow: the hand polygon drawn once more, offset by one pixel in a darker colour, under the hand. Drawn per minute together with the hands, cost is one extra polygon per hand.
7. Centre cap over the hand pivot.
8. Icon above value on every readout (Crystal style), values centred.

## Rejected or deferred

1. Gradients and translucency: not representable on MIP, replaced by dithered rings and lines.
2. Lume or glow on hands: would need alpha blending, costly on MIP, deferred.
3. Overlaying data on the hands (Aviatorlike): conflicts with the hold to cycle centre region and readability, not adopted.
4. Ticking seconds hand in low power on AMOLED: the platform does not allow it, the seconds hand stays high power only on AMOLED.

## Skin assignments

1. classic: sunburst, chapter ring, sub dial frames, hand shadow, centre cap.
2. minimal: inner bezel and centre cap only.
3. sport: crosshatch, chapter ring, bold accent on the active page indicator dot, centre cap.

## Pass 1 findings (bug fixes)

1. Sun and moon visibility. The horizon logic now lives in SkyState (pure functions, tested for Belgrade midday and midnight). A body is drawn only while it is between its rise and set, with the set before rise case (moon up across midnight) handled explicitly. The simulator itself was misleading: its weather location is Garmin's home in Kansas while the clock runs in the Mac's time zone, so "sunrise 2:09, sunset 2:11" were the Kansas times rendered in a 12 hour clock without an AM or PM marker. The debug build now logs now, sunrise, sunset, moonrise and moonset in UTC seconds at every refresh.
2. Readouts. One ReadoutRenderer stacks icon above value above label, centred. The side by side code is gone.
3. Numerals. The off colour was not a colour value at all: text drawn into a BufferedBitmap that was created with a palette does not render correctly (missing on MIP, wrong colour on AMOLED). The dial buffer is created without a palette now. Numerals and major ticks are 0xAAAAAA (COLOR_LT_GRAY), the only silver on the 64 colour palette.

## Simulator measurements after pass 1

Frame draw time of the weather effect overlay (simulator, not device), particles at normal intensity.
fenix8solar51mm at 6 fps (budget 166 ms): rain 40 particles 34 to 71 ms, heavy rain 64 particles 79 to 132 ms, snow 30 particles 42 to 61 ms, thunder flash frame 215 ms once (over budget, particles halved to 20 for the session as designed), fog 32 ms, wind 32 ms.
fenix847mm at 10 fps (budget 100 ms): rain 80 particles 4 to 7 ms, heavy rain 128 particles 6 to 13 ms, snow 60 particles 14 to 25 ms, thunder 5 to 8 ms, fog 1 to 5 ms.
Peak app memory: 104968 bytes on fenix8solar51mm and 105952 bytes on fenix847mm of the 126792 byte watch face limit. The MIP simulator renders slowly, real device timings will differ, the budget check protects either way.

## Pass 2 (reference face patterns)

1. Sub dial panels. Every readout sits in a circular panel: near black fill, one pixel rim in the skin's panel rim colour, twelve tick marks on the rim. Icon in the upper third, value in the middle, uppercase label in the lower third. Panel diameter is a skin value (24 percent of the screen by default, 34 for the health centre panel). Percentage sources (battery, body battery, stress, pulse ox) get a rim gauge from 7 o'clock clockwise to 5 o'clock in the skin's low, medium and high band colours.
2. Layout rule. The four outer panels sit on the 45, 135, 225 and 315 degree diagonals at a radius computed in PanelSkin.layoutRadius: far enough from the centre element (centre diameter plus panel diameter plus spacing, all halves), far enough from each other (diameter plus spacing over the square root of two), and never past the chapter ring. With the shipped values this is 32 percent of the screen width, so the same rule places the panels on 260, 280, 416 and 454 px screens without any pixel constants. The fifth generic slot is a compact stack directly below the bottom pair, in the gap between them.
3. Chapter ring. Minute track on the outer ring, every fifth mark longer and in the silver numeral colour, quarter numerals just inside the ring at 87 percent of the dial radius in the same silver. accentQuadrant tints one 15 minute quadrant of the ring in the accent colour, off (-1) in all three skins.
4. Hands. New skeleton shape: baton outline in silver with a dark cut out, used for classic. Seconds hand thin in the accent colour with a counterweight disc on the tail. Centre cap: outer silver disc, inner accent disc. Hand shadow stays for classic.
5. Accent discipline. One accent per skin (classic red, sport orange, minimal white). It is used only by the seconds hand and counterweight, the active page indicator dot, the top health arc (body battery), the temperature value on the weather page, the pressure bars above the baseline, and the centre cap core.
6. Weather page. Sunrise time with icon on the left and sunset on the right, level with the arc ends and above the centre icon. Pressure trend chart below the panels: twelve half hour bars from six hours of SensorHistory pressure, baseline at the six hour mean, accent above, muted below, 40 by 8 percent of the screen. Night mode (sun below the horizon): thirty fixed stars in the top half, seeded from the screen width once per renderer, drawn into the cached dial, and the moon at 18 percent with its phase shading. Day mode: no stars, the sun disc with two dithered glow rings.
7. Health page. Centre heart rate panel with heart icon above the value and BPM below, four panels around it, body battery and stress with rim gauges. The centre panel doubles as the hold to cycle region, so heart rate itself is not a launch target, the outer panels are.
8. Typography. Oswald Medium (OFL) for values, Roboto Condensed Bold (Apache 2.0) uppercase for labels, rasterised per device by tools/gen_fonts.py into resources-DEVICE/fonts at 8.2, 16 and 4.6 percent of the screen width. One bit glyphs on MIP, anti aliased on AMOLED. The generator checks that "100%", "-12°", "1013", "29.92" and "88:88" fit inside a panel on every device and fails the build script when they do not.

Known compromises: the sun and moon arcs at 46 percent brush the 3 and 9 numerals, the moon phase name only appears while the moon is up and uses the small system font so it fits between the bottom panels, and the weather icon inside the centre circle cycles pages on hold instead of launching the weather app (the sun arc and the temperature panel do that).

## Memory after pass 2

The first pass 2 build ran out of memory when switching skins in the simulator. Measured in the test build (numbers include the test code): code plus static data 104 KB, one skin JSON dictionary 12 KB while parsing, a parsed skin 9 to 11 KB retained, the page renderers 3 KB, an effect 3 KB, each bitmap font only 320 bytes on the heap (the atlases live in the graphics pool). Changes: the generated key tables became functions (minus 3 KB of static strings), each skin is split by the generator into a core and a pages resource parsed one after the other (parse peak 5 KB instead of 12 KB), and the view drops the previous skin and effect before loading the next skin. Skin switches now peak well inside the 127 KB limit, the probe numbers are in the pass 2 log below.

## Pass 2 simulator log

Skin switch trace (probe build, fenix8solar51mm): old skin released 109.0 KB, new core parsed 112.8 KB, at rest after the switch 112 to 114 KB. Peak over the whole matrix (three skins, every page, day and night, six forced conditions): 117.3 KB on fenix8solar51mm and 118.5 KB on fenix847mm, against the 126.8 KB limit reported by the simulator. Effect draw times in the simulator: fenix8solar51mm at 6 fps 16 to 32 ms per frame (budget 166 ms), fenix847mm at 10 fps 1 to 8 ms (budget 100 ms), no budget hit. Screenshots of every state are in docs/screens/pass2 (p2-DEVICE-SKIN-STATE.png).

## Feedback round after pass 2

1. Textures removed from all three skins (sunburst and crosshatch read as noise on the small dial); the options stay in the skin model.
2. Effects toned down and moved behind the time markers: rain is small drops of three sizes in a muted grey at 24 (MIP) or 48 (AMOLED) particles, heavy rain adds short streaks, snow is dots, small crosses and six armed stars of three sizes, wind is a handful of short curved streaks, fog is three soft dithered bands, and thunder is a bolt only, no full screen flash. After the overlay is drawn the chapter ring, ticks and numerals are drawn again on top, so the overlay sits behind every marker, value and the hands.
3. Sun and moon are proper icons (tapered rays with a two tone disc, cratered moon disc) at 13 percent, the moon at 10 percent by day and 13 by night, the centre condition icon at 30 percent. The sun travels on the arc at 40 percent, inside the chapter ring, and passes behind the panels.
4. The sun and moon arcs are tapered bands: one pixel at the horizon ends, arcWidthPercent of the screen at the zenith, drawn as dithered rings so they read as translucent, in pastel colours from the 64 colour palette (0xFFFFAA for the sun, 0xAAAAFF for the moon).
5. A battery readout (glyph plus percent) sits at 12 percent from the top on every page, in the skin's battery block, accent coloured below 15 percent.
6. The date panel lost its calendar grid icon. A new NextEvent source shows the nearest calendar event: time as the value, event title as the label, from the system calendar complication. Page one slot four defaults to it.

## Palette and type round

1. Palette. Structure is greyscale on the 64 colour palette: black background and panel fill, 0x555555 rims, rings, hand shadows and tick minors, 0xAAAAAA numerals, tick majors, labels and hands, white values. Colour appears only where it carries meaning and always as a pastel from the palette: gauge bands 0xFFAAAA, 0xFFFFAA and 0xAAFFAA, sun arc and disc 0xFFFFAA, moon arc 0xAAAAFF, pulse ox 0xAAFFFF, HRV 0xAAAAFF, lightning 0xAAAAFF, the accent (classic 0xFFAAAA, sport 0xFFAA55, minimal white) on the seconds hand, active page dot, top health arc, temperature and pressure bars.
2. Type. Values in Rajdhani SemiBold (OFL), labels in Montserrat SemiBold (OFL) uppercase, both rasterised per device by tools/gen_fonts.py at 8.8, 18 and 4.2 percent of the screen width. The width check allows one pixel of rounding. Oswald and Roboto Condensed stay in assets/fonts as alternatives.
3. Event panel. The nearest calendar event shows its time as the value and its title as the label; titles longer than nine characters scroll one character per refresh (every second while awake).

## Backgrounds and the rounded icon set

1. Icons. The weather set was redrawn in the soft, rounded style of the reference images: clouds built from overlapping discs with a lighter top and a grey shadow tone standing in for the gradients, a warm sun with rounded rays and a two tone disc, blue drops, an orange bolt, white star flakes, a shaded full moon disc for the arc marker, and a crescent with stars for clear nights. Everything is flat colour so it survives the 64 colour palette.
2. Condition discs. Photographs cannot ship (licensing, palette, size), so tools/gen_backgrounds.py paints a stylised sky disc per weather category: a two colour gradient, blurred cloud blobs, rain streaks, a lightning streak for thunder, arcs for wind, stars for clear nights. On MIP devices the disc is Floyd Steinberg dithered to the 64 colour palette. The disc is 30 percent of the screen, drawn behind the condition icon, and can be turned off per skin (weatherPage.conditionBackground).
3. Topographic dial. The same tool draws thin contour lines (iso lines of a seeded smooth field, every fifth line lighter) masked to the round display, as dial texture "topo". Classic and sport use it, minimal stays plain. The bitmap lives in the graphics pool and is drawn once into the cached dial, so it costs nothing per minute.

## Final simulator numbers (this round)

Memory after moving the skin lookup tables into functions and splitting each skin into core, layout and pages resources: at rest 115 KB (minimal) to 117 KB (sport), peak over the whole matrix including every skin switch and all six forced weather conditions 122.0 KB on fenix8solar51mm and 122.0 KB on fenix847mm, against the 126.8 KB limit. The margin is about 5 KB, so any further feature must come with a measurement (probe.jungle plus tools/simrun.py). Tests: 18 pass. Screenshots of every state: docs/screens/pass2.

## Contour texture softening

The contour lines are now blurred (gaussian, 1.3 px) and faint. The resource pipeline keeps only one bit of alpha, so the softness cannot be alpha: on AMOLED the blurred coverage is painted as dim blue grey on opaque black (the dial is black, so it is equivalent to translucency). MIP has four grey levels and full dithering turned the field into speckle, so the blurred line core is drawn as a 50 percent checkerboard and its halo as a 25 percent pattern in the darkest grey 0x555555, which reads as a soft translucent line on the transflective display.
