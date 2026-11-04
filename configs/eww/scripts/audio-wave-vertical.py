#!/usr/bin/env python3

import subprocess
import time
import os

CONFIG = os.path.expanduser("~/.config/cava/eww-cava.conf")
OUTPUT = "/tmp/eww-waveform-vertical"

# Same waveform proportions as the horizontal visualizer
WIDTH = 300
HEIGHT = 1080

CENTER = 50
AMPLITUDE = 90
BASELINE_X = WIDTH / 2

os.makedirs(OUTPUT, exist_ok=True)

process = subprocess.Popen(
    ["cava", "-p", CONFIG],
    stdout=subprocess.PIPE,
    text=True,
    bufsize=1
)

try:
    for line in process.stdout:
        try:
            values = [
                float(v) for v in line.strip().split(";") if v.strip()
            ]

            if len(values) < 2:
                continue

            points = []

            for i, value in enumerate(values):

                # EXACT same amplitude calculation as horizontal
                displacement = (
                    min(value * 2.5, 100) / 100 * AMPLITUDE
                )

                # Rotate the original horizontal waveform 90 degrees
                x = BASELINE_X - displacement
                y = i * HEIGHT / (len(values) - 1)

                points.append((x, y))

            # EXACT same quadratic smoothing as horizontal
            path = f"M {points[0][0]:.2f} {points[0][1]:.2f}"

            for i in range(1, len(points)):
                x1, y1 = points[i - 1]
                x2, y2 = points[i]

                mx = (x1 + x2) / 2
                my = (y1 + y2) / 2

                path += (
                    f" Q {x1:.2f} {y1:.2f}"
                    f" {mx:.2f} {my:.2f}"
                )

            path += (
                f" T {points[-1][0]:.2f}"
                f" {points[-1][1]:.2f}"
            )

            filename = f"{OUTPUT}/wave-{time.time_ns()}.svg"

            svg = f'''<svg xmlns="http://www.w3.org/2000/svg"
                width="{WIDTH}" height="{HEIGHT}"
                viewBox="0 0 {WIDTH} {HEIGHT}">
                <path d="{path}"
                    fill="none"
                    stroke="#ffffff"
                    stroke-width="2"
                    stroke-linecap="round"
                    stroke-linejoin="round"/>
            </svg>'''

            with open(filename, "w") as f:
                f.write(svg)

            print(filename, flush=True)

            # Keep only recent frames
            files = sorted(os.listdir(OUTPUT))

            for old in files[:-3]:
                os.remove(os.path.join(OUTPUT, old))

        except (ValueError, OSError):
            continue

except KeyboardInterrupt:
    process.terminate()



