from __future__ import annotations

import importlib.util
import fcntl
import json
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


SCRIPT = Path(__file__).parents[1] / "scripts" / "dispatch.py"
REPO_CODEX_HOME = Path(__file__).parents[3]
SPEC = importlib.util.spec_from_file_location("codex_dispatch", SCRIPT)
assert SPEC and SPEC.loader
DISPATCH = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(DISPATCH)


class DispatchTests(unittest.TestCase):
    def setUp(self) -> None:
        self.tempdir = tempfile.TemporaryDirectory()
        self.root = Path(self.tempdir.name)
        self.previous_dispatch_tmp = os.environ.get("CODEX_DISPATCH_TMP")
        os.environ["CODEX_DISPATCH_TMP"] = str(self.root / "runtime")
        DISPATCH.runtime_temp_dir().mkdir()
        self.codex_home = self.root / "codex-home"
        self.agents = self.codex_home / "agents"
        self.agents.mkdir(parents=True)
        (self.codex_home / "dispatch.toml").write_text(
            'mode = "automatic"\nbackend = "exec"\nmax_parallel = 1\n'
            'capture_evidence = true\n'
            'confirm_profiles = ["implement_deep"]\n',
            encoding="utf-8",
        )
        self.write_profile(
            "investigate", "gpt-5.6-sol", "medium", "default", False, "read-only"
        )
        self.write_profile(
            "implement_deep", "gpt-5.6-sol", "high", "default", False, "workspace-write"
        )
        self.write_profile("lookup", "gpt-5.6-sol", "low", "fast", True, "read-only")

    def tearDown(self) -> None:
        if self.previous_dispatch_tmp is None:
            os.environ.pop("CODEX_DISPATCH_TMP", None)
        else:
            os.environ["CODEX_DISPATCH_TMP"] = self.previous_dispatch_tmp
        self.tempdir.cleanup()

    def write_profile(
        self,
        name: str,
        model: str,
        effort: str,
        service_tier: str,
        fast_mode: bool,
        sandbox: str,
    ) -> None:
        (self.agents / f"{name}.toml").write_text(
            f'name = "{name}"\n'
            f'description = "{name} profile"\n'
            f'model = "{model}"\n'
            f'model_reasoning_effort = "{effort}"\n'
            f'service_tier = "{service_tier}"\n'
            f'sandbox_mode = "{sandbox}"\n'
            'developer_instructions = "Stay bounded."\n'
            "[features]\n"
            f"fast_mode = {str(fast_mode).lower()}\n",
            encoding="utf-8",
        )

    def run_script(self, *arguments: str) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [sys.executable, str(SCRIPT), *arguments],
            text=True,
            capture_output=True,
            check=False,
        )

    def test_preview_reports_runtime_and_confirmation(self) -> None:
        normal = self.run_script(
            "--profile",
            "investigate",
            "--cwd",
            str(self.root),
            "--codex-home",
            str(self.codex_home),
            "--dry-run",
        )
        deep = self.run_script(
            "--profile",
            "implement_deep",
            "--cwd",
            str(self.root),
            "--codex-home",
            str(self.codex_home),
            "--dry-run",
        )
        self.assertEqual(normal.returncode, 0)
        self.assertFalse(json.loads(normal.stdout)["requires_confirmation"])
        self.assertTrue(json.loads(deep.stdout)["requires_confirmation"])
        self.assertEqual(json.loads(normal.stdout)["model"], "gpt-5.6-sol")
        self.assertEqual(json.loads(normal.stdout)["service_tier"], "default")
        self.assertFalse(json.loads(normal.stdout)["fast_mode"])

    def test_repository_profile_matrix(self) -> None:
        expected = {
            "lookup": ("gpt-5.6-sol", "low", "fast", True, "read-only"),
            "investigate": ("gpt-5.6-sol", "medium", "default", False, "read-only"),
            "implement": ("gpt-5.6-sol", "medium", "default", False, "workspace-write"),
            "implement_fast": ("gpt-5.6-sol", "high", "default", False, "workspace-write"),
            "implement_deep": ("gpt-5.6-sol", "high", "default", False, "workspace-write"),
            "review": ("gpt-5.6-sol", "medium", "default", False, "read-only"),
            "review_fast": ("gpt-5.6-sol", "high", "default", False, "read-only"),
        }
        policy = DISPATCH.load_policy(REPO_CODEX_HOME)
        self.assertEqual(policy["mode"], "automatic")
        for name, runtime in expected.items():
            profile = DISPATCH.load_profile(REPO_CODEX_HOME, name)
            self.assertEqual(
                (
                    profile["model"],
                    profile["model_reasoning_effort"],
                    profile["service_tier"],
                    profile["features"]["fast_mode"],
                    profile["sandbox_mode"],
                ),
                runtime,
            )

    def test_rejects_speed_that_does_not_match_effort(self) -> None:
        self.write_profile("invalid", "gpt-5.6-sol", "low", "default", False, "read-only")
        with self.assertRaisesRegex(DISPATCH.DispatchError, "profile speed"):
            DISPATCH.load_profile(self.codex_home, "invalid")

    def test_rejects_invalid_service_tier_and_fast_mode_type(self) -> None:
        self.write_profile("invalid_tier", "gpt-5.6-sol", "low", "priority", True, "read-only")
        with self.assertRaisesRegex(DISPATCH.DispatchError, "unsupported service tier"):
            DISPATCH.load_profile(self.codex_home, "invalid_tier")

        self.write_profile("invalid_feature", "gpt-5.6-sol", "high", "default", False, "read-only")
        path = self.agents / "invalid_feature.toml"
        path.write_text(
            path.read_text(encoding="utf-8").replace("fast_mode = false", 'fast_mode = "false"'),
            encoding="utf-8",
        )
        with self.assertRaisesRegex(DISPATCH.DispatchError, "must be a boolean"):
            DISPATCH.load_profile(self.codex_home, "invalid_feature")

    def test_build_command_for_fast_profile_is_exact(self) -> None:
        profile = DISPATCH.load_profile(self.codex_home, "lookup")
        report = self.root / "report.md"
        self.assertEqual(
            DISPATCH.build_command("codex", self.root, profile, report),
            [
                "codex",
                "exec",
                "-C",
                str(self.root),
                "-m",
                "gpt-5.6-sol",
                "-c",
                'model_reasoning_effort="low"',
                "-c",
                'service_tier="fast"',
                "-c",
                "features.fast_mode=true",
                "-s",
                "read-only",
                "--json",
                "-o",
                str(report),
                "-",
            ],
        )

    def test_rejects_unknown_and_unsafe_profile_names(self) -> None:
        for name in ("missing", "../investigate"):
            result = self.run_script(
                "--profile",
                name,
                "--cwd",
                str(self.root),
                "--codex-home",
                str(self.codex_home),
                "--dry-run",
            )
            self.assertEqual(result.returncode, 2)

    def test_build_prompt_prevents_recursive_dispatch(self) -> None:
        profile = DISPATCH.load_profile(self.codex_home, "investigate")
        prompt = DISPATCH.build_prompt(profile, "Trace the request.")
        self.assertIn("Do not spawn agents", prompt)
        self.assertIn("Stay bounded.", prompt)
        self.assertIn("Trace the request.", prompt)

    def test_deep_profile_requires_confirmation(self) -> None:
        blocked = self.run_script(
            "--profile",
            "implement_deep",
            "--cwd",
            str(self.root),
            "--codex-home",
            str(self.codex_home),
            "--prompt",
            "Implement the bounded task.",
        )
        self.assertEqual(blocked.returncode, 2)
        self.assertIn("requires confirmation", blocked.stderr)

    def test_rejects_concurrent_dispatch(self) -> None:
        prompt = self.root / "prompt.md"
        prompt.write_text("Trace the request.", encoding="utf-8")
        lock_path = DISPATCH.runtime_temp_dir() / f"codex-dispatch-{os.getuid()}.lock"
        with lock_path.open("w", encoding="utf-8") as lock_handle:
            fcntl.flock(lock_handle, fcntl.LOCK_EX | fcntl.LOCK_NB)
            blocked = self.run_script(
                "--profile",
                "investigate",
                "--cwd",
                str(self.root),
                "--codex-home",
                str(self.codex_home),
                "--prompt-file",
                str(prompt),
            )
        self.assertEqual(blocked.returncode, 2)
        self.assertIn("already running", blocked.stderr)

    def test_fake_codex_receives_pinned_runtime_and_returns_evidence(self) -> None:
        fake = self.root / "fake-codex"
        fake.write_text(
            "#!/bin/sh\n"
            "payload=$(cat)\n"
            "printf '%s\\n' \"$@\" > \"$FAKE_ARGS\"\n"
            "printf '%s' \"$payload\" > \"$FAKE_PROMPT\"\n"
            "report=''\n"
            "previous=''\n"
            "for value in \"$@\"; do\n"
            "  if [ \"$previous\" = '-o' ]; then report=$value; fi\n"
            "  previous=$value\n"
            "done\n"
            "printf 'delegated report' > \"$report\"\n"
            "printf '%s\\n' '{\"type\":\"thread.started\",\"thread_id\":\"thread-test\"}'\n",
            encoding="utf-8",
        )
        fake.chmod(0o755)
        prompt = self.root / "prompt.md"
        prompt.write_text("Trace the request.", encoding="utf-8")
        artifact = self.root / "artifacts"
        env = os.environ.copy()
        env["FAKE_ARGS"] = str(self.root / "args.txt")
        env["FAKE_PROMPT"] = str(self.root / "composed-prompt.txt")
        result = subprocess.run(
            [
                sys.executable,
                str(SCRIPT),
                "--profile",
                "investigate",
                "--cwd",
                str(self.root),
                "--codex-home",
                str(self.codex_home),
                "--codex-bin",
                str(fake),
                "--artifact-dir",
                str(artifact),
                "--prompt-file",
                str(prompt),
            ],
            text=True,
            capture_output=True,
            env=env,
            check=False,
        )
        summary = json.loads(result.stdout)
        arguments = (self.root / "args.txt").read_text(encoding="utf-8").splitlines()
        composed_prompt = (self.root / "composed-prompt.txt").read_text(encoding="utf-8")
        self.assertEqual(result.returncode, 0)
        self.assertEqual(
            arguments,
            [
                "exec",
                "-C",
                str(self.root.resolve()),
                "-m",
                "gpt-5.6-sol",
                "-c",
                'model_reasoning_effort="medium"',
                "-c",
                'service_tier="default"',
                "-c",
                "features.fast_mode=false",
                "-s",
                "read-only",
                "--json",
                "-o",
                str((artifact / "report.md").resolve()),
                "-",
            ],
        )
        self.assertIn("Do not spawn agents", composed_prompt)
        self.assertEqual(summary["session_id"], "thread-test")
        self.assertEqual(summary["report"], "delegated report")


if __name__ == "__main__":
    unittest.main()
