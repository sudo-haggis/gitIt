#!/bin/bash
# Regenerate the SVG demo screenshots used in the README.
# Requires: pip install rich
#
# Usage (from repo root):
#   bash docs/record_demos.sh

set -e
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
python3 "$REPO_ROOT/docs/make_demo_svgs.py"
echo "Done. Commit docs/img/*.svg alongside any output-changing code changes."
