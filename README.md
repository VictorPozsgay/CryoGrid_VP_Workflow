# CryoGrid_VP_Workflow

MATLAB workflow for preparing forcing data and environmental inputs for **CryoGrid mountain permafrost simulations**.

This repository contains tools developed for mountain permafrost modelling, including:

* preparation and processing of meteorological forcing datasets
* high-resolution DEM generation and processing
* geological dataset preparation from BRGM GEO050K_HARM
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
│   │       ├── VP_DEM/
│   │       │   └── High-resolution DEM and terrain-product generation workflows
│   │       │
│   │       └── VP_Geol/
│   │           └── BRGM GEO050K_HARM geological processing workflows
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
    ├── geology/
    │   └── Generated BRGM geological datasets
    │
    └── DEM/
        └── Generated LiDAR DEM products
```

The folder:

```
CryoGridCommunity_forcing/
```

contains generated forcing datasets, geological products, and DEM products.

Because these datasets can become very large, this folder is intentionally excluded from Git. It is expected to exist locally when running the processing workflows.

---

# CryoGrid VP workflows

The processing workflows are located in:

```
CryoGridCommunity_source/source/
```

They are organized into three independent modules:

```
source/

├── VP_Forcing/
│   └── Meteorological forcing preparation

├── VP_DEM/
│   └── DEM and topographic processing

└── VP_Geol/
    └── Geological dataset preparation
```

Each workflow is independently executable and documented in its own README.

---

# VP_Forcing: meteorological forcing workflow

Documentation:

[SAFRAN S2M workflow](CryoGrid/CryoGridCommunity_source/source/VP_Forcing/README.md)

The workflow prepares CryoGrid-compatible meteorological forcing datasets by combining:

* SAFRAN/S2M meteorological forcing
* ERA5 top-of-atmosphere solar radiation

The workflow:

1. Reads SAFRAN/S2M meteorological forcing
2. Reads ERA5 top-of-atmosphere solar radiation
3. Interpolates ERA5 radiation to SAFRAN massifs
4. Merges meteorological and radiation variables
5. Produces CryoGrid-compatible forcing structures
6. Runs automated validation and diagnostic plots

The final forcing dataset is generated in:

```
CryoGridCommunity_forcing/
└── meteo/
    └── CryoGrid_ready/
        └── FORCING_SAFRAN_ALL.mat
```

This file contains all processed SAFRAN massifs, elevation levels, meteorological variables, and radiation forcing required by CryoGrid.

---

# VP_DEM: IGN LiDAR HD DEM workflow

Documentation:

[IGN LiDAR HD DEM workflow](CryoGrid/CryoGridCommunity_source/source/VP_DEM/LiDAR_HD_DEM/README.md)

Main workflow: [`prepare_dem.m`](/CryoGrid/CryoGridCommunity_source/source/VP_DEM/LiDAR_HD_DEM/prepare_dem.m).

## Overview

The IGN LiDAR HD workflow generates high-resolution topographic inputs for CryoGrid simulations over the French Alps.

The processing scripts are located in:

```
CryoGridCommunity_source/source/VP_DEM/
```

The generated DEM and terrain products are stored separately in:

```
CryoGridCommunity_forcing/
└── DEM/
    └── LiDAR_HD_DEM_10m/
```

The workflow is fully restartable. Previously downloaded IGN WMS chunks are stored in a persistent cache, allowing interrupted processing to resume without repeating completed downloads. Each generated dataset also contains a persistent cache/ directory storing downloaded IGN WMS chunks used for restart capability and to avoid redundant downloads.

The workflow is driven by [`prepare_dem.m`](/CryoGrid/CryoGridCommunity_source/source/VP_DEM/LiDAR_HD_DEM/prepare_dem.m) and:

1. Reads SAFRAN massif polygons.
2. Downloads IGN LiDAR HD elevation data through the IGN WMS service.
3. Automatically splits large requests into WMS-compatible chunks.
4. Reuses cached downloads when available, allowing interrupted runs to be resumed.
5. Cleans and merges elevation data into one DEM per SAFRAN massif.
6. Clips DEMs to the SAFRAN massif boundaries.
7. Generates DEM and binary mask GeoTIFF files.
8. Merges all massif DEMs into a continuous Alpine DEM.
9. Computes terrain derivatives (currently slope and aspect) from the Alpine DEM.
10. Clips all terrain products back to the individual massif grids.

Quality-control diagnostics are provided by the separate [`run_lidar_diagnostics.m`](/CryoGrid/CryoGridCommunity_source/source/VP_DEM/LiDAR_HD_DEM/run_lidar_diagnostics.m) workflow.

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

The generated products include:

* massif DEMs
* massif masks
* a merged Alpine DEM
* Alpine terrain derivatives (currently slope and aspect)
* massif terrain derivatives clipped from the Alpine products

For each SAFRAN massif:

```
DEM_massif_XX.tif
```

contains the elevation data, and

```
DEM_mask_massif_XX.tif
```

contains the corresponding polygon mask:

| Value | Meaning |
| ----- | ------- |
| 1 | Inside SAFRAN massif |
| 0 | Outside SAFRAN massif |

Terrain derivatives are computed from the merged Alpine DEM before being clipped back to the massif grids. This avoids artificial discontinuities at SAFRAN massif boundaries while ensuring that all DEM, mask and derivative products for a given massif share identical extent, resolution and pixel alignment.

---

# VP_Geol: BRGM GEO050K_HARM geological workflow

Documentation:

[BRGM GEO050K_HARM workflow](CryoGrid/CryoGridCommunity_source/source/VP_Geol/README.md)

## Overview

The geological workflow prepares geological datasets from the official **BRGM GEO050K_HARM** database for CryoGrid simulations.

The processing scripts are located in:

```
CryoGridCommunity_source/source/VP_Geol/
```

The generated geological products are stored in:

```
CryoGridCommunity_forcing/
└── geology/
    └── BRGM_GEO050K_HARM/
```

The workflow:

1. Downloads required BRGM department datasets
2. Merges geological polygons covering the French Alps
3. Builds geological inventories
4. Rasterizes geological units onto CryoGrid DEM grids
5. Produces a reduced inventory containing only geological units present in the modelling domain

The generated geological rasters:

* use the same grid as the DEM products,
* use Lambert-93 projection,
* preserve traceability to the original BRGM geological units.

A future classification step will map the 1000+ BRGM geological units into a reduced set of CryoGrid-ready geological classes suitable for thermal and hydrological parameterization.

## Dependency

The geological workflow relies on the existence of CryoGrid-compatible DEM products generated by **VP_DEM**.

Before running **VP_Geol**, the DEM workflow must therefore be completed:

```
prepare_dem()
        │
        ▼
CryoGridCommunity_forcing/
└── DEM/
    └── LiDAR_HD_DEM_10m/
        └── DEM/

        │
        ▼
prepare_geology()
```

The DEM grids define the target spatial framework for geological rasterization. Geological products are generated directly on the same grid as the DEM rasters to ensure perfect spatial consistency between topography and geology.

---

# CryoGrid integration

The generated forcing, geology and DEM datasets are designed to provide inputs for:

```
CryoGridCommunity_source/
```

and associated CryoGrid simulation workflows.

The general workflow is:

```
External datasets
        │
        ▼
prepare_forcing()    prepare_dem()    prepare_geology()
        │                  │                  │
        └──────────────────┴──────────────────┘
                           │
                           ▼
CryoGridCommunity_forcing/
├── meteo/      (meteorological forcing)
├── DEM/        (DEMs, terrain derivatives, and diagnostics)
└── geology/    (geological products)
                           │
                           ▼
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

All spatial datasets generated by [`prepare_dem.m`](/CryoGrid/CryoGridCommunity_source/source/VP_DEM/LiDAR_HD_DEM/prepare_dem.m) and [`prepare_geology.m`](/CryoGrid/CryoGridCommunity_source/source/VP_Geol/prepare_geology.m) use:

```
Lambert-93
EPSG:2154
```

The SAFRAN massif polygons, DEM products, and geological rasters therefore share the same projected coordinate system.

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

Start with the workflow corresponding to the required dataset:

Meteorological forcing ([`prepare_forcing.m`](/CryoGrid/CryoGridCommunity_source/source/VP_Forcing/prepare_forcing.m)):

[SAFRAN S2M workflow](CryoGrid/CryoGridCommunity_source/source/VP_Forcing/README.md)

DEM generation ([`prepare_dem.m`](/CryoGrid/CryoGridCommunity_source/source/VP_DEM/LiDAR_HD_DEM/prepare_dem.m)):

[IGN LiDAR HD DEM workflow](CryoGrid/CryoGridCommunity_source/source/VP_DEM/LiDAR_HD_DEM/README.md)

Geological processing ([`prepare_geology.m`](/CryoGrid/CryoGridCommunity_source/source/VP_Geol/prepare_geology.m)):

[BRGM GEO050K_HARM workflow](CryoGrid/CryoGridCommunity_source/source/VP_Geol/README.md)