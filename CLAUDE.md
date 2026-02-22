# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**text_whisperer** (v2.1) — A production-ready, GPU-accelerated speech-to-text application with global hotkeys and auto-paste functionality. Modular architecture with 121 tests and 71% coverage.

## Key Commands

### Running the Application
```bash
# From repo root
python main.py

# From voice_transcription_tool/ subdirectory
cd voice_transcription_tool/
python main.py

# With command line options
python main.py --debug      # Enable verbose logging
python main.py --minimized  # Start hidden (background mode)

# Background service via manager script
./voice_transcription_manager.sh --start
./voice_transcription_manager.sh --stop
./voice_transcription_manager.sh --status
```

### Development Commands
```bash
# Install dependencies
pip install -r requirements.txt

# Run tests (MUST be in voice_transcription_tool/ directory)
cd voice_transcription_tool/
python -m pytest tests/              # All 121 tests
python -m pytest tests/ -v           # Verbose output
python -m pytest tests/ --cov        # With coverage (71%)
python -m pytest -m unit             # Unit tests only
python -m pytest -m integration      # Integration tests only
python -m pytest -m stress           # Stress tests
```

### Monitoring & Debugging
```bash
# Monitor resource usage
./voice_transcription_tool/monitor_voice_tool.sh

# Debug system freezes (run from TTY)
./voice_transcription_tool/debug_freeze.sh

# Check logs
tail -f logs/voice_transcription_*.log
```

### Stress Testing & Validation
```bash
# Memory leak detection (from repo root)
python scripts/memory_leak_test.py --cycles 1000 --log-interval 100
python scripts/memory_leak_test.py --duration 3600  # 1-hour test

# Multi-hour stability testing
./scripts/stability_test.sh --duration 8 --interval 300
```

## Architecture Overview

### Modular Design Pattern

The codebase follows a **Manager Pattern** where each subsystem is encapsulated in a dedicated manager class. `VoiceTranscriptionApp` (`gui/main_window.py:53`) acts as the coordinator.

### Core Module Structure

```
voice_transcription_tool/
├── main.py                 # Entry point with process locking & cleanup
├── config/
│   └── settings.py         # ConfigManager - JSON config with validation
├── audio/
│   ├── recorder.py         # AudioRecorder - PyAudio wrapper
│   ├── devices.py          # AudioDeviceManager - device selection
│   └── feedback.py         # AudioFeedback - recording sounds
├── speech/
│   └── engines.py          # SpeechEngineManager + 3 engines:
│                           #   FasterWhisperEngine (GPU, 4x faster)
│                           #   WhisperEngine (GPU/CPU)
│                           #   GoogleSpeechEngine (cloud fallback)
├── gui/
│   └── main_window.py      # VoiceTranscriptionApp - main coordinator
└── utils/
    ├── hotkeys.py          # HotkeyManager - pynput global shortcuts
    ├── autopaste.py        # AutoPasteManager - xdotool integration
    ├── tray_manager.py     # TrayManager - system tray with notifications
    ├── health_monitor.py   # HealthMonitor - resource monitoring
    └── logger.py           # Logging setup
```

### Critical Design Patterns

1. **Manager Classes**: Each subsystem has clear responsibility boundaries
2. **Abstract Base Classes**: Speech engines inherit from `SpeechEngine` ABC (`speech/engines.py:31`)
3. **Queue-based Threading**: Audio processing uses thread-safe queues (recorder → speech → GUI)
4. **Callback Pattern**: GUI updates from background threads via callbacks + `Tkinter.after()`
5. **Singleton Process Lock**: `/tmp/voice_transcription.lock` prevents multiple instances
6. **Graceful Degradation**: GPU, faster-whisper, and system tray all have fallback paths

### Data Flow

**Recording Flow:**
```
User Hotkey (Alt+D) → HotkeyManager → VoiceTranscriptionApp.toggle_recording()
→ AudioRecorder.start_recording() → audio_queue
→ SpeechEngineManager.transcribe() → transcription_queue
→ GUI update + AutoPasteManager → clipboard/paste
→ TrayManager.show_notification()
```

**GPU-Accelerated Transcription:**
```
Audio File → FasterWhisperEngine (CTranslate2 + FP16 on GPU, INT8 on CPU)
           ↓ fallback
           WhisperEngine (PyTorch + FP16 on GPU, FP32 on CPU)
           ↓ fallback
           GoogleSpeechEngine (cloud)
```

## System Dependencies

**Required:**
- FFmpeg — Audio processing (critical)
- xclip (Linux) — Clipboard functionality
- xdotool (Linux) — Auto-paste functionality
- Python 3.7+ with tkinter

**Key Python Packages:**
- pynput — Cross-platform global hotkeys **without sudo**
- pyaudio — Audio recording
- pygame — Audio feedback
- torch — Whisper engine support
- faster-whisper (>=0.10.0) — CTranslate2 optimization (4x speedup)
- psutil — Resource monitoring
- pystray + pillow — System tray

## Testing

**Test Markers:**
- `-m unit` — Individual component tests with mocked dependencies
- `-m integration` — Cross-component workflow tests
- `-m stress` — 1000-cycle resource leak detection, race conditions, crash resilience
- `-m requires_audio` — Tests needing audio hardware
- `-m requires_internet` — Tests needing network

**Coverage Breakdown:**
- Audio module: 100%
- Config module: 92%
- Speech module: 85%
- Utils module: 68%
- GUI module: 51%

## Important Implementation Notes

### GPU Detection
- GPU check: `speech/engines.py:86-96` (torch.cuda.is_available() + cuDNN validation)
- Device selection: FP16 on GPU, FP32/INT8 on CPU
- Config override: `force_cpu: true` disables GPU

### Engine Priority
FasterWhisperEngine → WhisperEngine → GoogleSpeechEngine (`speech/engines.py:565-596`)

### Process Lock
Uses `fcntl` file locking (`main.py:32`). If app crashes, manually remove `/tmp/voice_transcription.lock`.

### Hotkeys (Linux)
Uses pynput instead of keyboard library to avoid sudo. See `docs/LINUX_HOTKEY_SOLUTION.md`.

### Auto-Paste Focus Management
Captures active window before recording (`utils/autopaste.py:55`), restores before paste.
Terminal apps use Ctrl+Shift+V; browser detection prevents address bar issues.

### Health Monitor
Monitors CPU/memory every 30s. Limits: 2048MB memory, 98% CPU (`utils/health_monitor.py:14`).

### Default Settings
- Hotkey: Alt+D (record toggle)
- Audio: 16kHz, mono, 30s max
- Engine: faster-whisper > whisper > google
- Model: base (configurable: tiny/base/small/medium/large)
- GPU: Auto-detect with CPU fallback

## Common Development Patterns

### Adding a New Manager Component
1. Create manager class in appropriate module
2. Initialize in `VoiceTranscriptionApp.__init__()` (`gui/main_window.py:61`)
3. Add config fields to `ConfigManager` (`config/settings.py`)
4. Write unit tests in `tests/test_*.py`

### Adding a New Speech Engine
1. Inherit from `SpeechEngine` ABC (`speech/engines.py:31`)
2. Implement `transcribe()`, `is_available()`, `name`
3. Register in `SpeechEngineManager._init_engines()` (`speech/engines.py:565`)
4. Add dependency check in `main.py:check_dependencies()`

## Key Files Quick Reference

| File | Purpose |
|------|---------|
| `voice_transcription_tool/main.py` | Entry point, process lock |
| `gui/main_window.py` | VoiceTranscriptionApp coordinator |
| `speech/engines.py` | All 3 speech engines |
| `audio/recorder.py` | AudioRecorder + RMS |
| `config/settings.py` | ConfigManager, JSON persistence |
| `utils/hotkeys.py` | HotkeyManager (pynput) |
| `utils/autopaste.py` | AutoPasteManager (xdotool) |
| `utils/tray_manager.py` | TrayManager (PIL icons) |
| `utils/health_monitor.py` | Resource limit monitoring |

## Known Limitations

- xdotool auto-paste is Linux-only (Windows/macOS planned)
- No CI/CD pipeline yet (GitHub Actions planned)
- GPU requires manual CUDA/cuDNN installation
