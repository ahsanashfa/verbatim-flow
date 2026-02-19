#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RES_DIR="$ROOT_DIR/apps/mac-client/Resources"
MASTER_PNG="$RES_DIR/AppIcon-master.png"
ICNS_FILE="$RES_DIR/AppIcon.icns"

mkdir -p "$RES_DIR"

python3 - "$MASTER_PNG" <<'PY'
import math
import sys
from PIL import Image, ImageDraw, ImageFilter

output_path = sys.argv[1]
size = 1024
corner = 220

image = Image.new("RGBA", (size, size), (0, 0, 0, 0))
draw = ImageDraw.Draw(image)

# Diagonal gradient background.
for y in range(size):
    for x in range(size):
        t = (x + y) / (2 * size)
        r = int(20 + 30 * t)
        g = int(50 + 120 * t)
        b = int(85 + 130 * t)
        image.putpixel((x, y), (r, g, b, 255))

mask = Image.new("L", (size, size), 0)
mask_draw = ImageDraw.Draw(mask)
mask_draw.rounded_rectangle((0, 0, size - 1, size - 1), radius=corner, fill=255)
image.putalpha(mask)

overlay = Image.new("RGBA", (size, size), (0, 0, 0, 0))
overlay_draw = ImageDraw.Draw(overlay)
overlay_draw.ellipse((140, 120, 860, 840), fill=(120, 230, 255, 52))
overlay_draw.ellipse((240, 180, 980, 920), fill=(60, 140, 255, 48))
overlay = overlay.filter(ImageFilter.GaussianBlur(50))
image = Image.alpha_composite(image, overlay)

glyph = Image.new("RGBA", (size, size), (0, 0, 0, 0))
g = ImageDraw.Draw(glyph)

# Soft ring.
g.ellipse((180, 180, 844, 844), outline=(214, 248, 255, 116), width=26)

# Wave bars.
bars = [220, 320, 460, 360, 250]
bar_w = 70
gap = 32
left = (size - (bar_w * len(bars) + gap * (len(bars) - 1))) // 2
baseline = 660

for idx, height in enumerate(bars):
    x0 = left + idx * (bar_w + gap)
    x1 = x0 + bar_w
    y0 = baseline - height
    y1 = baseline
    g.rounded_rectangle((x0, y0, x1, y1), radius=34, fill=(245, 252, 255, 246))
    g.rounded_rectangle((x0 + 6, y0 + 10, x1 - 6, y1 - 14), radius=28, fill=(140, 242, 255, 188))

# Accent spark.
g.ellipse((724, 290, 794, 360), fill=(255, 255, 255, 250))
g.polygon([(758, 238), (781, 290), (735, 290)], fill=(255, 255, 255, 224))

glyph = glyph.filter(ImageFilter.GaussianBlur(0.6))
image = Image.alpha_composite(image, glyph)

shadow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
s = ImageDraw.Draw(shadow)
s.rounded_rectangle((34, 34, size - 34, size - 34), radius=corner, outline=(255, 255, 255, 50), width=2)
shadow = shadow.filter(ImageFilter.GaussianBlur(0.8))
image = Image.alpha_composite(image, shadow)

image.save(output_path, "PNG")
print(output_path)
PY

ICONSET_DIR="$(mktemp -d "$RES_DIR/.AppIcon.XXXXXX.iconset")"

sips -z 16 16 "$MASTER_PNG" --out "$ICONSET_DIR/icon_16x16.png" >/dev/null
sips -z 32 32 "$MASTER_PNG" --out "$ICONSET_DIR/icon_16x16@2x.png" >/dev/null
sips -z 32 32 "$MASTER_PNG" --out "$ICONSET_DIR/icon_32x32.png" >/dev/null
sips -z 64 64 "$MASTER_PNG" --out "$ICONSET_DIR/icon_32x32@2x.png" >/dev/null
sips -z 128 128 "$MASTER_PNG" --out "$ICONSET_DIR/icon_128x128.png" >/dev/null
sips -z 256 256 "$MASTER_PNG" --out "$ICONSET_DIR/icon_128x128@2x.png" >/dev/null
sips -z 256 256 "$MASTER_PNG" --out "$ICONSET_DIR/icon_256x256.png" >/dev/null
sips -z 512 512 "$MASTER_PNG" --out "$ICONSET_DIR/icon_256x256@2x.png" >/dev/null
sips -z 512 512 "$MASTER_PNG" --out "$ICONSET_DIR/icon_512x512.png" >/dev/null
sips -z 1024 1024 "$MASTER_PNG" --out "$ICONSET_DIR/icon_512x512@2x.png" >/dev/null

iconutil -c icns "$ICONSET_DIR" -o "$ICNS_FILE"
rm -rf "$ICONSET_DIR"
echo "[ok] generated icon: $ICNS_FILE"
