#!/usr/bin/env python3
"""Generate the Bacchana 1024x1024 App Store icon.

Tavern neobrutalist signature (mirrors tokens.json v2): cream paper
background, a tilted white card with a black spade pip, hard black offset
shadow and an orange accent plate behind the card. No transparency
(App Store icons must be fully opaque). The tavern icon design itself is
unchanged by the product rename (v0.16.0, La Tournee -> Bacchana, final name) -
only the output path follows the renamed `Bacchana/` app folder.

Usage:
    python scripts/gen_app_icon.py
"""
from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw

REPO_ROOT = Path(__file__).resolve().parent.parent
OUTPUT = REPO_ROOT / "Bacchana" / "Assets.xcassets" / "AppIcon.appiconset" / "AppIcon-1024.png"

SIZE = 1024
BG = (255, 249, 240, 255)     # #FFF9F0 paper
NEON = (255, 92, 0, 255)      # #FF5C00 accent orange
CARD_FACE = (255, 255, 255, 255)  # #FFFFFF
CARD_INK = (17, 17, 17, 255)      # #111111


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

    # Orange accent plate behind the card, hard-edged (no blur, no glow).
    plate = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    plate_draw = ImageDraw.Draw(plate)
    plate_draw.rounded_rectangle(
        (SIZE * 0.16, SIZE * 0.14, SIZE * 0.84, SIZE * 0.90),
        radius=int(SIZE * 0.07),
        fill=NEON,
    )
    base = Image.alpha_composite(base, plate)

    # Tilted white card with black spade pip and hard black border.
    card_w, card_h = int(SIZE * 0.5), int(SIZE * 0.72)
    card = Image.new("RGBA", (card_w, card_h), (0, 0, 0, 0))
    card_draw = ImageDraw.Draw(card)
    radius = int(card_w * 0.12)
    card_draw.rounded_rectangle(
        (0, 0, card_w - 1, card_h - 1),
        radius=radius,
        fill=CARD_FACE,
        outline=CARD_INK,
        width=int(SIZE * 0.008),
    )
    draw_spade(card_draw, card_w // 2, int(card_h * 0.46), int(card_w * 0.5), CARD_INK)

    rotated = card.rotate(-8, expand=True, resample=Image.BICUBIC)
    paste_x = (SIZE - rotated.width) // 2
    paste_y = (SIZE - rotated.height) // 2

    # Hard black offset shadow (neobrutalist), drawn from the card silhouette.
    offset = int(SIZE * 0.02)
    shadow = Image.new("RGBA", rotated.size, (0, 0, 0, 0))
    shadow.paste(Image.new("RGBA", rotated.size, CARD_INK), mask=rotated.split()[3])
    base.alpha_composite(shadow, (paste_x + offset, paste_y + offset))
    base.alpha_composite(rotated, (paste_x, paste_y))

    # App Store icons must be fully opaque, no alpha channel.
    flattened = Image.new("RGB", (SIZE, SIZE), BG[:3])
    flattened.paste(base, mask=base.split()[3])

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    flattened.save(OUTPUT, format="PNG")
    print(f"wrote {OUTPUT} ({flattened.size[0]}x{flattened.size[1]})")


if __name__ == "__main__":
    main()
