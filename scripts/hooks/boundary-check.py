from pathlib import Path
import sys

# Placeholder boundary check hook for local agent tooling.
repo_root = Path(__file__).resolve().parents[2]
if not repo_root.exists():
    sys.exit(1)
sys.exit(0)
