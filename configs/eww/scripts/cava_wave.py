#!/usr/bin/env python3
import subprocess
import sys
import os

# ====== CONFIG ======
BARS = 80                  # more bars = smoother wave
HEIGHT = 90                # height of the visualizer in px
WIDTH = 1920               # change to your screen width
LINE_COLOR = "#ffffff"     # white (or use wallust color)
LINE_WIDTH = 2.2
FILL = False               # set True if you want the area under the wave filled
OUTPUT = "/tmp/cava_wave.svg"
FPS = 50
# ====================

def generate_svg(values):
    n = len(values)
    if n < 2:
        return

    step = WIDTH / (n - 1)
    points = []

    for i, v in enumerate(values):
        x = i * step
        y = HEIGHT - (v / 100.0) * (HEIGHT - 8)   # 8px padding from top
        points.append((x, y))

    # Build smooth cubic Bezier path (Catmull-Rom style)
    path = f"M {points[0][0]:.1f},{points[0][1]:.1f}"

    for i in range(len(points) - 1):
        p0 = points[max(i - 1, 0)]
        p1 = points[i]
        p2 = points[i + 1]
        p3 = points[min(i + 2, len(points) - 1)]

        # Control points
        cp1x = p1[0] + (p2[0] - p0[0]) / 6
        cp1y = p1[1] + (p2[1] - p0[1]) / 6
        cp2x = p2[0] - (p3[0] - p1[0]) / 6
        cp2y = p2[1] - (p3[1] - p1[1]) / 6

        path += f" C {cp1x:.1f},{cp1y:.1f} {cp2x:.1f},{cp2y:.1f} {p2[0]:.1f},{p2[1]:.1f}"

    fill_attr = f'fill="{LINE_COLOR}" fill-opacity="0.15"' if FILL else 'fill="none"'
    
    svg = f'''<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="{WIDTH}" height="{HEIGHT}" viewBox="0 0 {WIDTH} {HEIGHT}">
  <path d="{path}" stroke="{LINE_COLOR}" stroke-width="{LINE_WIDTH}" 
        stroke-linecap="round" stroke-linejoin="round" {fill_attr}/>
</svg>'''

    with open(OUTPUT, "w") as f:
        f.write(svg)

def main():
    # Minimal cava config (raw ascii, high resolution)
    config = f"""
[general]
framerate = {FPS}
bars = {BARS}
sleep_timer = 3

[output]
method = raw
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = 100
"""

    # Start cava
    proc = subprocess.Popen(
        ["cava", "-p", "/dev/stdin"],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        text=True,
        bufsize=1
    )
    proc.stdin.write(config)
    proc.stdin.close()

    print(f"Writing smooth wave to {OUTPUT}", file=sys.stderr)

    try:
        for line in proc.stdout:
            line = line.strip()
            if not line:
                continue
            # CAVA outputs: 12;45;67;...;
            values = [int(x) for x in line.split(";") if x.strip().isdigit()]
            if len(values) >= 2:
                generate_svg(values)
    except KeyboardInterrupt:
        pass
    finally:
        proc.terminate()

if __name__ == "__main__":
    main()
