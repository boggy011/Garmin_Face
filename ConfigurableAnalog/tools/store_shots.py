# /// script
# requires-python = ">=3.11"
# dependencies = ["pillow", "pyobjc-framework-Quartz"]
# ///
"""Store listing screenshots at native resolution.

Runs the probe build of a product in the simulator through simrun, captures the window at
the requested times, then crops each capture to the watch display using the device pack's
display location (the simulator draws the device image 1:1 under a 28 point title bar).

Usage:
    uv run tools/store_shots.py <product> "<name>@<seconds> ..." [--out release/listing]
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
from simrun import parse_shots, restart_simulator, run  # noqa: E402

PROJECT_DIR = Path(__file__).resolve().parent.parent
DEVICES_DIR = Path.home() / "Library/Application Support/Garmin/ConnectIQ/Devices"
TITLE_BAR = 28


def display_rect(product: str) -> tuple[int, int, int, int]:
    """(x, y, w, h) of the display inside the simulator window capture."""
    simulator = json.loads(
        (DEVICES_DIR / product / "simulator.json").read_text(encoding="utf-8")
    )
    location = simulator["display"]["location"]
    return (
        int(location["x"]),
        TITLE_BAR + int(location["y"]),
        int(location["width"]),
        int(location["height"]),
    )


def main() -> int:
    """Entry point."""
    parser = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    parser.add_argument("product")
    parser.add_argument("shots")
    parser.add_argument("--out", default="release/listing")
    parser.add_argument("--seconds", type=float, default=0.0)
    args = parser.parse_args()
    shots = parse_shots(args.shots)
    seconds = args.seconds if args.seconds > 0 else shots[-1][1] + 3
    out_dir = PROJECT_DIR / args.out
    out_dir.mkdir(parents=True, exist_ok=True)
    restart_simulator()
    prg = PROJECT_DIR / "bin" / f"pass2-probe-{args.product}.prg"
    run(str(prg), args.product, seconds, shots, "store/raw", [])
    x, y, w, h = display_rect(args.product)
    for name, _ in shots:
        raw = PROJECT_DIR / "docs/screens" / "store" / f"raw-{args.product}-{name}.png"
        image = Image.open(raw).convert("RGB")
        target = out_dir / f"{args.product}-{name}.png"
        image.crop((x, y, x + w, y + h)).save(target, optimize=True)
        print(f"wrote {target.relative_to(PROJECT_DIR)} {w}x{h}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
