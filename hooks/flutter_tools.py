#!/usr/bin/env python3
"""
Cross-platform Flutter/Dart tooling for pre-commit hooks.

Usage:
  python hooks/flutter_tools.py format
  python hooks/flutter_tools.py analyze
  python hooks/flutter_tools.py test

Tries FVM first (if available), then falls back to dart/flutter directly.
Works on macOS, Linux, and Windows (no bash required).
"""

from __future__ import annotations

import argparse
import shutil
import subprocess
import sys
from typing import List, Optional


def resolve(prog: str) -> Optional[str]:
  return shutil.which(prog)


def run(cmd: List[str]) -> int:
  try:
    proc = subprocess.run(cmd, check=False)
    return proc.returncode
  except FileNotFoundError:
    return 127


def cmd_format() -> int:
  # Prefer FVM-managed dart
  fvm = resolve("fvm")
  if fvm:
    return run([fvm, "dart", "format", "-o", "none", "--set-exit-if-changed", "."])

  # Fallback to dart directly
  dart_cmd = resolve("dart")
  if dart_cmd:
    return run([dart_cmd, "format", "-o", "none", "--set-exit-if-changed", "."])

  # Last resort: some environments still have `flutter format`
  flutter_cmd = resolve("flutter")
  if flutter_cmd:
    return run([flutter_cmd, "format", "-o", "none", "--set-exit-if-changed", "."])

  print("Error: Neither fvm, dart, nor flutter found in PATH", file=sys.stderr)
  return 127


def cmd_analyze() -> int:
  fvm = resolve("fvm")
  if fvm:
    return run([fvm, "flutter", "analyze"])
  flutter_cmd = resolve("flutter")
  if flutter_cmd:
    return run([flutter_cmd, "analyze"])
  print("Error: flutter not found (and fvm not available)", file=sys.stderr)
  return 127


def cmd_test() -> int:
  fvm = resolve("fvm")
  if fvm:
    return run([fvm, "flutter", "test"])
  flutter_cmd = resolve("flutter")
  if flutter_cmd:
    return run([flutter_cmd, "test"])
  print("Error: flutter not found (and fvm not available)", file=sys.stderr)
  return 127


def main(argv: List[str]) -> int:
  parser = argparse.ArgumentParser(description="Cross-platform Flutter/Dart hooks")
  parser.add_argument("command", choices=["format", "analyze", "test"], help="Command to run")
  args = parser.parse_args(argv)

  if args.command == "format":
    return cmd_format()
  if args.command == "analyze":
    return cmd_analyze()
  if args.command == "test":
    return cmd_test()
  return 1


if __name__ == "__main__":
  sys.exit(main(sys.argv[1:]))
