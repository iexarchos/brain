"""brainenv — shared setup for the Python scripts in bin/ (the shell version is brain-env.sh).

REPO is the engine checkout, DATA the owner's private data checkout ($BRAIN_DATA, default
REPO/data). Loads DATA/brain.env into os.environ (variables already set win).
"""
import os
import pathlib

REPO = pathlib.Path(__file__).resolve().parent.parent
DATA = pathlib.Path(os.environ.get("BRAIN_DATA") or REPO / "data")


def _load(path):
    try:
        lines = path.read_text(encoding="utf-8").splitlines()
    except OSError:
        return
    for line in lines:
        line = line.strip()
        if line and not line.startswith("#") and "=" in line:
            key, value = line.split("=", 1)
            os.environ.setdefault(key.strip(), value.strip().strip("'\""))


_load(DATA / "brain.env")
OWNER = os.environ.get("OWNER_NAME") or "the owner"
BANK = os.environ.get("HINDSIGHT_BANK_ID") or "brain"
API = os.environ.get("HINDSIGHT_API_URL", "http://127.0.0.1:8888").rstrip("/")
BASE = f"{API}/v1/default/banks/{BANK}"
