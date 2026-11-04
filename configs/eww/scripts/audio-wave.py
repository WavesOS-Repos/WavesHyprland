#!/usr/bin/env python3

import subprocess
import time
import os
import math

CONFIG = os.path.expanduser("~/.config/cava/eww-cava.conf")
OUTPUT = "/tmp/eww-waveform"
WIDTH = 1920

# Original waveform drawing dimensions
HEIGHT = 100
CENTER = HEIGHT / 2
AMPLITUDE = 90

# Expanded transparent canvas
CANVAS_HEIGHT = 300
TOP_EXPANSION = 200

os.makedirs(OUTPUT, exist_ok=True)

process = subprocess.Popen(
    ["cava", "-p", CONFIG],
    stdout=subprocess.PIPE,
    text=True,
    bufsize=1
)

for line in process.stdout:
    try:
        values = [float(v) for v in line.strip().split(";") if v.strip()]
        if len(values) < 2:
            continue

        points = []
        for i, value in enumerate(values):
            x = i * WIDTH / (len(values) - 1)
            y = CENTER - min(value * 2.5, 100) / 100 * AMPLITUDE
            points.append((x, y))

        path = f"M {points[0][0]:.2f} {points[0][1]:.2f}"

        for i in range(1, len(points)):
            x1, y1 = points[i - 1]
            x2, y2 = points[i]
            mx = (x1 + x2) / 2
            my = (y1 + y2) / 2
            path += f" Q {x1:.2f} {y1:.2f} {mx:.2f} {my:.2f}"

        path += f" T {points[-1][0]:.2f} {points[-1][1]:.2f}"

        filename = f"{OUTPUT}/wave-{time.time_ns()}.svg"

        svg = f'''<svg xmlns="http://www.w3.org/2000/svg"
    	    width="{WIDTH}" height="{CANVAS_HEIGHT}"
    	    viewBox="0 {-TOP_EXPANSION} {WIDTH} {CANVAS_HEIGHT}">
    	    <path d="{path}" fill="none" stroke="#ffffff"
    	    stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
    	   </svg>'''

        with open(filename, "w") as f:
            f.write(svg)

        print(filename, flush=True)

        # Keep only recent frames.
        files = sorted(os.listdir(OUTPUT))
        for old in files[:-3]:
            os.remove(os.path.join(OUTPUT, old))

    except (ValueError, OSError):
        continue
