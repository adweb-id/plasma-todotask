"""Puts a rendered popup on the Plasma popup background it is shown on.

The widget draws no background of its own (Plasma's dialog does), so the
render is laid over the colour scheme's window colour, with rounded corners
and a thin border like a Plasma popup. An open context menu, rendered on its
own, is laid over at the position the driver logged.

    python3 frame.py <shot.png> <scheme.colors> <log>
"""
import configparser
import re
import sys

from PIL import Image, ImageDraw

shot, scheme, log = sys.argv[1:4]

colors = configparser.ConfigParser(interpolation=None)
colors.read(scheme)
bg = tuple(int(v) for v in colors["Colors:Window"]["BackgroundNormal"].split(","))
fg = tuple(int(v) for v in colors["Colors:Window"]["ForegroundNormal"].split(","))

# Plasma's dialog adds this margin around a popup's content
pad = 6
popup = Image.open(shot).convert("RGBA")
w, h = popup.size[0] + 2 * pad, popup.size[1] + 2 * pad
base = Image.new("RGBA", (w, h), bg + (255,))
base.alpha_composite(popup, dest=(pad, pad))

menu_at = None
with open(log, errors="replace") as f:
    for line in f:
        m = re.search(r"MENU_AT (-?\d+) (-?\d+)", line)
        if m:
            menu_at = (int(m.group(1)), int(m.group(2)))
if menu_at:
    menu = Image.open(shot.replace(".png", ".menu.png")).convert("RGBA")
    base.alpha_composite(menu, dest=(menu_at[0] + pad, menu_at[1] + pad))

# Rounded corners and a 1 px border, transparent outside
radius = 10
mask = Image.new("L", (w, h), 0)
ImageDraw.Draw(mask).rounded_rectangle((0, 0, w - 1, h - 1), radius=radius, fill=255)
out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
out.paste(base, (0, 0), mask)
ImageDraw.Draw(out).rounded_rectangle((0, 0, w - 1, h - 1), radius=radius,
                                      outline=fg + (60,), width=1)
out.save(shot)
