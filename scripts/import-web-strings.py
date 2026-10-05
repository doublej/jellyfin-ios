#!/usr/bin/env python3
"""Copy wording from jellyfin-ui's messages/{en,nl}.json into Localizable.strings.

Only keys listed in KEYS (the screens this app shares with the web client) are copied; keys
already in a .strings file keep their iOS wording unless --force. `{name}` placeholders become
positional `%1$@`, numbered by their order in the English text, so Dutch can reorder them.

    scripts/import-web-strings.py [--force]
"""
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
WEB = Path.home() / "dev/web/jellyfin-ui/messages"
OUT = ROOT / "jellyfin-ios/App/Resources/{locale}.lproj/Localizable.strings"
KEYS = Path(__file__).with_name("web-keys.txt")
ENTRY = re.compile(r'^"((?:[^"\\]|\\.)*)"\s*=\s*"((?:[^"\\]|\\.)*)";', re.M)


def order(text: str) -> list[str]:
    names: list[str] = []
    for name in re.findall(r"\{(\w+)\}", text):
        if name not in names:
            names.append(name)
    return names


def convert(text: str, names: list[str]) -> str:
    escaped = text.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n")
    return re.sub(r"\{(\w+)\}", lambda m: f"%{names.index(m[1]) + 1}$@", escaped)


def main() -> None:
    force = "--force" in sys.argv
    keys = [k.strip() for k in KEYS.read_text().splitlines() if k.strip() and not k.startswith("#")]
    english = json.loads((WEB / "en.json").read_text())
    for locale in ("en", "nl"):
        web = json.loads((WEB / f"{locale}.json").read_text())
        path = Path(str(OUT).format(locale=locale))
        current = dict(ENTRY.findall(path.read_text())) if path.exists() else {}
        for key in keys:
            if key in current and not force:
                continue
            current[key] = convert(web[key], order(english[key]))
        lines = [f'"{key}" = "{value}";' for key, value in sorted(current.items())]
        path.write_text("\n".join(lines) + "\n")
        print(f"{locale}: {len(current)} keys")


main()
