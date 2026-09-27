# /// script
# requires-python = ">=3.11"
# dependencies = ["pillow", "pyobjc-framework-Quartz"]
# ///
"""Save a screenshot of the Connect IQ simulator window.

Finds the simulator window through the Quartz window list, captures that window through Quartz
(falling back to a display capture cropped to the window) and writes docs/screens/<name>.png,
optionally trimmed to the watch display. Needs Screen Recording permission for the terminal
that runs it.

Usage:
    uv run tools/screenshot.py <name> [--device-only]
"""

from __future__ import annotations

import argparse
import subprocess
import sys
from pathlib import Path
from typing import Any, cast

import Quartz  # type: ignore[import-not-found]
from PIL import Image

PROJECT_DIR = Path(__file__).resolve().parent.parent
SCREENS_DIR = PROJECT_DIR / "docs/screens"
OWNER_HINTS = ("simulator", "connect iq", "connectiq")


def simulator_window() -> tuple[int, tuple[int, int, int, int]]:
    """Window number and bounds (x, y, w, h) in points of the titled, on screen simulator window."""
    options = (
        Quartz.kCGWindowListOptionOnScreenOnly
        | Quartz.kCGWindowListExcludeDesktopElements
    )
    windows = cast(
        list[dict[str, Any]],
        Quartz.CGWindowListCopyWindowInfo(options, Quartz.kCGNullWindowID),
    )
    best: tuple[int, tuple[int, int, int, int]] | None = None
    best_score = -1
    for window in windows:
        owner = str(window.get("kCGWindowOwnerName", "")).lower()
        if (
            not any(hint in owner for hint in OWNER_HINTS)
            or int(window.get("kCGWindowLayer", 0)) != 0
        ):
            continue
        bounds = window.get("kCGWindowBounds", {})
        rect = (
            int(bounds.get("X", 0)),
            int(bounds.get("Y", 0)),
            int(bounds.get("Width", 0)),
            int(bounds.get("Height", 0)),
        )
        score = rect[2] * rect[3] + (
            10_000_000
            if "simulator" in str(window.get("kCGWindowName", "")).lower()
            else 0
        )
        if score > best_score:
            best_score = score
            best = (int(window["kCGWindowNumber"]), rect)
    if best is None:
        sys.exit("ERROR: no simulator window found, start it with: connectiq")
    return best


def display_scale(image: Image.Image) -> float:
    """Pixels per point of the main display."""
    bounds = Quartz.CGDisplayBounds(Quartz.CGMainDisplayID())
    return image.width / float(bounds.size.width)


def trim_to_device(window: Image.Image) -> Image.Image:
    """Crop the window image to the bounding box of the non-background (device) pixels."""
    grey = window.convert("L")
    sample = grey.getpixel((4, grey.height // 2))
    background = int(sample) if isinstance(sample, (int, float)) else 0
    mask = grey.point(lambda v: 255 if abs(v - background) > 24 else 0)
    bbox = mask.getbbox()
    return window.crop(bbox) if bbox else window


def capture_window_image(window_id: int, target: Path) -> bool:
    """Capture one window through Quartz into a PNG. False when the system refused."""
    image = Quartz.CGWindowListCreateImage(
        Quartz.CGRectNull,
        Quartz.kCGWindowListOptionIncludingWindow,
        window_id,
        Quartz.kCGWindowImageBoundsIgnoreFraming,
    )
    if image is None or Quartz.CGImageGetWidth(image) < 10:
        return False
    url = Quartz.CFURLCreateWithFileSystemPath(
        None, str(target), Quartz.kCFURLPOSIXPathStyle, False
    )
    destination = Quartz.CGImageDestinationCreateWithURL(url, "public.png", 1, None)
    if destination is None:
        return False
    Quartz.CGImageDestinationAddImage(destination, image, None)
    return bool(Quartz.CGImageDestinationFinalize(destination))


def capture(name: str, device_only: bool) -> Path:
    """Capture the simulator window and save it. Returns the written path."""
    SCREENS_DIR.mkdir(parents=True, exist_ok=True)
    target = SCREENS_DIR / f"{name}.png"
    window_id, (x, y, w, h) = simulator_window()
    if not capture_window_image(window_id, target):
        subprocess.run(["screencapture", "-x", str(target)], check=True)
        image = Image.open(target)
        scale = display_scale(image)
        image.crop(
            (int(x * scale), int(y * scale), int((x + w) * scale), int((y + h) * scale))
        ).save(target)
    window = Image.open(target).convert("RGB")
    if device_only:
        window = trim_to_device(window)
    window.save(target)
    return target


def main() -> int:
    """Entry point."""
    parser = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    parser.add_argument(
        "name", help="file name without extension, saved under docs/screens/"
    )
    parser.add_argument(
        "--device-only",
        action="store_true",
        help="trim the window chrome around the watch",
    )
    args = parser.parse_args()
    path = capture(args.name, args.device_only)
    print(f"wrote {path.relative_to(PROJECT_DIR)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
