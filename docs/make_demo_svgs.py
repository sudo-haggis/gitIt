#!/usr/bin/env python3
"""
Generate static SVG screenshots of gitIt output.

Runs each gitIt command, captures its ANSI-coloured output, and exports
a styled SVG via rich. No PTY or interactive terminal required.

Usage (from repo root):
    python3 docs/make_demo_svgs.py
"""
import os
import subprocess
import sys
from pathlib import Path

try:
    from rich.console import Console
    from rich.text import Text
except ImportError:
    sys.exit("rich is required: pip install rich")

REPO_ROOT = Path(__file__).resolve().parent.parent
IMG_DIR = REPO_ROOT / "docs" / "img"
IMG_DIR.mkdir(parents=True, exist_ok=True)

DEMOS = [
    ("gitit_default",  ["-t"],          "gitit"),
    ("gitit_branches", ["-t", "-b"],    "gitit -b"),
    ("gitit_list",     ["-t", "-l"],    "gitit -l"),
    ("gitit_verbose",  ["-t", "-v"],    "gitit -v"),
    ("gitit_help",     ["--help"],      "gitit --help"),
]

WIDTH = 89  # matches the hardcoded separator width in cli_tools.sh


def run_gitit(args: list[str]) -> bytes:
    env = {
        **os.environ,
        "TERM": "xterm-256color",
        "COLUMNS": str(WIDTH),
        "LINES": "50",
        "FORCE_COLOR": "1",
    }
    result = subprocess.run(
        ["bash", "gitIt.sh"] + args,
        capture_output=True,
        cwd=REPO_ROOT,
        env=env,
        timeout=30,
    )
    # gitIt exits 0 from exit statements — stdout is the output
    return result.stdout or result.stderr


def make_svg(name: str, raw: bytes, title: str) -> Path:
    text = Text.from_ansi(raw.decode("utf-8", errors="replace"))
    console = Console(record=True, width=WIDTH, highlight=False, markup=False)
    console.print(text, end="")
    svg = console.export_svg(title=title)
    out = IMG_DIR / f"{name}.svg"
    out.write_text(svg)
    return out


def main():
    for name, args, title in DEMOS:
        print(f"  {title} ...", end=" ", flush=True)
        raw = run_gitit(args)
        if not raw.strip():
            print("WARN: no output captured — skipping")
            continue
        path = make_svg(name, raw, title)
        print(f"→ {path.relative_to(REPO_ROOT)}")


if __name__ == "__main__":
    main()
