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

Side load: copy bin/ConfigurableAnalog.prg to GARMIN/APPS on the watch.

Python tooling checks for the generator:

    ruff format tools/ && ruff check --line-length 160 tools/ && mypy --strict tools/gen_settings.py
