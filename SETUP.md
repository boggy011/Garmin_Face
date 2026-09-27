# Connect IQ development setup (macOS)

Set up 2026-09-27 on macOS 27.0, Apple Silicon (arm64), zsh, Homebrew 6.0.21. Project specific build, test and release commands are in ConfigurableAnalog/SETUP.md.

## Versions

Java: Temurin OpenJDK 17.0.13, managed by SDKMAN
VS Code: 1.139.1
VS Code extension: garmin.monkey-c 1.1.3 (official)
Connect IQ SDK Manager: 1.0.1
Connect IQ SDK: 9.2.0 (connectiq-sdk-mac-9.2.0-2026-06-09-92a1605b2), set as current
Device packages: fenix8solar51mm, fenix8solar47mm, fenix847mm, fenix843mm (all API 6.0 devices are installed)

## Paths

SDK Manager app:        /Applications/SdkManager.app
Connect IQ root:        ~/Library/Application Support/Garmin/ConnectIQ
Active SDK pointer:     ~/Library/Application Support/Garmin/ConnectIQ/current-sdk.cfg
Active SDK:             ~/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.2.0-2026-06-09-92a1605b2
SDK tools:              <active SDK>/bin  (monkeyc, monkeydo, connectiq, ConnectIQ.app simulator)
Device packages:        ~/Library/Application Support/Garmin/ConnectIQ/Devices/<deviceId>
Developer key (PEM):    ~/garmin-keys/developer_key.pem   RSA 4096, source key
Developer key (DER):    ~/garmin-keys/developer_key.der   PKCS8, the file monkeyc signs with
VS Code key setting:    <project>/.vscode/settings.json, monkeyC.developerKeyPath (gitignored)
Build output:           <project>/bin/ (gitignored)
Java home:              ~/.sdkman/candidates/java/current

Back up ~/garmin-keys. Every store update must be signed with this exact key. A lost key means a new store listing. The key fingerprint is recorded in ConfigurableAnalog/SETUP.md.

## Environment variables (~/.zshrc, block "Garmin Connect IQ dev environment")

JAVA_HOME      ~/.sdkman/candidates/java/current   (pre-existing, set by SDKMAN init)
PATH           += /Applications/Visual Studio Code.app/Contents/Resources/app/bin   (code CLI)
CIQ_SDK_HOME   read from current-sdk.cfg at every shell start, trailing slash stripped
PATH           += $CIQ_SDK_HOME/bin

Previous ~/.zshrc saved as ~/.zshrc.bak-connectiq-setup.
Switching SDK in SDK Manager (SDK tab, Use) changes PATH in the next new shell. Check with: monkeyc --version

## General commands

Verify the toolchain:

    java -version && code --version && monkeyc --version

In VS Code: "Monkey C: Verify Installation".

Simulator: run connectiq, wait until its window is up, then monkeydo <prg> <deviceId>. Starting monkeydo before the window is up gives "Unable to connect to simulator". monkeydo stays attached and streams app output. Ctrl+C detaches, the app keeps running in the simulator. In VS Code, F5 builds and launches in the simulator using the .vscode/settings.json key path.

Side load to the watch: connect it over USB and copy the .prg into GARMIN/APPS. If the watch mounts as a drive it appears at /Volumes/GARMIN. If it only presents MTP on macOS, use Android File Transfer or OpenMTP. Eject, then pick the face under watch face settings on the device.

Store upload: the .iq export goes to the Connect IQ developer portal (apps.garmin.com, developer dashboard). VS Code equivalent: "Monkey C: Export Project".

Add or remove target devices: SDK Manager, Devices tab, then "Monkey C: Edit Products" in VS Code.

Python tooling (generators, screenshots, simulator runner): Python 3.14 with uv, scripts carry their own dependencies as PEP 723 headers. cairosvg needs DYLD_FALLBACK_LIBRARY_PATH=/opt/homebrew/lib for the Homebrew cairo library.
