# /// script
# requires-python = ">=3.11"
# ///

from __future__ import annotations

import argparse
import fcntl
import json
import os
import re
import subprocess
import sys
import tempfile
import time
import tomllib
from pathlib import Path
from typing import Any


PROFILE_RE = re.compile(r"^[a-z][a-z0-9_]*$")
VALID_EFFORTS = {"low", "medium", "high", "xhigh"}
VALID_SERVICE_TIERS = {"default", "fast"}
VALID_SANDBOXES = {"read-only", "workspace-write", "danger-full-access"}
REQUIRED_PROFILE_KEYS = {
    "name",
    "description",
    "developer_instructions",
    "model",
    "model_reasoning_effort",
    "service_tier",
    "sandbox_mode",
    "features",
}


class DispatchError(Exception):
    pass


def read_toml(path: Path) -> dict[str, Any]:
    try:
        with path.open("rb") as handle:
            return tomllib.load(handle)
    except FileNotFoundError as exc:
        raise DispatchError(f"missing configuration: {path}") from exc
    except tomllib.TOMLDecodeError as exc:
        raise DispatchError(f"invalid TOML in {path}: {exc}") from exc


def load_profile(codex_home: Path, profile_name: str) -> dict[str, Any]:
    if not PROFILE_RE.fullmatch(profile_name):
        raise DispatchError(f"invalid profile name: {profile_name}")

    profile_path = codex_home / "agents" / f"{profile_name}.toml"
    profile = read_toml(profile_path)
    missing = sorted(REQUIRED_PROFILE_KEYS - profile.keys())
    if missing:
        raise DispatchError(f"profile {profile_name} is missing: {', '.join(missing)}")
    if profile["name"] != profile_name:
        raise DispatchError(f"profile name mismatch in {profile_path}")
    if profile["model_reasoning_effort"] not in VALID_EFFORTS:
        raise DispatchError(f"unsupported effort in {profile_path}")
    if profile["service_tier"] not in VALID_SERVICE_TIERS:
        raise DispatchError(f"unsupported service tier in {profile_path}")
    if profile["sandbox_mode"] not in VALID_SANDBOXES:
        raise DispatchError(f"unsupported sandbox in {profile_path}")
    features = profile["features"]
    if not isinstance(features, dict) or not isinstance(features.get("fast_mode"), bool):
        raise DispatchError(f"features.fast_mode must be a boolean in {profile_path}")
    expected_speed = ("fast", True) if profile["model_reasoning_effort"] == "low" else ("default", False)
    if (profile["service_tier"], features["fast_mode"]) != expected_speed:
        raise DispatchError(
            f"profile speed must be fast for low effort and default otherwise in {profile_path}"
        )
    return profile


def load_policy(codex_home: Path) -> dict[str, Any]:
    policy = read_toml(codex_home / "dispatch.toml")
    if policy.get("mode") not in {"automatic", "confirm", "off"}:
        raise DispatchError("dispatch mode must be automatic, confirm, or off")
    if policy.get("backend") != "exec":
        raise DispatchError("only the exec dispatch backend is currently supported")
    if policy.get("max_parallel") != 1:
        raise DispatchError("max_parallel must remain 1 while using the exec backend")
    if policy.get("capture_evidence") is not True:
        raise DispatchError("capture_evidence must remain enabled")
    return policy


def confirmation_required(policy: dict[str, Any], profile_name: str) -> bool:
    return policy["mode"] == "confirm" or profile_name in policy.get("confirm_profiles", [])


def runtime_temp_dir() -> Path:
    return Path(os.environ.get("CODEX_DISPATCH_TMP", "/tmp"))


def build_prompt(profile: dict[str, Any], task: str) -> str:
    return f"""You are a delegated Codex worker using the {profile['name']} profile.

Delegation boundary:
- Do not spawn agents, launch another Codex process, or delegate further.
- Complete only the assignment below.
- Preserve unrelated work and do not commit, push, deploy, or edit global configuration.
- Stop after the acceptance criteria and required validation pass.

Profile instructions:
{profile['developer_instructions'].strip()}

Assignment:
{task.strip()}
"""


def build_command(
    codex_bin: str,
    cwd: Path,
    profile: dict[str, Any],
    report_path: Path,
) -> list[str]:
    return [
        codex_bin,
        "exec",
        "-C",
        str(cwd),
        "-m",
        profile["model"],
        "-c",
        f'model_reasoning_effort="{profile["model_reasoning_effort"]}"',
        "-c",
        f'service_tier="{profile["service_tier"]}"',
        "-c",
        f'features.fast_mode={str(profile["features"]["fast_mode"]).lower()}',
        "-s",
        profile["sandbox_mode"],
        "--json",
        "-o",
        str(report_path),
        "-",
    ]


def extract_session_id(event_path: Path) -> str | None:
    if not event_path.exists():
        return None
    for line in event_path.read_text(encoding="utf-8").splitlines():
        try:
            event = json.loads(line)
        except json.JSONDecodeError:
            continue
        if event.get("type") == "thread.started":
            return event.get("thread_id")
    return None


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Run one pinned Codex profile.")
    parser.add_argument("--profile", required=True)
    parser.add_argument("--cwd", type=Path, required=True)
    parser.add_argument("--prompt-file", type=Path)
    parser.add_argument("--prompt")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--confirmed", action="store_true")
    parser.add_argument("--artifact-dir", type=Path)
    parser.add_argument("--codex-bin", default=os.environ.get("CODEX_BIN", "codex"))
    parser.add_argument(
        "--codex-home",
        type=Path,
        default=Path(os.environ.get("CODEX_HOME", Path.home() / ".codex")),
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    try:
        codex_home = args.codex_home.expanduser().resolve()
        cwd = args.cwd.expanduser().resolve()
        if not cwd.is_dir():
            raise DispatchError(f"working directory does not exist: {cwd}")

        policy = load_policy(codex_home)
        if policy["mode"] == "off":
            raise DispatchError("dispatch is disabled by policy")
        profile = load_profile(codex_home, args.profile)
        summary: dict[str, Any] = {
            "profile": profile["name"],
            "model": profile["model"],
            "effort": profile["model_reasoning_effort"],
            "service_tier": profile["service_tier"],
            "fast_mode": profile["features"]["fast_mode"],
            "sandbox": profile["sandbox_mode"],
            "requires_confirmation": confirmation_required(policy, args.profile),
            "backend": policy["backend"],
        }
        if args.dry_run:
            summary["status"] = "preview"
            print(json.dumps(summary, indent=2))
            return 0
        if args.prompt_file is not None and args.prompt is not None:
            raise DispatchError("use only one of --prompt-file or --prompt")
        if args.prompt_file is None and args.prompt is None:
            raise DispatchError("--prompt-file or --prompt is required unless --dry-run is used")
        if summary["requires_confirmation"] and not args.confirmed:
            raise DispatchError(f"profile {args.profile} requires confirmation; rerun with --confirmed")

        task = args.prompt_file.read_text(encoding="utf-8") if args.prompt_file else args.prompt
        assert task is not None
        if not task.strip():
            raise DispatchError("prompt is empty")
        artifact_dir = args.artifact_dir
        if artifact_dir is None:
            artifact_dir = Path(
                tempfile.mkdtemp(prefix="codex-dispatch.", dir=runtime_temp_dir())
            )
        else:
            artifact_dir = artifact_dir.expanduser().resolve()
            artifact_dir.mkdir(parents=True, exist_ok=True)

        report_path = artifact_dir / "report.md"
        event_path = artifact_dir / "events.jsonl"
        stderr_path = artifact_dir / "stderr.log"
        command = build_command(args.codex_bin, cwd, profile, report_path)
        env = os.environ.copy()
        env["CODEX_DISPATCH_CHILD"] = "1"
        started = time.monotonic()
        lock_path = runtime_temp_dir() / f"codex-dispatch-{os.getuid()}.lock"
        with lock_path.open("w", encoding="utf-8") as lock_handle:
            try:
                fcntl.flock(lock_handle, fcntl.LOCK_EX | fcntl.LOCK_NB)
            except BlockingIOError as exc:
                raise DispatchError("another delegated Codex process is already running") from exc
            with event_path.open("w", encoding="utf-8") as stdout_handle, stderr_path.open(
                "w", encoding="utf-8"
            ) as stderr_handle:
                completed = subprocess.run(
                    command,
                    input=build_prompt(profile, task),
                    text=True,
                    stdout=stdout_handle,
                    stderr=stderr_handle,
                    env=env,
                    check=False,
                )

        summary.update(
            {
                "status": "completed" if completed.returncode == 0 else "failed",
                "exit_code": completed.returncode,
                "elapsed_seconds": round(time.monotonic() - started, 2),
                "session_id": extract_session_id(event_path),
                "report_path": str(report_path),
                "events_path": str(event_path),
                "stderr_path": str(stderr_path),
                "report": report_path.read_text(encoding="utf-8") if report_path.exists() else "",
            }
        )
        print(json.dumps(summary, indent=2))
        return completed.returncode
    except (DispatchError, OSError) as exc:
        print(json.dumps({"status": "error", "error": str(exc)}), file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
