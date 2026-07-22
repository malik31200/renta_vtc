# Handoff: Renta VTC Logo

## Overview
A logo (icon + wordmark) for "Renta VTC", a dark-themed mobile app that helps VTC (ride-hailing) drivers calculate their net earnings per ride. Selected concept: **"Volant" (steering wheel)**, referenced as option **1b** in the attached design file.

## About the Design Files
The bundled `.dc.html` file is a **design reference built in HTML** — it shows the intended look of the logo, not production code to copy directly. Recreate it as real logo assets (SVG/PNG at required sizes, app icon, favicon) in whatever tool/pipeline the team uses for brand assets, matching the shapes and colors described below pixel-for-pixel.

## Fidelity
**High-fidelity.** Colors, proportions, and layout are final for the selected option (1b). The file also contains other explored concepts (monogram, route pin, car) that were NOT selected — ignore those, they're kept only as design history.

## Selected Logo — "Volant" (1b)

### Icon
- Container: rounded square, 16px corner radius, background `#1c1d20` (dark neutral), size 60×60 in the mock (scales freely as a square aspect ratio).
- Inner ring: circle, 38px diameter (at 60px container size — ~63% of container), stroke width 4px, color `#F2A33D` (orange accent), no fill.
- Hub: small solid circle centered in the ring, 12px diameter, background `#1c1d20` with a 3px `#F2A33D` stroke.
- Spokes: 3 straight bars, 3px wide × 44px long, color `#F2A33D`, all centered on the ring's center, rotated at 0°, 60°, and 120° (three bars crossing through center produce 6 visible spoke ends — the classic steering-wheel spoke pattern). Bars are clipped by the ring stroke/circle at the edges.

### App icon / favicon variant
Same construction at smaller scale (44px container, 28px ring, 8px hub) — used for small square placements (favicon, app icon, avatar).

### Wordmark
- Typeface: Helvetica/Arial Bold (system sans), weight 800.
- Text: "Renta" in white (`#ffffff`), space, "VTC" in orange (`#F2A33D`), both bold, same size.
- Size: 26px, letter-spacing -0.3px, single line, no wrap.
- Lockup: icon and wordmark side by side, 14px gap, vertically centered.

## Design Tokens
- **Background (dark, app-native context):** `#0b0b0c`–`#131315` range (matches app screenshot dark theme).
- **Icon container background:** `#1c1d20`.
- **Accent / brand orange:** `#F2A33D`.
- **Wordmark white:** `#ffffff`.
- **Font:** Helvetica, Arial, sans-serif — weight 800 for wordmark and icon letterforms.
- **Corner radius:** 16px (large icon container), 12px (small/app-icon container) — consistent ~27% of container size.

## Assets
No external image assets — the icon is built entirely from basic CSS shapes (circle, bars, ring), no photography or complex SVG artwork involved.

## Files
- `Logo Renta VTC.dc.html` — full design file. Option **1b** (id `#1b` in the file) is the selected/final logo. Other ids (1a, 1c, 1d, 2a, 2b, 2c) are earlier explorations kept for reference only.
