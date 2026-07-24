# CryoGrid_VP_Workflow

MATLAB workflow for preparing forcing data and topographic inputs for **CryoGrid mountain permafrost simulations**.

This repository contains tools developed for mountain permafrost modelling, including:

- preparation of meteorological forcing datasets
- processing of high-resolution DEM products
- integration of SAFRAN and ERA5 datasets
- CryoGrid workflow adaptations

---

# Repository structure

The main organization is:

```
CryoGrid_VP_Workflow/

├── forcing/
│
│   ├── DEM_Script_VP/
│   │   └── LiDAR_HD_DEM/
│   │       └── IGN LiDAR HD DEM processing workflow
│   │
│   └── Forcing_Data/
│       └── LiDAR_HD_DEM_10m/
│           └── Generated LiDAR DEM dataset
│
├── CryoGrid/
│   └── CryoGrid source code and modifications
│
└── ...
```

---

# IGN LiDAR HD DEM workflow

The IGN LiDAR HD workflow generates high-resolution topographic inputs for CryoGrid simulations over the French Alps.

The processing scripts are located here:

[LiDAR HD DEM processing workflow](forcing/DEM_Script_VP/LiDAR_HD_DEM/README.md)

The generated DEM dataset is stored separately here at forcing/Forcing_Data/LiDAR_HD_DEM_10m/ (but the data is too large to be on GitHub).

The workflow:

1. Reads SAFRAN massif polygons
2. Downloads IGN LiDAR HD elevation data through the IGN WMS service
3. Automatically splits large requests into smaller chunks
4. Caches downloaded tiles
5. Merges and cleans elevation data
6. Clips DEMs to SAFRAN massif boundaries
7. Generates DEM and mask GeoTIFF files
8. Runs automatic quality-control diagnostics

---

# LiDAR DEM products

The current repository dataset was generated at:

```
Resolution = 10 m
```

The workflow itself supports other resolutions by changing the requested resolution during DEM generation.

All products use:

| Property | Value |
|---|---|
| Projection | Lambert-93 |
| EPSG | 2154 |
| Horizontal units | metres |
| Elevation units | metres |
| Vertical reference | IGN69 |

For each SAFRAN massif:

```
DEM_massif_XX.tif
```

contains the elevation data.

```
DEM_mask_massif_XX.tif
```

contains the corresponding polygon mask:

| Value | Meaning |
|---|---|
| 1 | Inside SAFRAN massif |
| 0 | Outside SAFRAN massif |

The mask is independent from DEM availability and allows missing LiDAR pixels to be distinguished from areas outside the modelling domain.

---

# LiDAR diagnostics

The LiDAR workflow produces automatic quality-control outputs:

```
LiDAR_HD_DEM_10m/

└── diagnostics/

    ├── LiDAR_HD_DEM_massifs.png
    ├── LiDAR_HD_DEM_missing_pixels.png
    └── LiDAR_HD_DEM_validation.csv
```

The diagnostics include:

- overview map of all DEMs
- visualization of missing LiDAR pixels
- validation table summarizing DEM coverage by SAFRAN massif

---

# Running the LiDAR workflow

The main DEM generation function is:

```matlab
build_lidar_hd_dem()
```

The diagnostic workflow is:

```matlab
run_lidar_diagnostics()
```

Detailed instructions, function descriptions, and examples are provided in:

[LiDAR HD DEM workflow README](forcing/DEM_Script_VP/LiDAR_HD_DEM/README.md)

---

# Other forcing workflows

Additional forcing preparation scripts are located in:

```
forcing/
```

including tools for:

- SAFRAN forcing processing
- ERA5 integration
- CryoGrid forcing structure generation

---

# Requirements

Main requirements:

- MATLAB
- Mapping Toolbox

Some optional processing functions may require additional MATLAB toolboxes.

---

# Coordinate systems

All spatial datasets in the LiDAR workflow use:

```
Lambert-93
EPSG:2154
```

The SAFRAN massif shapefile and generated DEM products therefore share the same projected coordinate system.

---

# Quick start

Clone the repository:

```bash
git clone <repository-url>
```

Open MATLAB and add the workflow folders:

```matlab
addpath(genpath("forcing/DEM_Script_VP"))
```

For LiDAR DEM generation and processing, start with:

[forcing/DEM_Script_VP/LiDAR_HD_DEM/README.md](forcing/DEM_Script_VP/LiDAR_HD_DEM/README.md)