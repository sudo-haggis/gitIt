#!/bin/bash
# Run this script from the repo root in a real terminal to regenerate the SVG demos.
# Requires termtosvg: pip install termtosvg
#
# Usage:
#   bash docs/record_demos.sh

set -e

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
IMG_DIR="$REPO_ROOT/docs/img"
GITIT="$REPO_ROOT/gitIt.sh"

mkdir -p "$IMG_DIR"

WIDTH=100
HEIGHT=30

record() {
    local label="$1"
    local output="$2"
    local cmd="$3"
    echo "Recording: $label → $output"
    termtosvg "$IMG_DIR/$output" \
        -c "bash -c 'cd $REPO_ROOT && $cmd; sleep 2'" \
        -g "${WIDTH}x${HEIGHT}" \
        -M 200 \
        -D 3000
    echo "  done."
}

record "default compact view"   "gitit_default.svg"  "bash gitIt.sh -t"
record "branches view"          "gitit_branches.svg" "bash gitIt.sh -t -b"
record "list view"              "gitit_list.svg"     "bash gitIt.sh -t -l"
record "verbose view"           "gitit_verbose.svg"  "bash gitIt.sh -t -v"
record "help"                   "gitit_help.svg"     "bash gitIt.sh --help"

echo ""
echo "All SVGs written to $IMG_DIR"
echo "Commit them and push — the README will pick them up automatically."
