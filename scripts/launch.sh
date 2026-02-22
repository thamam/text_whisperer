#!/bin/bash
# Voice Transcription Tool Launcher
# This script launches the application with proper permissions

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}/../voice_transcription_tool"

# Check if running with sudo for hotkeys
if [ "$EUID" -eq 0 ]; then
    echo "Running with root privileges (hotkeys enabled)"
    python3 main.py "$@"
else
    echo "Running without root (hotkeys disabled - use GUI buttons)"
    python3 main.py "$@"
fi
