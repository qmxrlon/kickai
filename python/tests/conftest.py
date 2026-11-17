import os
import sys
import tempfile
from pathlib import Path

# Configure the environment before any app module is imported.
os.environ.setdefault("DATABASE_URL", "postgresql://test:test@localhost:5432/kickai_test")
os.environ.setdefault("MODEL_DIR", tempfile.mkdtemp(prefix="kickai-models-"))
os.environ.setdefault("API_SECRET_KEY", "test-secret")
os.environ.setdefault("ENVIRONMENT", "test")

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
