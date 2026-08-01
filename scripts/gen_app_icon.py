#!/usr/bin/env python3
"""Generate the BlackOut 1024x1024 App Store icon.

Neo-Tokyo Borderland signature: dark arena background, a tilted white card
with a black spade pip, soft red neon halo. No transparency (App Store
icons must be fully opaque).

Usage:
    python scripts/gen_app_icon.py
"""
from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

REPO_ROOT = Path(__file__).resolve().parent.parent
OUTPUT = REPO_ROOT / "BlackOut" / "Assets.xcassets" / "AppIcon.appiconset" / "AppIcon-1024.png"

SIZE = 1024
BG = (9, 9, 11, 255)          # #09090B
NEON = (255, 59, 65, 255)     # #FF3B41
CARD_FACE = (247, 245, 240, 255)  # #F7F5F0
CARD_INK = (17, 17, 20, 255)      # #111114


def draw_spade(draw: ImageDraw.ImageDraw, cx: int, cy: int, size: int, color: tuple) -> None:
    """Draws a simple spade pip using two circles and a triangle, stem below."""
    r = size // 3
    draw.ellipse((cx - r, cy - r, cx, cy + r * 0.4), fill=color)
    draw.ellipse((cx, cy - r, cx + r, cy + r * 0.4), fill=color)
    draw.polygon(
        [(cx - r, cy), (cx + r, cy), (cx, cy - size // 2)],
        fill=color,
    )
    stem_w = size // 10
    draw.polygon(
        [
            (cx - stem_w, cy + r * 0.4),
            (cx + stem_w, cy + r * 0.4),
            (cx + stem_w * 2, cy + size // 2),
            (cx - stem_w * 2, cy + size // 2),
        ],
        fill=color,
    )


def main() -> None:
    base = Image.new("RGBA", (SIZE, SIZE), BG)

    # Soft red neon halo behind the card.
    halo = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    halo_draw = ImageDraw.Draw(halo)
    halo_draw.ellipse(
        (SIZE * 0.18, SIZE * 0.22, SIZE * 0.82, SIZE * 0.86),
        fill=(*NEON[:3], 140),
    )
    halo = halo.filter(ImageFilter.GaussianBlur(radius=SIZE // 10))
    base = Image.alpha_composite(base, halo)

    # Tilted white card with black spade pip.
    card_w, card_h = int(SIZE * 0.5), int(SIZE * 0.72)
    card = Image.new("RGBA", (card_w, card_h), (0, 0, 0, 0))
    card_draw = ImageDraw.Draw(card)
    radius = int(card_w * 0.12)
    card_draw.rounded_rectangle((0, 0, card_w, card_h), radius=radius, fill=CARD_FACE)
    draw_spade(card_draw, card_w // 2, int(card_h * 0.46), int(card_w * 0.5), CARD_INK)

    rotated = card.rotate(-8, expand=True, resample=Image.BICUBIC)
    paste_x = (SIZE - rotated.width) // 2
    paste_y = (SIZE - rotated.height) // 2
    base.alpha_composite(rotated, (paste_x, paste_y))

    # App Store icons must be fully opaque, no alpha channel.
    flattened = Image.new("RGB", (SIZE, SIZE), BG[:3])
    flattened.paste(base, mask=base.split()[3])

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    flattened.save(OUTPUT, format="PNG")
    print(f"wrote {OUTPUT} ({flattened.size[0]}x{flattened.size[1]})")


if __name__ == "__main__":
    main()
