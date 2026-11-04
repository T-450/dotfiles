#!/usr/bin/env python3
"""Render an original ringed planet as sysc-greet ASCII art.

Colors are SGR codes that sysc-greet maps to the active theme (ansi_style=true):
  96 primary (lit side)   34 secondary (shadow side)   90 fg_muted (night edge / stars)
  93 warning (ring)       97 fg_primary (bright stars)
Usage: make-planet.py [--plain]   -> prints the art (escapes spelled as \\033)
"""
import math, random, sys

W, H = 60, 15          # columns, rows
R = 5.6                # planet radius in rows (x2 in columns: cells are ~1:2)
CX, CY = W / 2, H / 2 - 0.3
TILT = math.radians(15)    # ring opening angle
ROT = math.radians(-8)    # ring roll on screen
RING = (1.30, 2.05)        # ring inner/outer radius, in planet radii
GAP = (9, 9)              # Cassini-like gap
L = (-0.45, -0.35, 0.82)   # light direction (from upper left, toward viewer)
n = math.sqrt(sum(c * c for c in L)); L = tuple(c / n for c in L)

RAMP = " .:-=+*#%@"
plain = "--plain" in sys.argv
rnd = random.Random(2026)

def sgr(code, ch):
    return ch if plain or ch == " " else f"\\033[{code}m{ch}"

rows = []
for y in range(H):
    line = []
    for x in range(W):
        nx = (x + 0.5 - CX) / (2 * R)
        ny = (y + 0.5 - CY) / R
        # ring coordinates: undo roll, then undo tilt (v stretched back to a circle)
        u = nx * math.cos(ROT) + ny * math.sin(ROT)
        w = -nx * math.sin(ROT) + ny * math.cos(ROT)
        v = w / math.sin(TILT)
        rr = math.hypot(u, v)
        in_ring = RING[0] <= rr <= RING[1] and not (GAP[0] <= rr <= GAP[1])
        ring_front = v > 0
        d2 = nx * nx + ny * ny
        cell = " "
        if d2 <= 1.0 and not (in_ring and ring_front):
            nz = math.sqrt(1 - d2)
            lum = max(0.0, nx * L[0] + ny * L[1] + nz * L[2])
            ch = RAMP[min(len(RAMP) - 1, 1 + int(lum * (len(RAMP) - 1)))]
            # soft horizontal bands, like a gas giant
            if math.sin(ny * 7.0) > 0.75 and ch not in " .":
                ch = RAMP[max(1, RAMP.index(ch) - 1)]
            code = 96 if lum > 0.55 else 34 if lum > 0.18 else 90
            cell = sgr(code, ch)
        elif in_ring:
            edge = min(rr - RING[0], RING[1] - rr)
            ch = "=" if edge > 0.18 else "-"
            cell = sgr(93, ch)
        elif rnd.random() < 0.022:
            cell = sgr(97 if rnd.random() < 0.3 else 90, rnd.choice("..·*+"))
        line.append(cell)
    rows.append("".join(line).rstrip())
while rows and not rows[0].strip(): rows.pop(0)
while rows and not rows[-1].strip(): rows.pop()
print("\n".join(rows))
