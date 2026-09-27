# ConfigurableAnalog build and run

Prerequisites: Connect IQ SDK 9.2.0 as current SDK, device packages fenix8solar51mm, fenix8solar47mm, fenix847mm and fenix843mm, developer key at ~/garmin-keys/developer_key.der. PATH setup and machine level details are in ../fenix8-watchface/SETUP.md.

All commands run from this folder.

Regenerate settings, strings, editor config and SettingsKeys.mc after editing tools/sources.yaml:

    python3 tools/gen_settings.py
    python3 tools/gen_settings.py --check

Build for fenix8solar51mm (strict type check, warnings on):

    monkeyc -d fenix8solar51mm -f monkey.jungle -o bin/ConfigurableAnalog.prg -y ~/garmin-keys/developer_key.der -w -l 3

Other targets: replace fenix8solar51mm with fenix8solar47mm, fenix847mm or fenix843mm.

Run in the simulator (start the simulator first, wait for its window):

    connectiq
    monkeydo bin/ConfigurableAnalog.prg fenix8solar51mm

monkeydo stays attached and prints app output. Ctrl+C detaches. In the simulator use Settings, Trigger Watch Face Editor or the low power mode toggle to exercise the editor and partial updates. Touch and hold the dial centre to cycle pages.

Unit tests (Toybox.Test):

    monkeyc -d fenix8solar51mm -f monkey.jungle -o bin/ConfigurableAnalog-test.prg -y ~/garmin-keys/developer_key.der -w -l 3 -t
    monkeydo bin/ConfigurableAnalog-test.prg fenix8solar51mm -t

In VS Code the same runs through "Monkey C: Run Tests". Build and launch with F5.

Export for the store (all products, release):

    monkeyc -e -r -f monkey.jungle -o bin/ConfigurableAnalog.iq -y ~/garmin-keys/developer_key.der -l 3

Developer key fingerprint (SHA256 of the public key, DER): 8c469231f94e733536dfbf9ec6f0312b43be76eae4d6dadb7223efaf722d7524. Every store update must be signed with this key. Check with: openssl pkey -inform DER -in ~/garmin-keys/developer_key.der -pubout -outform DER | openssl dgst -sha256

Side load: build with the command above, then copy bin/ConfigurableAnalog.prg to GARMIN/APPS on the watch. The file to check on a real fenix 8 Solar 51mm is exactly bin/ConfigurableAnalog.prg built with -d fenix8solar51mm.

Simulator probe (auto page cycling, forced weather conditions, memory and frame time log):

    monkeyc -d fenix8solar51mm -f probe.jungle -o bin/ConfigurableAnalog-probe.prg -y ~/garmin-keys/developer_key.der -w -l 3
    uv run tools/simrun.py bin/ConfigurableAnalog-probe.prg fenix8solar51mm --restart --seconds 82 --prefix run --shots "generic@5 weather@13 health@21"

Screenshots land in docs/screens. Icons: uv run tools/gen_icons.py after editing assets/icons/src or tools/icons.yaml. Backgrounds: uv run tools/gen_backgrounds.py (topographic dial texture and weather condition discs). Fonts: uv run tools/gen_fonts.py after editing assets/fonts or tools/fonts.yaml (also checks that the widest values fit a panel).

Debug colour swatches: set the showColourSwatches setting to true (phone settings, or Properties in the simulator) to draw the 64 colour palette grid over the face, photograph the real display and pick colours by index (row major, index = r * 16 + g * 4 + b with channel levels 00, 55, AA, FF).

Python tooling checks for the generator:

    ruff format tools/ && ruff check --line-length 160 tools/ && mypy --strict tools/gen_settings.py

## Store release

Preflight: python3 tools/gen_settings.py --check, the test suite, and a strict build for every product in manifest.xml. Bump version in manifest.xml (semver) and add a CHANGELOG.md entry. Export:

    monkeyc -e -f monkey.jungle -o release/ConfigurableAnalog-<version>.iq -y ~/garmin-keys/developer_key.der -w -l 3

The .iq is a 7-zip archive (not zip) holding one .prg per device build plus the manifest; inspect it with py7zr (uv run --with py7zr python) or 7z. Side-load binary for the smoke test: monkeyc -d fenix8solar51mm ... -o release/ConfigurableAnalog-<version>-fenix8solar51mm.prg. Listing assets (native resolution screenshots, icons, listing text) live in release/listing, screenshots come from uv run tools/store_shots.py <product> "generic@8 weather@16 health@32". The developer key fingerprint above must match on every release.
