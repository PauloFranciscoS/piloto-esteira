import os
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from runtime.server import health_status, snapshot


class HealthTest(unittest.TestCase):
    def tearDown(self):
        os.environ.pop("HEALTH_MODE", None)
        os.environ.pop("SERVICE", None)
        os.environ.pop("APP_VERSION", None)
        os.environ.pop("GIT_SHA", None)

    def test_health_ok(self):
        self.assertEqual(health_status(), 200)

    def test_health_fail(self):
        os.environ["HEALTH_MODE"] = "fail"
        self.assertEqual(health_status(), 500)

    def test_snapshot_uses_env(self):
        os.environ["SERVICE"] = "api"
        os.environ["APP_VERSION"] = "1"
        os.environ["GIT_SHA"] = "abc"
        self.assertEqual(
            snapshot(),
            {"service": "api", "version": "1", "commit": "abc"},
        )
