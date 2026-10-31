# BioBike — Magnetic Field Mapping of Pedelec Drive Magnets

Measurement data and MATLAB scripts accompanying the article

> S. Feldmann, M. Lanz, M. Wiedenmann:
> **Non-Destructive Quality Assessment of Permanent Magnets in Pedelec Drive
> Systems via Magnetic Field Mapping and Support Vector Machine Classification.**
> Aalen University, 2026 (submitted). DOI: _to be added after acceptance_

The 14 NdFeB permanent magnets from the rotor of a **daum electronic Impulse2**
pedelec centre-drive (PMSM) were scanned with a three-axis Hall field mapper
twice. The first scan was after **5,000 km of endurance testing** on the
biomechanical Hardware-in-the-Loop e-bike test bench at Aalen University
(*degraded* state). The second was after **pulse re-magnetisation** (*fully
magnetised* reference state). The paired difference field maps show localised
demagnetisation of 0.3–7.6 mT, mainly at the magnet edges.

---

## Repository contents

All files are in the repository root. The scripts expect the data files in the
MATLAB working directory.

| File(s) | Content | Paper |
|---|---|---|
| `Feldmann_aufmagnetisiert_1.txt` … `_14.txt` | Area scans of magnets M1–M14, **fully magnetised** (reference) state | Sect. 2.3, 3 |
| `Feldmann2_1.txt` … `Feldmann2_14.txt` | Area scans of magnets M1–M14, **degraded** state after 5,000 km | Sect. 2.3, 3 |
| `Rotor_slice.txt` | Full 360° scan of the assembled rotor, 13 axial slices | Rotor figures |
| `Rotor_slice_2.txt` | Repeat of the 13-slice rotor scan (same set-up, 14 min later) | – |
| `Rotor.txt` | Single-slice 360° rotor scan (preliminary) | – |
| `convert_helmholtz_to_images_pub_v001_260511.m` | Converts the magnet scans into field-map images (step 1) | Field-map figures |
| `helmholtz_diff_analysis_v001_260511_pub.m` | Difference fields ΔB = B_magnetised − B_degraded, histograms, degradation ranking (step 2) | Degradation figures |
| `Plot_Rotor_Publ_Lanz_v002_250302.m` | Rotor surface field maps from `Rotor_slice.txt` | Rotor figures |
| `LICENSE` | CC0 1.0 (data) | |
| `LICENSE-CODE` | MIT (scripts) | |
| `DISCLAIMER.md` | Terms of use | |

Files with the same index form a pair: `Feldmann_aufmagnetisiert_n.txt` ↔
`Feldmann2_n.txt` is magnet M*n* before/after re-magnetisation.

---

## Measurement set-up (paper, Table 1)

| Parameter | Value |
|---|---|
| Gaussmeter | SENIS MMS-1A-RS, three-axis Hall field mapper |
| Hall probe | SENIS AG #382-18, measurement range 1500 mT |
| Magnet scans | Transition mode (area scan), 24 mm × 14 mm per magnet, 250 µm resolution, 8 mm/s |
| Rotor scans | Diameter mode, 0.1° angular resolution, 360°, 13 axial slices (1 mm pitch), radius 20.95 mm, 15 °/s |
| Coordinate system | FSV tool (magnets), rotary table (rotor) |
| Filter | ON, 1500 mT |
| Magnets | 14 × NdFeB, approx. 24 × 14 × 3 mm, > 300 mT peak surface flux density |
| Re-magnetisation | Pulse magnetiser M-K-O1020A, Magnet-Physik, Cologne |
| Endurance test | 5,000 km, five-stage load collective, 500 W (pedal + motor), 50–100 rpm |
| Measurement dates | Rotor: 27 Jan 2021 · degraded magnets: 25 Feb 2021 · re-magnetised magnets: 26 Feb 2021 |

---

## File format

All `.txt` files are raw exports of the SENIS MMS software:

* A text header between two lines of `****` holds the scan settings, probe
  offsets, start position and calibration date. Then come one line of column
  names and one blank units line.
* Data: tab-separated, fixed width, point as decimal separator.
* Encoding: ISO-8859-1 (Windows-1252), Windows line endings (CRLF).

| # | Column | Unit | Description |
|---|---|---|---|
| 1 | Slice | – | Slice index (rotor scans: 1…13) |
| 2 | Line | – | Scan line index |
| 3 | X | mm | Probe X position |
| 4 | Y | mm | Probe Y position |
| 5 | Z | mm | Probe Z position |
| 6 | Rotation | deg | Rotary table angle |
| 7–9 | Bx, By, Bz | mT | Flux density components |
| 10 | Rot. Enc | steps | Rotary encoder |
| 11 | Bxy | mT | √(Bx² + By²) |
| 12 | Btot | mT | √(Bx² + By² + Bz²), the total flux density used in the paper |
| 13 | Angle error | deg | Encoder angle deviation |
| 14 | Direction | – | Scan direction |
| 15 … | R, Z, Theta, probe temperature | mm, mm, deg, °C | Additional columns (rotor scans) |

The magnet analysis uses columns 3 (X), 4 (Y) and 12 (Btot).

---

## Reproducing the figures

Requires **MATLAB R2021a or newer** with the **Image Processing Toolbox**.

```matlab
cd <path-to>/BioBike                 % repository root = working directory

convert_helmholtz_to_images_pub_v001_260511   % 1) field-map images  -> images_*/ , overview_*.png
helmholtz_diff_analysis_v001_260511_pub       % 2) difference analysis -> diff_analysis/
Plot_Rotor_Publ_Lanz_v002_250302              % 3) rotor figures      -> Fig_Rotor_*.png
```

Step 1 must run before step 2, because the difference analysis also reads the
images written by step 1. Figures are exported as 300 dpi PNG files. The
journal styling uses Times New Roman; if that font is missing, MATLAB uses a
fallback and label widths change.

The feature extraction (25 statistical, gradient and GLCM texture features) and
the classifier comparison (SVM linear/RBF, decision tree, k-NN, bagged trees,
leave-one-out cross-validation) in Sects. 4–6 of the paper are not part of this
repository.

---

## Notes on the data

* `Feldmann_aufmagnetisiert_1.txt` (M1, re-magnetised) contains only 2,231
  data rows, compared with 5,529 for all other magnet scans. The scan of this
  magnet covers only part of the 24 × 14 mm area.
* Zero rows (outside the magnet) are treated as background by the scripts.

---

## License

* **Data** (`*.txt`): [CC0 1.0 Universal](LICENSE), public domain dedication.
* **Scripts** (`*.m`): [MIT License](LICENSE-CODE).

Citing the article is appreciated (see [`CITATION.cff`](CITATION.cff)). See also
[`DISCLAIMER.md`](DISCLAIMER.md).

## Related work

S. Feldmann, M. Wiedenmann: *Biomechanical hardware-in-the-loop control concept
for pedelec drivetrain testing.* Computer Science & Information Technology
(CSIT), 15, 2025. http://aircconline.com/csit/papers/vol15/csit152506.pdf

## Acknowledgement

This work was carried out within the MagTwin sub-project of the SmartPro
research alliance and the DiMa project at Aalen University, in cooperation
with daum electronic GmbH, Fürth.

## Contact

Prof. Dr.-Ing. Sebastian Feldmann, Aalen University, Germany —
Sebastian.Feldmann@HS-Aalen.de
