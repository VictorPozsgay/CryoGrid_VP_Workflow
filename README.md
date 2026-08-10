# CryoGrid_VP_Workflow

MATLAB workflow for preparing forcing data and environmental inputs for **CryoGrid mountain permafrost simulations**.

This repository contains tools for:

* meteorological forcing preparation (SAFRAN / ERA5)
* high-resolution DEM and topographic processing (IGN LiDAR HD)
* geological dataset preparation (BRGM GEO050K_HARM)
* CryoGrid Community workflow adaptations

---

# Repository structure

```
CryoGrid_VP_Workflow/

├── CryoGrid/
│
│   ├── CryoGridCommunity_source/
│   │   └── source/
│   │       ├── VP_Forcing/
│   │       ├── VP_DEM/
│   │       └── VP_Geol/
│   │
│   ├── CryoGridCommunity_run/
│   └── CryoGridCommunity_results/
│
└── CryoGridCommunity_forcing/
    ├── meteo/
    ├── geology/
    └── DEM/
```

`CryoGridCommunity_forcing/` contains generated datasets and is excluded from Git because products can become very large.

---

# CryoGrid VP workflows

The processing modules are located in:

```
CryoGrid/CryoGridCommunity_source/source/
```

```
source/

├── VP_Forcing/
│   └── Meteorological forcing preparation

├── VP_DEM/
│   └── DEM and topographic processing

└── VP_Geol/
    └── Geological dataset preparation
```

Each workflow has its own documentation.

---

# Canonical paths

The three preparation workflows use the following root paths:

```text
CryoGridCommunity_forcing/
├── meteo/
├── DEM/
└── geology/
```

```matlab
forcing_path  = "CryoGridCommunity_forcing/DEM";
dem_path      = "CryoGridCommunity_forcing/DEM";
geology_path  = "CryoGridCommunity_forcing/geology";
safran_shp    = "CryoGridCommunity_forcing/meteo/SAFRAN/shapefile/massifs_alpes_2154.shp";
```

The corresponding workflows are:

```matlab
prepare_forcing(forcing_path,varargin)
prepare_dem(dem_path,safran_shp,varargin)
prepare_geology(geology_path,dem_path,varargin)
```

# VP_Forcing: meteorological forcing workflow

Documentation:

[SAFRAN S2M workflow](CryoGrid/CryoGridCommunity_source/source/VP_Forcing/README.md)

The workflow combines:

* SAFRAN/S2M meteorological forcing
* ERA5 top-of-atmosphere radiation

It:

1. Reads SAFRAN forcing
2. Reads ERA5 radiation
3. Interpolates radiation to SAFRAN massifs
4. Produces CryoGrid-compatible forcing structures
5. Runs validation and diagnostics

Output:

```
CryoGridCommunity_forcing/
└── meteo/
    └── CryoGrid_ready/
        └── FORCING_SAFRAN_ALL.mat
```

---

# VP_DEM: IGN LiDAR HD DEM workflow

Documentation:

[IGN LiDAR HD DEM workflow](CryoGrid/CryoGridCommunity_source/source/VP_DEM/LiDAR_HD_DEM/README.md)

Main workflow:

[`prepare_dem.m`](CryoGrid/CryoGridCommunity_source/source/VP_DEM/LiDAR_HD_DEM/prepare_dem.m)

The workflow generates high-resolution topographic products for CryoGrid simulations over the French Alps.

Generated products are stored separately:

```
CryoGridCommunity_forcing/
└── DEM/
    └── LiDAR_HD_DEM_10m/
```

---

## DEM workflow

Run:

```matlab
prepare_dem()
```

The workflow:

1. Reads SAFRAN massif polygons
2. Downloads IGN LiDAR HD elevation data through WMS
3. Splits large requests into compatible chunks
4. Reuses cached downloads
5. Builds massif DEMs and masks
6. Merges massifs into a continuous Alpine DEM
7. Computes terrain derivatives
8. Clips derivatives to massifs
9. Generates CryoGrid-compatible aspect products
10. Optionally runs diagnostics

The workflow is fully restartable.

---

## DEM products

Current dataset:

```
Resolution = 10 m
```

All products use:

| Property | Value |
|---|---|
| Projection | Lambert-93 |
| EPSG | 2154 |
| Horizontal units | metres |
| Elevation units | metres |
| Vertical reference | IGN69 |

For each massif:

```
DEM_massif_XX.tif
```

contains elevation data.

```
DEM_mask_massif_XX.tif
```

contains:

| Value | Meaning |
|---|---|
| 1 | Inside SAFRAN massif |
| 0 | Outside SAFRAN massif |

The Alpine merged DEM:

```
DEM/

└── ALPS/

    ├── DEM_ALPS.tif
    └── DEM_ALPS_mask.tif
```

is used as the basis for terrain derivatives.

---

## Terrain products

Terrain derivatives are computed from the continuous Alpine DEM to avoid discontinuities at massif boundaries.

Generated products:

```
SLOPE/

├── ALPS/
│   └── SLOPE_ALPS.tif
│
└── SLOPE_massif_XX.tif


ASPECT/

├── ALPS/
│   └── ASPECT_ALPS.tif
│
└── ASPECT_massif_XX.tif
```

Slope:

```
degrees (°)
```

Aspect follows the geographic convention:

```
0°   = North
90°  = East
180° = South
270° = West
```

CryoGrid uses:

```
0°   = South
90°  = East
180° = North
270° = West
```

Therefore:

```
ASPECT_CryoGrid/
└── ASPECT_CryoGrid_massif_XX.tif
```

is generated separately. Original aspect products are preserved.

---

## DEM diagnostics

Diagnostics are generated with:

```matlab
run_lidar_diagnostics()
```

They can be included directly in `prepare_dem()`:

```matlab
prepare_dem( ...
    dem_path,...
    shapefile,...
    "Diagnostics",true)
```

or run independently:

```matlab
run_lidar_diagnostics( ...
    "CryoGridCommunity_forcing/DEM/LiDAR_HD_DEM_10m", ...
    "CryoGridCommunity_forcing/meteo/SAFRAN/shapefile/massifs_alpes_2154.shp")
```

The diagnostic workflow automatically detects Alpine products following:

```
PRODUCT/

└── ALPS/

    └── PRODUCT_ALPS.tif
```

Examples:

```
DEM/ALPS/DEM_ALPS.tif
SLOPE/ALPS/SLOPE_ALPS.tif
ASPECT/ALPS/ASPECT_ALPS.tif
```

Outputs:

```
diagnostics/
├── LiDAR_HD_DEM_massifs.png
├── LiDAR_HD_<PRODUCT>_ALPS_overview.png
├── LiDAR_HD_DEM_missing_pixels.png
├── LiDAR_HD_DEM_validation.csv
└── LiDAR_HD_DEM_validation.md
```

---

# VP_Geol: BRGM GEO050K_HARM workflow

Documentation:

[BRGM GEO050K_HARM workflow](CryoGrid/CryoGridCommunity_source/source/VP_Geol/README.md)

The workflow prepares CryoGrid-compatible geological inputs:

1. Downloads BRGM GEO050K_HARM data
2. Merges Alpine geological polygons
3. Builds geological inventories
4. Rasterizes geological units onto the DEM grids
5. Builds a final mask retaining only pixels with valid DEM, slope, aspect, and geology

Output:

```text
CryoGridCommunity_forcing/
└── geology/
    └── BRGM_GEO050K_HARM/
```

The final masks are stored with the corresponding DEM resolution:

```text
CryoGridCommunity_forcing/
└── DEM/
    └── LiDAR_HD_DEM_XXm/
        └── MASK/
            ├── MASK_massif_XX.tif
            └── masking_log.mat
```

Geological rasters use the same grid as the DEM products, Lambert-93 (EPSG:2154), and preserve traceability to the original BRGM geological units.

---

# CryoGrid integration

The complete workflow is:

```
External datasets
        │
        ▼
prepare_forcing()     prepare_dem()     prepare_geology()
        │                   │                  │
        └───────────────────┴──────────────────┘
                            │
                            ▼
                    CryoGridCommunity_forcing/
                    ├── meteo/
                    ├── DEM/
                    └── geology/
                            │
                            ▼
                    CryoGrid simulations
```

---

# Requirements

Main requirements:

* MATLAB
* Mapping Toolbox

Additional toolboxes may be required depending on the workflow.

---

# Coordinate system

All spatial products generated by:

[`prepare_dem.m`](CryoGrid/CryoGridCommunity_source/source/VP_DEM/LiDAR_HD_DEM/prepare_dem.m)

and:

[`prepare_geology.m`](CryoGrid/CryoGridCommunity_source/source/VP_Geol/prepare_geology.m)

use:

```
Lambert-93
EPSG:2154
```

---

# Quick start

Clone:

```bash
git clone <repository-url>
```

Add the MATLAB source tree:

```matlab
addpath(genpath("CryoGrid/CryoGridCommunity_source/source"))
```

Run the required workflow:

Meteorological forcing:

[`prepare_forcing.m`](CryoGrid/CryoGridCommunity_source/source/VP_Forcing/prepare_forcing.m)

[SAFRAN S2M workflow](CryoGrid/CryoGridCommunity_source/source/VP_Forcing/README.md)


DEM and topography:

[`prepare_dem.m`](CryoGrid/CryoGridCommunity_source/source/VP_DEM/LiDAR_HD_DEM/prepare_dem.m)

[IGN LiDAR HD DEM workflow](CryoGrid/CryoGridCommunity_source/source/VP_DEM/LiDAR_HD_DEM/README.md)


Geology:

[`prepare_geology.m`](CryoGrid/CryoGridCommunity_source/source/VP_Geol/prepare_geology.m)

[BRGM GEO050K_HARM workflow](CryoGrid/CryoGridCommunity_source/source/VP_Geol/README.md)