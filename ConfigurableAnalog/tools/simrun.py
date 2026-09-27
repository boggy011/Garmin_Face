# /// script
# requires-python = ">=3.11"
# dependencies = ["pillow", "pyobjc-framework-Quartz"]
# ///
"""Run a .prg in the Connect IQ simulator for a bounded time.

Drives monkeydo through a pseudo terminal so its console output is unbuffered, prints the
interesting lines, and takes timed screenshots of the simulator window while the app runs.
The simulator must already be running (connectiq), or pass --restart.

Usage:
    uv run tools/simrun.py <prg> <device> [--seconds 60] [--shots "generic@5 weather@13"] [--prefix before] [--restart] [-- extra monkeydo args]

Screenshots are written to docs/screens/<prefix>-<device>-<name>.png.
"""

from __future__ import annotations

import argparse
import os
import pty
import select
import signal
import subprocess
import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from screenshot import capture  # noqa: E402

KEEP = (
    "probe:",
    "effects:",
    "weather:",
    "Regions:",
    "HealthCache",
    "Error",
    "Exception",
    "PASS",
    "FAIL",
    "DEBUG",
    "Ran ",
    "Executing",
    "Unable",
)


def sdk_bin() -> Path:
    """bin folder of the active SDK from current-sdk.cfg."""
    cfg = Path.home() / "Library/Application Support/Garmin/ConnectIQ/current-sdk.cfg"
    return Path(cfg.read_text(encoding="utf-8").strip().rstrip("/")) / "bin"


def parse_shots(spec: str) -> list[tuple[str, float]]:
    """ "name@seconds name@seconds" into a time ordered list."""
    shots: list[tuple[str, float]] = []
    for entry in spec.split():
        name, _, at = entry.partition("@")
        shots.append((name, float(at)))
    return sorted(shots, key=lambda item: item[1])


def restart_simulator() -> None:
    """Kill stale clients and the simulator, start it again and wait for its port."""
    subprocess.run(["pkill", "-f", "MonkeyDoDeux"], check=False)
    subprocess.run(
        ["pkill", "-f", "ConnectIQ.app/Contents/MacOS/simulator"], check=False
    )
    time.sleep(2.0)
    subprocess.run([str(sdk_bin() / "connectiq")], check=True)
    for _ in range(60):
        probe = subprocess.run(
            ["lsof", "-nP", "-iTCP:1234", "-sTCP:LISTEN"],
            check=False,
            capture_output=True,
        )
        if probe.returncode == 0:
            time.sleep(2.0)
            return
        time.sleep(0.5)
    sys.exit("ERROR: simulator did not start listening on port 1234")


def run(
    prg: str,
    device: str,
    seconds: float,
    shots: list[tuple[str, float]],
    prefix: str,
    extra: list[str],
) -> str:
    """Run the app, take the screenshots, return the captured console output."""
    command = [str(sdk_bin() / "monkeydo"), prg, device, *extra]
    pid, fd = pty.fork()
    if pid == 0:
        os.execv(command[0], command)
    start = time.time()
    chunks: list[bytes] = []
    pending = list(shots)
    alive = True
    while alive and time.time() - start < seconds:
        ready, _, _ = select.select([fd], [], [], 0.25)
        if ready:
            try:
                data = os.read(fd, 4096)
            except OSError:
                data = b""
            if not data:
                alive = False
            chunks.append(data)
        while pending and time.time() - start >= pending[0][1]:
            name, at = pending.pop(0)
            path = capture(f"{prefix}-{device}-{name}", True)
            print(f"shot {path.name} at {at:.0f}s")
    try:
        os.kill(pid, signal.SIGTERM)
    except OSError:
        pass
    subprocess.run(["pkill", "-f", "MonkeyDoDeux"], check=False)
    os.close(fd)
    return b"".join(chunks).decode("utf-8", errors="replace").replace("\r", "")


def main() -> int:
    """Entry point."""
    parser = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    parser.add_argument("prg")
    parser.add_argument("device")
    parser.add_argument("--seconds", type=float, default=60.0)
    parser.add_argument("--shots", default="")
    parser.add_argument("--prefix", default="shot")
    parser.add_argument(
        "--all-output",
        action="store_true",
        help="print every console line, not only the interesting ones",
    )
    parser.add_argument(
        "--restart",
        action="store_true",
        help="restart the simulator first (clears stuck clients)",
    )
    parser.add_argument("extra", nargs="*")
    args = parser.parse_args()
    if args.restart:
        restart_simulator()
    output = run(
        args.prg,
        args.device,
        args.seconds,
        parse_shots(args.shots),
        args.prefix,
        args.extra,
    )
    for line in output.splitlines():
        if line.strip() and (args.all_output or any(key in line for key in KEEP)):
            print(line)
    return 0


if __name__ == "__main__":
    sys.exit(main())
