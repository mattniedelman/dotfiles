"""Configure pytest for skillers tests."""

import sys
from pathlib import Path

# Add skillers directory to path for standalone imports
_SKILLERS_PATH = Path(__file__).parent.parent / "skillers"
sys.path.insert(0, str(_SKILLERS_PATH))
