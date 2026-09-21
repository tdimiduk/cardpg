#!/usr/bin/env python3
"""
Forwarding wrapper for tools/design_utils/keyword_mod.py
"""
import sys
from pathlib import Path

# Add design_utils directory to path
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from keyword_mod import main

if __name__ == "__main__":
    main()
