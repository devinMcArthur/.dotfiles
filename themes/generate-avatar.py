#!/usr/bin/env python3
"""The Road v2 — perspective road to a sunset disc, aurora sky, theme ring."""
import os
#
# Devin's profile picture ("The Road"): perspective road with yellow->peach
# centerline dashes running into a sunset disc, dusk-aurora sky, ringed by
# the six themes. Regenerate + reapply:
#   python3 themes/generate-avatar.py && magick ~/Pictures/selfies/avatar-road-v2.png -resize 512x512 ~/.face
#   busctl call org.freedesktop.Accounts /org/freedesktop/Accounts/User$(id -u) org.freedesktop.Accounts.User SetIconFile s $HOME/.face

from PIL import Image, ImageDraw, ImageFilter, ImageFont

S = 1024
OUT = os.path.expanduser("~/Pictures/selfies")
CRUST, MANTLE, BASE = "#11111b", "#181825", "#1e1e2e"
YELLOW, PEACH, TEXT = "#f9e2af", "#fab387", "#cdd6f4"
SKY = ["#cba6f7", "#89b4fa", "#fab387"]  # aurora: mauve, blue, peach
RING = ["#f9e2af", "#7aa2f7", "#fabd2f", "#88c0d0", "#ebbcba", "#e68e0d"]


def rgb(h):
    return tuple(int(h[i:i + 2], 16) for i in (1, 3, 5))


def lerp(a, b, t):
    return tuple(round(a[i] + (b[i] - a[i]) * t) for i in range(3))


HORIZON = int(S * 0.56)
VX, VY = S * 0.5, HORIZON

# ── sky: vertical gradient + aurora blobs ──────────────────────────────────
img = Image.new("RGB", (S, S), rgb(CRUST))
d = ImageDraw.Draw(img)
top, bot = rgb(CRUST), rgb("#2a2038")  # warm dusk toward horizon
for y in range(HORIZON):
    d.line([(0, y), (S, y)], fill=lerp(top, bot, (y / HORIZON) ** 1.6))

ov = Image.new("RGBA", (S, S), (0, 0, 0, 0))
od = ImageDraw.Draw(ov)
spots = [(0.22, 0.18, 0.40, 70), (0.80, 0.28, 0.36, 60), (0.5, 0.50, 0.55, 60)]
for (cx, cy, r, a), col in zip(spots, SKY):
    od.ellipse([S * cx - S * r, S * cy - S * r, S * cx + S * r, S * cy + S * r],
               fill=rgb(col) + (a,))
ov = ov.filter(ImageFilter.GaussianBlur(150))
img = Image.alpha_composite(img.convert("RGBA"), ov).convert("RGB")
d = ImageDraw.Draw(img)

# ── sun/moon disc glow at the vanishing point ──────────────────────────────
glow = Image.new("RGBA", (S, S), (0, 0, 0, 0))
gd = ImageDraw.Draw(glow)
gd.ellipse([VX - 250, VY - 250, VX + 250, VY + 250], fill=rgb(PEACH) + (90,))
glow = glow.filter(ImageFilter.GaussianBlur(120))
img = Image.alpha_composite(img.convert("RGBA"), glow).convert("RGB")
d = ImageDraw.Draw(img)

R = 118
for i in range(R, 0, -1):  # radial-ish gradient disc, yellow top -> peach base
    t = 1 - i / R
    d.ellipse([VX - i, VY - 118 - i * 0.0 - (R - i) * 0.0 - i + i, 0, 0][0:0] or
              [VX - i, VY - 60 - i, VX + i, VY - 60 + i],
              fill=lerp(rgb(YELLOW), rgb(PEACH), (1 - t) * 0.9))
# crisp rim
d.ellipse([VX - R, VY - 60 - R, VX + R, VY - 60 + R], outline=rgb(YELLOW), width=3)

# ── ground + road ──────────────────────────────────────────────────────────
d.rectangle([0, HORIZON, S, S], fill=rgb(CRUST))
for y in range(HORIZON, S):  # faint ground gradient
    t = (y - HORIZON) / (S - HORIZON)
    d.line([(0, y), (S, y)], fill=lerp(rgb("#15121d"), rgb(CRUST), t))

road_bottom_w = S * 0.46
road = [(VX - road_bottom_w, S), (VX + road_bottom_w, S), (VX + 14, VY), (VX - 14, VY)]
d.polygon(road, fill=rgb(BASE))
# asphalt grain
grain = Image.effect_noise((S, S), 18).convert("L")
mask = Image.new("L", (S, S), 0)
ImageDraw.Draw(mask).polygon(road, fill=40)
img = Image.composite(Image.merge("RGB", (grain,) * 3), img, mask)
d = ImageDraw.Draw(img)
# edge lines
for side in (-1, 1):
    d.line([(VX + side * road_bottom_w * 0.92, S), (VX + side * 11, VY + 4)],
           fill=rgb("#45475a"), width=8)

# ── center dashes: perspective-compressed, yellow -> peach toward the sun ──
n = 9
for k in range(n):
    t0, t1 = k / n, (k + 0.55) / n
    def yp(t):  # perspective: compress toward horizon
        return S - (S - VY - 8) * (t ** 0.62)
    def wp(t):
        return max(5, 30 * (1 - t) ** 1.25)
    y0, y1 = yp(t0), yp(t1)
    w0, w1 = wp(t0), wp(t1)
    col = lerp(rgb(YELLOW), rgb(PEACH), t0)
    d.polygon([(VX - w0, y0), (VX + w0, y0), (VX + w1, y1), (VX - w1, y1)], fill=col)

# grain overall
noise = Image.effect_noise((S, S), 10).convert("L")
img = Image.composite(img, Image.merge("RGB", (noise,) * 3), Image.new("L", (S, S), 250))
d = ImageDraw.Draw(img)

# ── six-theme ring ─────────────────────────────────────────────────────────
seg = 360 / len(RING)
for k, col in enumerate(RING):
    d.arc([26, 26, S - 26, S - 26], start=k * seg - 90 + 3, end=(k + 1) * seg - 90 - 3,
          fill=rgb(col), width=16)

img.save(f"{OUT}/avatar-road-v2.png")

# circular preview
prev = Image.new("RGB", (620, 660), rgb(BASE))
m = Image.new("L", (560, 560), 0)
ImageDraw.Draw(m).ellipse([0, 0, 560, 560], fill=255)
prev.paste(img.resize((560, 560)), (30, 30), m)
fl = ImageFont.truetype("/usr/share/fonts/TTF/JetBrainsMonoNerdFont-Bold.ttf", 30)
ImageDraw.Draw(prev).text((310, 625), "The Road v2", font=fl, fill=rgb(TEXT), anchor="mm")
prev.save(f"{OUT}/avatar-road-v2-preview.png")
print("done")
