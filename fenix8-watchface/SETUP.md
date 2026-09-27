# Connect IQ development setup (fenix 8 Solar)

Set up 2026-09-27 on macOS 27.0, Apple Silicon (arm64), zsh, Homebrew 6.0.21.

## Versions

Java: Temurin OpenJDK 17.0.13, managed by SDKMAN
VS Code: 1.139.1
VS Code extension: garmin.monkey-c 1.1.3 (official)
Connect IQ SDK Manager: 1.0.1
Connect IQ SDK: 9.2.0 (connectiq-sdk-mac-9.2.0-2026-06-09-92a1605b2), set as current
Device packages: fenix8solar47mm, fenix8solar51mm (Connect IQ 6.0.2); all API 6.0 devices are installed
Project minApiLevel: 5.2.2, products: fenix8solar47mm, fenix8solar51mm

## Paths

SDK Manager app:        /Applications/SdkManager.app
Connect IQ root:        ~/Library/Application Support/Garmin/ConnectIQ
Active SDK pointer:     ~/Library/Application Support/Garmin/ConnectIQ/current-sdk.cfg
Active SDK:             ~/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.2.0-2026-06-09-92a1605b2
SDK tools:              <active SDK>/bin  (monkeyc, monkeydo, connectiq, ConnectIQ.app simulator)
Device packages:        ~/Library/Application Support/Garmin/ConnectIQ/Devices/<deviceId>
Developer key (PEM):    ~/garmin-keys/developer_key.pem   RSA 4096, source key
Developer key (DER):    ~/garmin-keys/developer_key.der   PKCS8, the file monkeyc signs with
Project:                /Users/bogdannejcev/Garmin/Garmin_Face/fenix8-watchface
VS Code key setting:    fenix8-watchface/.vscode/settings.json, monkeyC.developerKeyPath (gitignored)
Build output:           fenix8-watchface/bin/ (gitignored)
Java home:              ~/.sdkman/candidates/java/current

Back up ~/garmin-keys. Every store update must be signed with this exact key. A lost key means a new store listing.

## Environment variables (~/.zshrc, block "Garmin Connect IQ dev environment")

JAVA_HOME      ~/.sdkman/candidates/java/current   (pre-existing, set by SDKMAN init)
PATH           += /Applications/Visual Studio Code.app/Contents/Resources/app/bin   (code CLI)
CIQ_SDK_HOME   read from current-sdk.cfg at every shell start, trailing slash stripped
PATH           += $CIQ_SDK_HOME/bin

Previous ~/.zshrc saved as ~/.zshrc.bak-connectiq-setup.
Switching SDK in SDK Manager (SDK tab, Use) changes PATH in the next new shell. Check with: monkeyc --version

## Commands

Run from the project folder: cd /Users/bogdannejcev/Garmin/Garmin_Face/fenix8-watchface

Build (debug, single device):

    monkeyc -d fenix8solar51mm -f monkey.jungle -o bin/test.prg -y ~/garmin-keys/developer_key.der -w

Simulate:

    connectiq
    monkeydo bin/test.prg fenix8solar51mm

connectiq starts the simulator app. Wait until its window is up before monkeydo, otherwise "Unable to connect to simulator".
monkeydo stays attached and streams app output. Ctrl+C detaches, the app keeps running in the simulator.
In VS Code: F5 builds and launches in the simulator using the .vscode/settings.json key path.

Side load to the watch:

    cp bin/test.prg /Volumes/GARMIN/GARMIN/APPS/

Connect the watch over USB. If it mounts as a drive it appears at /Volumes/GARMIN.
If it only presents MTP on macOS, use Android File Transfer or OpenMTP and copy the .prg into GARMIN/APPS.
Eject, then pick the face under watch face settings on the device.

Export for the store (.iq, release, all products in manifest.xml):

    monkeyc -e -r -f monkey.jungle -o bin/fenix8-watchface.iq -y ~/garmin-keys/developer_key.der

Upload bin/fenix8-watchface.iq in the Connect IQ developer portal (apps.garmin.com, developer dashboard).
VS Code equivalent: "Monkey C: Export Project".

Verify the toolchain:

    java -version && code --version && monkeyc --version

In VS Code: "Monkey C: Verify Installation".

Add or remove target devices: SDK Manager, Devices tab, then "Monkey C: Edit Products" in VS Code.
