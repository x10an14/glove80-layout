#!/usr/bin/env python3
"""Read a .dof layout from stdin, score it with oxeylyzer,
and print one CSV row to stdout. All diagnostic output goes to stderr.

Usage: keymap-to-dof.py config/glove80.keymap | generate_dof_score.py

Env vars (set by nix run / devShell):
  OXEYLYZER_STATIC — oxeylyzer's static/ data directory
  CONFIG_TOML      — path to config.toml (default: repo config.toml)
"""

from os import environ
from pathlib import Path
import re
import tempfile
import subprocess
import sys

METRICS = [
    ("Score:", "score"),
    ("Sfb:", "sfb"),  # Same Finger Bigram
    ("Dsfb:", "dsfb"),  # Distance Same Finger Bigram
    ("Finger Speed:", "finger_speed"),
    ("Total Rolls:", "rolls"),
    ("Total Alternates:", "alternates"),
    ("Total Redirects:", "redirects"),
    ("Scissors:", "scissors"),
    ("Stretches:", "stretches"),
]


def log(*args, **kwargs):
    print(*args, file=sys.stderr, **kwargs)


def run_oxeylyzer(dof_json, config_toml, static_dir):
    """Set up a temp workdir, run oxeylyzer, return its output."""
    with tempfile.TemporaryDirectory() as f:
        tmp_folder, config_file, static_files = (
            Path(f),
            Path(config_toml),
            Path(static_dir),
        )
        config_file, static_files = (
            config_file.copy_into(tmp_folder),
            static_files.copy_into(tmp_folder),
        )

        for lang in ("english", "bokmal"):
            dof = static_files / "layouts" / lang / "engrammerno.dof"
            dof.parent.mkdir(parents=True, exist_ok=True)
            dof.write_text(dof_json)

        result = subprocess.run(
            ["oxeylyzer"],
            input="analyze engrammerno\nlanguage bokmal\nanalyze engrammerno\nquit\n",
            capture_output=True,
            text=True,
            cwd=tmp_folder,
        )
        return result.stdout + result.stderr


def parse_metrics(output):
    """Extract metric values per language from oxeylyzer output."""
    num_re, values, lang = re.compile(r"-?\d+\.\d+%?"), {}, "en"
    for line in output.splitlines():
        if "Set language to" in line:
            lang = "nb_no"
        for label, key in METRICS:
            if label in line:
                m = num_re.search(line[line.index(label) + len(label) :])
                if m:
                    values[f"{lang}_{key}"] = m.group().rstrip("%")
    return values


def main():
    missing = [
        v
        for v in ("OXEYLYZER_STATIC", "CONFIG_TOML")
        if v not in environ or not Path(environ[v]).exists()
    ]
    if missing != []:
        sys.exit(f"Error: {', '.join(missing)} must be set to valid path(s)")

    static_dir, config_toml = (
        Path(environ["OXEYLYZER_STATIC"]),
        Path(environ["CONFIG_TOML"]),
    )
    dof_json = sys.stdin.read()

    log("=== EngrammerNO Layout Analysis ===\n")
    log(dof_json)

    output = run_oxeylyzer(dof_json, config_toml, static_dir)
    log(output)

    values = parse_metrics(output)
    print(
        ",".join(
            values.get(f"{lang}_{key}", "")
            for lang in ("en", "nb_no")
            for _, key in METRICS
        )
    )


if __name__ == "__main__":
    main()
