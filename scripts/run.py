#!/usr/bin/env python3
"""
Voice Transcription Tool - Run Script

Usage:
    python run.py           # Run the application
    python run.py --debug   # Run with debug output
"""

import sys
import os

# Add repo root to Python path (this script lives in scripts/, repo root is one level up)
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# Import and run main
from voice_transcription_tool.main import main

if __name__ == "__main__":
    sys.exit(main())