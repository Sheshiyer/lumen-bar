#!/usr/bin/env python3
"""Run one local release command with a bounded wall clock and no echoed arguments."""

from __future__ import annotations

import argparse
import os
import signal
import subprocess
import sys


parser = argparse.ArgumentParser(add_help=False)
parser.add_argument("--seconds", type=int, required=True)
parser.add_argument("command", nargs=argparse.REMAINDER)
args = parser.parse_args()
command = args.command[1:] if args.command[:1] == ["--"] else args.command
if args.seconds < 1 or not command:
    raise SystemExit("run-with-timeout requires a positive --seconds and a command")

process = subprocess.Popen(command, start_new_session=True)
try:
    raise SystemExit(process.wait(timeout=args.seconds))
except subprocess.TimeoutExpired:
    # Kill the process group so a child timestamp/notary helper cannot outlive the gate.
    try:
        os.killpg(process.pid, signal.SIGTERM)
        process.wait(timeout=5)
    except (ProcessLookupError, subprocess.TimeoutExpired):
        try:
            os.killpg(process.pid, signal.SIGKILL)
        except ProcessLookupError:
            pass
    print(f"{os.path.basename(command[0])} timed out after {args.seconds}s", file=sys.stderr)
    raise SystemExit(124)
