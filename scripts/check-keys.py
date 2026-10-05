#!/usr/bin/env python3
"""`just keys-check`: every L10n key the app uses exists in the base Localizable.strings.

Literal keys come from L10n.t("…") / L10n.f("…"); keys built from a prefix (L10n.t("sort_\\(x)"))
are listed in DYNAMIC with their possible suffixes.
"""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
STRINGS = ROOT / "jellyfin-ios/App/Resources/en.lproj/Localizable.strings"
DYNAMIC = {
    "sort_": ["SortName", "DateCreated", "DateLastContentAdded", "PremiereDate", "CommunityRating", "Runtime", "DatePlayed", "Random"],
    "status_": ["all", "unplayed", "played", "resumable", "favorite"],
    "quality_": ["sd", "hd", "4k", "3d", "bluray", "dvd"],
    "mode_": ["Default", "Smart", "OnlyForced", "Always", "None"],
    "err_": ["incompatible", "not_allowed", "rate_limited", "no_source", "server", "network", "decode", "unsupported",
             "stream", "subtitles", "fatal", "offline"],
    "look_weight_": ["normal", "bold"],
    "font_": ["default", "serif", "mono", "casual", "smallcaps"],
    "background_": ["none", "shade", "box"],
    "shadow_": ["none", "raised", "depressed", "uniform", "drop"],
    "delivery_": ["direct", "remux", "audio", "video", "direct_detail", "remux_detail", "audio_detail", "video_detail"],
}

defined = set(re.findall(r'^"([^"]+)"\s*=', STRINGS.read_text(), re.M))
used: set[str] = set()
for file in (ROOT / "jellyfin-ios/App").rglob("*.swift"):
    for key in re.findall(r'L10n\.[tf]\(\s*"([^"\\]+)(\\\()?', file.read_text()):
        if key[1]:
            used.update(key[0] + suffix for suffix in DYNAMIC.get(key[0], ["?"]))
        else:
            used.add(key[0])
missing = sorted(used - defined)
for key in missing:
    print(f"missing: {key}")
print(f"keys: {len(used)} used, {len(defined)} defined, {len(missing)} missing")
sys.exit(1 if missing else 0)
