#!/usr/bin/env python3
"""Generate 'aurora' gradient wallpapers, one per theme, from themes/*.yaml.

Soft blurred color blobs from each palette's accents over a crust->base
gradient — cohesive, license-free, and regenerable whenever palettes change:

    python3 themes/generate-wallpapers.py

Writes Pictures/wallpapers/aurora-<theme>.jpg in the chezmoi source tree
(deployed to ~/Pictures/wallpapers by chezmoi apply).
"""

import os
import re
import sys

from PIL import Image, ImageDraw, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
OUT_DIR = os.path.join(HERE, "..", "Pictures", "wallpapers")
W, H = 1440, 960          # render size; upscaled 2x on save
FINAL = (2880, 1920)      # Framework 13 native


def hex_rgb(h):
    return tuple(int(h[i : i + 2], 16) for i in (0, 2, 4))


def load_palette(path):
    txt = open(path).read()
    return dict(re.findall(r'^\s+(\w+): "([0-9a-fA-F]{6})"', txt, re.M))


def aurora(colors):
    base, crust = hex_rgb(colors["base"]), hex_rgb(colors["crust"])

    # Vertical gradient crust (top) -> base (bottom).
    img = Image.new("RGB", (W, H))
    d = ImageDraw.Draw(img)
    for y in range(H):
        t = y / H
        d.line(
            [(0, y), (W, y)],
            fill=tuple(round(crust[i] + (base[i] - crust[i]) * t) for i in range(3)),
        )

    # Blurred accent blobs on an overlay.
    blobs = [
        (colors["accent"], (0.72, 0.22), 0.42, 120),
        (colors["accent2"], (0.22, 0.72), 0.38, 100),
        (colors["blue"], (0.88, 0.85), 0.30, 80),
        (colors["mauve"], (0.10, 0.12), 0.26, 60),
    ]
    overlay = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    od = ImageDraw.Draw(overlay)
    for hexcol, (cx, cy), r, alpha in blobs:
        rgb = hex_rgb(hexcol)
        rx, ry = W * r, H * r * 0.9
        x, y = W * cx, H * cy
        od.ellipse([x - rx, y - ry, x + rx, y + ry], fill=rgb + (alpha,))
    overlay = overlay.filter(ImageFilter.GaussianBlur(150))
    img = Image.alpha_composite(img.convert("RGBA"), overlay).convert("RGB")

    # Faint grain so the gradient doesn't band.
    noise = Image.effect_noise((W, H), 14).convert("L")
    img = Image.composite(img, Image.merge("RGB", (noise, noise, noise)),
                          Image.new("L", (W, H), 247))

    return img.resize(FINAL, Image.LANCZOS)


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    for f in sorted(os.listdir(HERE)):
        if not f.endswith(".yaml"):
            continue
        name = f[:-5]
        out = os.path.join(OUT_DIR, f"aurora-{name}.jpg")
        aurora(load_palette(os.path.join(HERE, f))).save(out, quality=88)
        print(f"wrote {out}")


if __name__ == "__main__":
    sys.exit(main())
