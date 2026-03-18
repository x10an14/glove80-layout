#!/usr/bin/env python3
"""Generate an oxeylyzer .dof file from a Glove80 ZMK keymap.

Parses the base layer of a Glove80 keymap and produces a .dof JSON file
suitable for analysis with oxeylyzer. Extracts the 3×10 alpha grid from
the Glove80's inner columns (positions 23-27 + 28-32 per row).

Uses "colstag" board type (column-stagger, 3×10) with "traditional"
fingering. See TODO.md for trade-offs vs. full 4×12 custom board.

Glove80 key positions (80 keys, 6 rows):
  Row 0:  0- 9  (5+5, F-keys)           — skipped
  Row 1: 10-21  (6+6, numbers/layer)     — skipped
  Row 2: 22-33  (6+6, upper alpha)       → inner 5+5 used
  Row 3: 34-45  (6+6, home row)          → inner 5+5 used
  Row 4: 46-63  (6+6+6, lower+inner)     → inner 5+5 used
  Row 5: 64-79  (5+3+3+5, bottom+thumb)  — skipped

Usage: keymap-to-dof.py [keymap-file]
"""

import json
from pathlib import Path
import re
import sys

# ZMK key code → character
ZMK_TO_CHAR = {
    **{c: c.lower() for c in "ABCDEFGHIJKLMNOPQRSTUVWXYZ"},
    "GRAVE": "`",
    "BACKSLASH": "\\",
    "SINGLE_QUOTE": "'",
    "SLASH": "/",
    "EQUAL": "=",
    "SEMICOLON": ";",
    "COMMA": ",",
    "DOT": ".",
    "MINUS": "-",
    "LBKT": "[",
    "RBKT": "]",
    "LEFT_BRACKET": "[",
    "RIGHT_BRACKET": "]",
    "SPACE": "spc",
    **{f"N{i}": str(i) for i in range(10)},
    **{f"NUMBER_{i}": str(i) for i in range(10)},
}


def parse_binding(binding_text):
    """Extract the character produced by a ZMK binding, or None."""
    if not (parts := binding_text.strip().split()):
        return None

    behavior = parts[0]

    if behavior == "kp" and len(parts) >= 2:
        return ZMK_TO_CHAR.get(parts[1])

    if (
        behavior in ("homey_left", "homey_right", "shift_left", "shift_right")
        and len(parts) >= 3
    ):
        return ZMK_TO_CHAR.get(parts[2])

    return None


def extract_base_layer_bindings(keymap_text):
    """Extract the flat list of bindings from the first keymap layer."""
    if not (
        match := re.search(
            r"keymap\s*\{.*?bindings\s*=\s*<\s*(.*?)\s*>;",
            keymap_text,
            re.DOTALL,
        )
    ):
        raise ValueError("Could not find base layer bindings in keymap")

    raw = match.group(1)
    return [p.strip() for p in raw.split("&") if p.strip()]


def build_dof(bindings):
    """Build a colstag 3×10 .dof dict from 80 Glove80 bindings."""
    if len(bindings) != 80:
        raise ValueError(f"Expected 80 bindings, got {len(bindings)}")

    def char_at(idx):
        c = parse_binding(bindings[idx])
        return c if c else "~"

    # 3×10 grid: inner 5 keys per hand from rows 2-4
    # Row 2: positions 23-27 (left inner 5) + 28-32 (right inner 5)
    # Row 3: positions 35-39 (left inner 5) + 40-44 (right inner 5)
    # Row 4: positions 47-51 (left inner 5) + 59-63 (right inner 5)
    rows = [
        [char_at(i) for i in range(23, 28)] + [char_at(i) for i in range(28, 33)],
        [char_at(i) for i in range(35, 40)] + [char_at(i) for i in range(40, 45)],
        [char_at(i) for i in range(47, 52)] + [char_at(i) for i in range(59, 64)],
    ]

    def fmt_row(row):
        return f"{' '.join(row[:5])}  {' '.join(row[5:])}"

    return {
        "name": "engrammerno",
        "authors": ["x10an14"],
        "board": "colstag",
        "layers": {
            "main": [fmt_row(r) for r in rows],
        },
        "fingering": "traditional",
    }


def main():
    keymap_path = sys.argv[1] if len(sys.argv) > 1 else "config/glove80.keymap"
    keymap_text = Path(keymap_path).read_text()

    bindings = extract_base_layer_bindings(keymap_text)
    dof = build_dof(bindings)

    print(json.dumps(dof, indent=4))


if __name__ == "__main__":
    main()
