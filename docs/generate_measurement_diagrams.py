"""Draw the measurement path and calibration schematics (requires Pillow)."""

from functools import lru_cache
from math import atan2, cos, sin
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ASSETS = Path(__file__).resolve().parent / "assets"
WIDTH = 1240
INK = "#132e3b"
MUTED = "#3b5966"
BLUE = "#076b85"
ORANGE = "#a54620"
LINE = "#c5dadd"
PANEL = "#ffffff"
SLAB = "#d5e8e1"


@lru_cache
def font(size, bold=False):
    filename = "Arial Bold.ttf" if bold else "Arial.ttf"
    try:
        return ImageFont.truetype(f"/System/Library/Fonts/Supplemental/{filename}", size)
    except OSError:
        filename = "DejaVuSans-Bold.ttf" if bold else "DejaVuSans.ttf"
        return ImageFont.truetype(filename, size)


def label(draw, xy, text, size=24, *, bold=False, color=INK, anchor=None):
    draw.multiline_text(xy, text, font=font(size, bold), fill=color, anchor=anchor, spacing=10)


def canvas(title, subtitle, row_height):
    height = 144 + 3 * row_height + 2 * 16 + 28
    image = Image.new("RGB", (WIDTH, height), "#f0f6f6")
    draw = ImageDraw.Draw(image)
    label(draw, (40, 28), title, 39, bold=True)
    label(draw, (42, 84), subtitle, 24, color=MUTED)
    return image, draw


def card(draw, top, height, title, description):
    draw.rounded_rectangle((34, top, WIDTH - 34, top + height), 20, fill=PANEL, outline=LINE, width=2)
    draw.line((700, top + 22, 700, top + height - 22), fill=LINE, width=2)
    label(draw, (732, top + 33), title, 30, bold=True)
    label(draw, (734, top + 85), description, 24, color=MUTED)


def horn(draw, x, y, direction, text, tilt=0):
    body = [(x + direction * u * cos(tilt) - v * sin(tilt), y + u * sin(tilt) + v * cos(tilt))
            for u, v in [(-66, -14), (-43, -14), (0, -30), (0, 30), (-43, 14), (-66, 14)]]
    draw.polygon(body, fill="#d8e8ed", outline=INK, width=3)
    label(draw, (x - 22 * direction, y + 45), text, 22, bold=True, anchor="mt")


def arrow(draw, start, end, color):
    draw.line((start, end), fill=color, width=5)
    angle = atan2(end[1] - start[1], end[0] - start[0])
    back = [(end[0] - 16 * cos(angle + sign * .50), end[1] - 16 * sin(angle + sign * .50))
            for sign in (-1, 1)]
    draw.polygon([end, *back], fill=color)


def plane(draw, x, top, bottom):
    for y in range(top, bottom, 14):
        draw.line((x, y, x, min(y + 8, bottom)), fill="#6a8a94", width=2)


def slab(draw, x, y):
    draw.rounded_rectangle((x - 12, y - 64, x + 12, y + 64), 4, fill=SLAB, outline=INK, width=2)
    for face in (x - 16, x + 16):
        plane(draw, face, y - 70, y + 72)
    label(draw, (x, y - 82), "Sample faces", 23, color=MUTED, anchor="ms")


def measurement_paths():
    height = 244
    image, draw = canvas("Three free-space measurement paths",
                         "Blue shows the incident wave. Orange shows the received wave.", height)
    top = 130
    y = top + 126
    card(draw, top, height, "Straight-through transmission",
         "Separate Tx and Rx face one another.\nThe slab is between them. The calibrated\nthrough channel supplies t.")
    slab(draw, 370, y)
    horn(draw, 145, y, 1, "Tx")
    horn(draw, 602, y, -1, "Rx")
    arrow(draw, (152, y), (348, y), BLUE)
    arrow(draw, (390, y), (594, y), ORANGE)

    top += height + 16
    y = top + 116
    card(draw, top, height, "Bistatic specular reflection",
         "Separate horns sit on the same side.\nRx follows the mirror direction. A VNA\ncan record this return as raw port S21.")
    slab(draw, 575, y)
    tilt = atan2(57, 551 - 257)
    horn(draw, 249, y - 57, 1, "Tx", tilt)
    horn(draw, 249, y + 57, 1, "Rx", -tilt)
    arrow(draw, (257, y - 57), (551, y), BLUE)
    arrow(draw, (551, y + 3), (257, y + 57), ORANGE)
    draw.line((450, y, 552, y), fill="#6a8a94", width=2)
    draw.line((594, y, 610, y), fill="#6a8a94", width=2)
    label(draw, (616, y), "Normal", 20, color=MUTED, anchor="lm")

    top += height + 16
    y = top + 126
    card(draw, top, height, "Monostatic reflection",
         "The same aperture sends and receives.\nShown at normal incidence for context.\nThe app models separate Tx / Rx paths.")
    slab(draw, 575, y)
    horn(draw, 249, y, 1, "Tx / Rx")
    arrow(draw, (257, y - 12), (551, y - 12), BLUE)
    arrow(draw, (551, y + 12), (257, y + 12), ORANGE)
    image.save(ASSETS / "measurement-paths.png", optimize=True)


def trl_standards():
    height = 206
    image, draw = canvas("Free-space TRL calibration standards",
                         "Conceptual air-path standards. Choose the actual standards for your fixture and band.", height)
    top = 130
    y = top + 105
    card(draw, top, height, "Thru",
         "An empty path between the horns\ndefines the thru reference.\nRemove the specimen for this step.")
    horn(draw, 155, y, 1, "Port 1")
    horn(draw, 575, y, -1, "Port 2")
    plane(draw, 365, y - 53, y + 53)
    arrow(draw, (164, y), (566, y), BLUE)

    top += height + 16
    y = top + 105
    card(draw, top, height, "Reflect",
         "A highly reflecting standard is\npresented to each port. The original\nstudy used a metal plate.")
    horn(draw, 155, y, 1, "Port 1")
    horn(draw, 575, y, -1, "Port 2")
    draw.rounded_rectangle((353, y - 59, 377, y + 59), 3, fill="#a9bdc5", outline=INK, width=2)
    label(draw, (365, y - 67), "Metal reference", 21, color=MUTED, anchor="ms")
    arrow(draw, (167, y - 12), (344, y - 12), BLUE)
    arrow(draw, (344, y + 12), (167, y + 12), ORANGE)
    arrow(draw, (563, y - 12), (386, y - 12), BLUE)
    arrow(draw, (386, y + 12), (563, y + 12), ORANGE)

    top += height + 16
    y = top + 105
    card(draw, top, height, "Line",
         "Another uniform thru path provides\na different electrical length.\nThe extra air path changes the phase.")
    horn(draw, 125, y, 1, "Port 1")
    horn(draw, 605, y, -1, "Port 2")
    plane(draw, 155, y - 43, y + 43)
    plane(draw, 575, y - 43, y + 43)
    label(draw, (365, y - 20), "Additional air path", 23, color=MUTED, anchor="ms")
    arrow(draw, (135, y), (595, y), BLUE)
    image.save(ASSETS / "trl-standards.png", optimize=True)


if __name__ == "__main__":
    measurement_paths()
    trl_standards()
