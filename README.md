# CryoGrid_VP_Workflow

MATLAB workflow for preparing forcing data and topographic inputs for **CryoGrid mountain permafrost simulations**.

This repository contains tools developed for mountain permafrost modelling, including:

* preparation and processing of meteorological forcing datasets
* high-resolution DEM processing
* SAFRAN and ERA5 forcing preparation
* CryoGrid Community workflow adaptations

---

# Repository structure

The main organization is:

```
CryoGrid_VP_Workflow/

├── CryoGrid/
│   │
│   ├── CryoGridCommunity_source/
│   │   │
│   │   └── source/
│   │       │
│   │       ├── VP_Forcing/
│   │       │   └── SAFRAN / ERA5 forcing preparation workflows
│   │       │
│   │       └── VP_DEM/
│   │           └── High-resolution DEM processing workflows
│   │
│   ├── CryoGridCommunity_run/
│   │
│   └── CryoGridCommunity_results/
│
└── CryoGridCommunity_forcing/
    │
    ├── meteo/
    │   └── Generated SAFRAN/ERA5 forcing datasets
    │
    └── DEM/
        └── Generated LiDAR DEM products
```

The folder:

```
CryoGridCommunity_forcing/
```

contains generated forcing datasets and DEM products.

Because these datasets can become very large, this folder is intentionally excluded from Git. It is expected to exist locally when running the processing workflows.

---

# CryoGrid VP forcing workflows

The forcing preparation workflows are located in:

```
CryoGrid/CryoGridCommunity_source/source/VP_Forcing/
```

They include:

* SAFRAN meteorological forcing processing
* ERA5 data extraction and processing
* merging of SAFRAN and ERA5-derived variables
* preparation of CryoGrid-compatible forcing structures

Detailed documentation will be added as the workflow is finalized.

---

# VP_Forcing documentation

The meteorological forcing preparation workflow is documented separately:

[SAFRAN S2M workflow](CryoGrid/CryoGridCommunity_source/source/VP_Forcing/README.md)

The workflow:

1. Reads SAFRAN/S2M meteorological forcing
2. Reads ERA5 top-of-atmosphere solar radiation
3. Interpolates ERA5 radiation to SAFRAN massifs
4. Produces CryoGrid-compatible forcing structures
5. Runs automated validation and diagnostic plots

The final forcing dataset is generated in:

```
CryoGridCommunity_forcing/
└── meteo/
    └── CryoGrid_ready/
        └── FORCING_SAFRAN_ALL.mat
```


This file contains all processed SAFRAN massifs, elevation levels,
meteorological variables, and radiation forcing required by CryoGrid.

---

# IGN LiDAR HD DEM workflow

Detailed documentation:

[IGN LiDAR HD DEM workflow](CryoGrid/CryoGridCommunity_source/source/VP_DEM/LiDAR_HD_DEM/README.md)

## Overview 

The IGN LiDAR HD workflow generates high-resolution topographic inputs for CryoGrid simulations over the French Alps.

The processing scripts are located in:

```
CryoGrid/CryoGridCommunity_source/source/VP_DEM/LiDAR_HD_DEM/
```

The generated DEM products are stored separately in:

```
CryoGridCommunity_forcing/

└── DEM/

    └── LiDAR_HD_DEM_10m/
```

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

## LiDAR DEM products

The current generated dataset uses:

```
Resolution = 10 m
```

The workflow itself supports other resolutions by changing the requested resolution during DEM generation.

All LiDAR products use:

| Property           | Value      |
| ------------------ | ---------- |
| Projection         | Lambert-93 |
| EPSG               | 2154       |
| Horizontal units   | metres     |
| Elevation units    | metres     |
| Vertical reference | IGN69      |

For each SAFRAN massif:

```
DEM_massif_XX.tif
```

contains the elevation data.

```
DEM_mask_massif_XX.tif
```

contains the corresponding polygon mask:

| Value | Meaning               |
| ----- | --------------------- |
| 1     | Inside SAFRAN massif  |
| 0     | Outside SAFRAN massif |

The mask is independent from DEM availability and allows missing LiDAR pixels to be distinguished from areas outside the modelling domain.

---

## LiDAR diagnostics

The LiDAR workflow generates automatic quality-control outputs.

The full diagnostics are generated together with the DEM dataset:

```
CryoGridCommunity_forcing/

└── DEM/

    └── LiDAR_HD_DEM_10m/

        └── diagnostics/
```

Since the forcing folder is ignored by Git, a lightweight copy of the diagnostics is stored with the processing scripts:

```
CryoGrid/

└── CryoGridCommunity_source/

    └── source/

        └── VP_DEM/

            └── LiDAR_HD_DEM/

                └── diagnostics/
```

Tracked diagnostic outputs include:

* DEM overview figure
* missing LiDAR pixel figure
* validation table

---

# CryoGrid integration

The generated forcing and DEM datasets are designed to provide inputs for:

```
CryoGrid/CryoGridCommunity_source/
```

and the associated CryoGrid simulation workflows.

The general workflow is:

```
External datasets
        |
        v
VP_Forcing / VP_DEM processing
        |
        v
CryoGridCommunity_forcing/
        |
        v
CryoGrid simulations
```

---

# Requirements

Main requirements:

* MATLAB
* Mapping Toolbox

Additional MATLAB toolboxes may be required depending on the processing workflow.

---

# Coordinate systems

All spatial datasets in the LiDAR workflow use:

```
Lambert-93
EPSG:2154
```

The SAFRAN massif polygons and generated DEM products therefore share the same projected coordinate system.

---

# Quick start

Clone the repository:

```bash
git clone <repository-url>
```

Open MATLAB and add the CryoGrid source tree:

```matlab
addpath(genpath("CryoGrid/CryoGridCommunity_source/source"))
```

For LiDAR DEM generation and processing, start with:

[IGN LiDAR HD DEM workflow](CryoGrid/CryoGridCommunity_source/source/VP_DEM/LiDAR_HD_DEM/README.md)
