#!/usr/bin/env python3
"""Sync BlackOut content packs from blackout-content into the iOS app bundle.

Copies every free (premium=false) pack verbatim into
BlackOut/Resources/Packs/, and writes a premium-catalog.json with metadata
only (no items) for every pack, so the Hub can render locked premium cards
without shipping their content.

Usage:
    python scripts/sync_content.py

Idempotent: safe to re-run, overwrites its own output only.
"""
from __future__ import annotations

import json
import shutil
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
CONTENT_ROOT = REPO_ROOT.parent / "blackout-content"
PACKS_SRC = CONTENT_ROOT / "content" / "fr" / "packs"
PACKS_DST = REPO_ROOT / "BlackOut" / "Resources" / "Packs"
CATALOG_DST = REPO_ROOT / "BlackOut" / "Resources" / "premium-catalog.json"


def main() -> int:
    if not PACKS_SRC.is_dir():
        print(f"error: content source not found at {PACKS_SRC}", file=sys.stderr)
        return 1

    PACKS_DST.mkdir(parents=True, exist_ok=True)

    catalog: list[dict] = []
    free_count = 0
    premium_count = 0

    for pack_file in sorted(PACKS_SRC.glob("*.json")):
        data = json.loads(pack_file.read_text(encoding="utf-8"))
        meta = data["pack"]
        catalog.append(meta)

        if meta["premium"]:
            premium_count += 1
            continue

        free_count += 1
        dst = PACKS_DST / pack_file.name
        shutil.copyfile(pack_file, dst)

    CATALOG_DST.write_text(
        json.dumps({"schemaVersion": 1, "packs": catalog}, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )

    print(f"synced {free_count} free packs into {PACKS_DST}")
    print(f"wrote catalog with {len(catalog)} packs ({premium_count} premium) to {CATALOG_DST}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
