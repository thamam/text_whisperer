# Installation Guide

## System Dependencies

### Linux (Ubuntu/Debian)
```bash
sudo apt install ffmpeg xclip xdotool python3-tk
```

### macOS
```bash
brew install ffmpeg
```

### Windows
Download FFmpeg from https://ffmpeg.org/download.html and add it to your PATH.

> **Note:** Auto-paste (`xdotool`) is currently Linux-only. On macOS and Windows, transcribed text is copied to the clipboard instead.

## Python Dependencies

```bash
pip install -r requirements.txt
```

This installs all required packages including faster-whisper, pynput, pyaudio, and pygame.

> **GPU acceleration (optional):** For NVIDIA GPU support, ensure CUDA Toolkit and cuDNN are installed. The app auto-detects and falls back to CPU gracefully.

## Running the Application

```bash
python3 main.py
```

Or from the `voice_transcription_tool/` directory:

```bash
cd voice_transcription_tool/
python3 main.py
```

## Background Service

Use the manager script to run as a background service:

```bash
./voice_transcription_manager.sh --start    # Start in background
./voice_transcription_manager.sh --status   # Check status
./voice_transcription_manager.sh --stop     # Stop
```

## Verifying the Installation

1. Run `python3 main.py`
2. The GUI window and system tray icon should appear
3. Press **Alt+D** to start recording — a pulsing banner indicates active recording
4. Speak, then release **Alt+D** — text is transcribed and auto-pasted at your cursor

## Troubleshooting

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for common issues and solutions.
