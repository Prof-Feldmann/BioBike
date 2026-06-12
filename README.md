# Rotor Magnet Hysteresis Dataset

Helmholtz-scanner measurements of permanent magnets from an e-bike motor rotor, captured before and after in-service operation. This repository contains the raw measurement data and the MATLAB scripts used to generate the figures published in the accompanying paper.

> **Citation placeholder.** If you use this dataset, please cite:
> _Feldmann et al. (year). Title. Journal, Vol(Issue), Pages. DOI:_ `<add DOI here>`

---

## Repository structure

```
.
├── data/
│   ├── Rotor_slice.txt                       # full 360° rotor scan (13 axial slices)
│   ├── Feldmann_aufmagnetisiert_1.txt        # pulsed (re-magnetised) magnet 1
│   ├── ...
│   ├── Feldmann_aufmagnetisiert_14.txt       # pulsed (re-magnetised) magnet 14
│   ├── Feldmann2_1.txt                       # used (in-service) magnet 1
│   ├── ...
│   └── Feldmann2_14.txt                      # used (in-service) magnet 14
├── scripts/
│   ├── Plot_Rotor_Publ_Lanz_002_250302_pub.m # rotor surface visualisation
│   ├── helmholtz_diff_analysis_pub.m         # pulsed–used difference analysis
│   └── convert_helmholtz_to_images_pub.m     # txt → PNG conversion + overviews
└── README.md
```

The `scripts/` folder produces all figures used in the publication directly from the contents of `data/`. No additional input files are required.

---

## Measurement set-up

| Item | Specification |
|---|---|
| Sensor system | SENIS MMS-1A-RS three-axis Hall scanner |
| Mode | Diameter (Helmholtz) mode |
| Test rig | daum electronic Impulse2 ergometer rotor |
| Angular resolution | 0.1° (3601 samples per full revolution) |
| Axial slices (rotor scan) | 13 |
| Number of magnets per rotor | 14 |
| Field unit | mT |
| Position unit | mm |
| Temperature recorded | yes (probe temperature, last column) |

The rotor consists of 14 surface-mounted permanent magnets distributed evenly around the circumference (one magnet every 360 / 14 ≈ 25.71°).

---

## Dataset description

### 1. `Rotor_slice.txt` — full rotor scan

Single tab-separated file containing a 360° scan of the assembled rotor, repeated for 13 axial positions Z. Header lines are bracketed by `***` blocks; numeric data starts after the second `***` block.

Columns (1-based, tab-separated):

| # | Name | Unit | Description |
|---|---|---|---|
| 1  | Slice         | –     | Slice index (1…13)                         |
| 2  | Line          | –     | Sample index within slice                  |
| 3  | X             | mm    | Sensor X position                          |
| 4  | Y             | mm    | Sensor Y position                          |
| 5  | Z             | mm    | Sensor Z position (axial)                  |
| 6  | Rotation      | deg   | Rotor rotation angle (0…360°)              |
| 7  | Bx            | mT    | Magnetic flux density, X component         |
| 8  | By            | mT    | Magnetic flux density, Y component         |
| 9  | Bz            | mT    | Magnetic flux density, Z component         |
| 10 | RotEnc        | deg   | Rotary encoder reading                     |
| 11 | Bxy           | mT    | √(Bx² + By²)                               |
| 12 | Btot          | mT    | √(Bx² + By² + Bz²) — total flux density    |
| 13 | AngleError    | deg   | Mechanical–encoder angle deviation         |
| 14 | Direction     | –     | Scan direction flag                        |
| 15 | R             | mm    | Radial position                            |
| 16 | Z             | mm    | Axial position (post-processed)            |
| 17 | Theta         | deg   | Polar angle                                |
| 18 | ProbeTemp     | °C    | Hall probe temperature                     |

### 2. `Feldmann_aufmagnetisiert_*.txt` — pulsed magnets (reference state)

Individual scans of each of the 14 magnets **immediately after pulse re-magnetisation**, i.e. the reference / as-new state. File index `*` ranges from 1 to 14 and matches the magnet position used in `Rotor_slice.txt`.

Same column layout as `Rotor_slice.txt`. The scripts in this repository use only columns **3 (X)**, **4 (Y)** and **12 (Btot)**.

### 3. `Feldmann2_*.txt` — used magnets (in-service state)

Scans of the same 14 magnets **after in-service operation** on the test rig. File index `*` from 1 to 14, magnet position identical to the pulsed dataset, so files with the same index form a paired comparison.

Identical column layout.

The pair `(Feldmann_aufmagnetisiert_n.txt, Feldmann2_n.txt)` is the basis for the per-magnet degradation analysis.

---

## MATLAB scripts

All three scripts share a common `PUB` style struct at the top defining fonts, sizes and line widths. Change values there to retune appearance globally; everything downstream picks the new values up.

### `Plot_Rotor_Publ_Lanz_002_250302_pub.m`

Reads `Rotor_slice.txt` and produces three publication figures:

| Output PNG | Content |
|---|---|
| `Fig_Rotor_FieldMap_Unwrapped.png` | Unwrapped rotor surface heat-map (θ, Z, B_tot) plus a representative circumferential profile |
| `Fig_Rotor_PolarView.png`          | Polar cross-section view, radial axis encodes axial slice |
| `Fig_Rotor_Combined.png`           | Combined publication figure with panels (a)–(c) and all 14 magnet labels |

Also prints per-magnet mean B_tot for the mid-slice to the console.

### `helmholtz_diff_analysis_pub.m`

Computes the pairwise difference field ΔB_tot = B_pulsed − B_used for each of the 14 magnets and produces:

| Output PNG | Content |
|---|---|
| `diff_images_all.png`         | 2 × 7 grid of difference fields with shared colour scale |
| `diff_rgb_all.png`            | RGB difference of the raw colour-map images |
| `histograms_per_magnet.png`   | Per-magnet ΔB_tot probability histograms |
| `histogram_overlay_all.png`   | All 14 distributions overlaid in one panel |
| `degradation_ranking.png`     | Bar chart of |⟨ΔB_tot⟩| ranked worst → best |

Results are written to `./diff_analysis/`. A summary table is printed to the console.

### `convert_helmholtz_to_images_pub.m`

Utility step: reads each per-magnet `*.txt` file and converts it to PNG.

| Output folder | Content |
|---|---|
| `images_pulsed_axes/` | Per-magnet pulsed PNG with axes, colorbar, title |
| `images_pulsed_raw/`  | Per-magnet pulsed PNG, image only (no axes) |
| `images_used_axes/`   | Per-magnet used PNG with axes, colorbar, title |
| `images_used_raw/`    | Per-magnet used PNG, image only (no axes) |

The `*_raw/` images are the input for the RGB-difference panel in `helmholtz_diff_analysis_pub.m`, so this script should be run **before** the difference analysis.

---

## Quick start

Tested with **MATLAB R2021a or newer**. No additional toolboxes are required beyond the base product and Image Processing Toolbox (used for `imresize` and `imshow`).

```matlab
% 1) Clone the repo, then in MATLAB:
cd <path-to-repo>
addpath('scripts');
cd('data');

% 2) Generate per-magnet PNG images (do this once)
convert_helmholtz_to_images_pub

% 3) Difference analysis (pulsed vs. used)
helmholtz_diff_analysis_pub

% 4) Rotor surface figures
Plot_Rotor_Publ_Lanz_002_250302_pub
```

All figures are written as 300 DPI PNGs into the working directory (or, for the difference analysis, into a `diff_analysis/` subfolder).

---

## Reproducing the published figures

The publication figures are produced bit-for-bit by the scripts as supplied. Random seeds are not used. If you obtain different output, check:

1. The data folder is the MATLAB working directory when the script starts (the scripts use `pwd` to locate the `.txt` files).
2. Times New Roman is installed on the system, otherwise MATLAB falls back to a different font and label widths change.
3. MATLAB version ≥ R2021a — earlier versions handle `xline`, `sgtitle` and `readmatrix` differently.

---

## Data integrity

- All `.txt` files are tab-separated UTF-8 with `***` header delimiters.
- Decimal separator: **point** (`.`).
- Line endings: Unix (`\n`) — Windows users opening the files in Notepad may see them as a single line, but MATLAB reads them correctly regardless.
- No NaN or sentinel values are used; the scripts treat all-zero rows as background and exclude them from statistics.

---

## License

`<TODO: choose and add a license — typical choices for research data are CC-BY-4.0 for the data and MIT or BSD-3-Clause for the scripts. Add the corresponding LICENSE file at the repo root.>`

---

## Contact

`<TODO: name, institution, email>`

Issues and pull requests are welcome through the GitHub issue tracker.
