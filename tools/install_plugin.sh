#!/bin/bash
# Builds the VST3 (if needed) and installs it to the folder for all users
# (/Library/Audio/Plug-Ins/VST3), where the release zip goes too (ship-bob
# locations.md), and removes a per-user copy so the host never sees two.
# When that folder is not writable it asks for the password (sudo); without
# a terminal (a background agent) it stops and prints the command instead.
#
# Installs a Release build (build-release/, configured here if missing):
# that is what a host's CPU meter should be judged on. A Debug build is
# unoptimised - measured 2026-10-10 at ~6x the audio-thread cost of Release
# (30% vs 5% of a 128-sample buffer, 8 voices) - so use
#   tools/install_plugin.sh --debug
# only to step through the plugin in a debugger.
set -euo pipefail

cd "$(dirname "$0")/.."

CONFIG=Release
BUILD_DIR=build-release

if [[ "${1:-}" == "--debug" ]]; then
    CONFIG=Debug
    BUILD_DIR=build
fi

if [[ ! -f "$BUILD_DIR/CMakeCache.txt" ]]; then
    cmake -B "$BUILD_DIR" -G Ninja -DCMAKE_BUILD_TYPE="$CONFIG"
fi

cmake --build "$BUILD_DIR" --target HorizonPad_VST3 -j 8

SRC="$BUILD_DIR/HorizonPad_artefacts/$CONFIG/VST3/Horizon Pad.vst3"
DEST_DIR="/Library/Audio/Plug-Ins/VST3"
DEST="$DEST_DIR/Horizon Pad.vst3"
SUDO=""
if [[ ! -w "$DEST_DIR" ]] || { [[ -e "$DEST" ]] && [[ ! -w "$DEST" ]]; }; then
    if [[ -t 0 ]]; then
        SUDO="sudo"
    else
        echo "$DEST_DIR needs the password: run tools/install_plugin.sh in a terminal" >&2
        exit 1
    fi
fi

$SUDO mkdir -p "$DEST_DIR"
$SUDO rm -rf "$DEST"
$SUDO cp -R "$SRC" "$DEST"
USER_COPY="$HOME/Library/Audio/Plug-Ins/VST3/Horizon Pad.vst3"
if [[ -e "$USER_COPY" ]]; then
    rm -rf "$USER_COPY"
    echo "Removed the per-user copy $USER_COPY"
fi

echo "Installed $CONFIG build to $DEST"
