# CryoGrid_VP_Workflow

MATLAB workflow for preparing forcing data and environmental inputs for **CryoGrid mountain permafrost simulations**.

This repository contains tools for:

- meteorological forcing preparation (SAFRAN / ERA5)
- high-resolution DEM and topographic processing (IGN LiDAR HD)
- geological dataset preparation (BRGM GEO050K_HARM)
- CryoGrid Community workflow adaptations

---

# Repository structure

```text
CryoGrid_VP_Workflow/

├── CryoGrid/
│
│   ├── CryoGridCommunity_source/
│   │   └── source/
│   │       ├── VP_Meteo/
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

`CryoGridCommunity_forcing/` contains generated datasets and is excluded from Git because products and cached downloads can become very large.

The three preparation workflows are located in:

```text
CryoGrid/CryoGridCommunity_source/source/

├── VP_Meteo/
│   └── Meteorological forcing preparation
│
├── VP_DEM/
│   └── DEM and topographic processing
│
└── VP_Geol/
    └── Geological dataset preparation
```

Each workflow has its own README.

---

# Canonical paths

The main workflows use:

```text
CryoGridCommunity_forcing/
├── meteo/
├── DEM/
└── geology/
```

Typical MATLAB configuration:

```matlab
meteo_path   = "CryoGridCommunity_forcing/meteo";
dem_path     = "CryoGridCommunity_forcing/DEM";
geology_path = "CryoGridCommunity_forcing/geology";
safran_shp   = "CryoGridCommunity_forcing/meteo/SAFRAN/shapefile/massifs_alpes_2154.shp";
```

The corresponding workflows are:

```matlab
prepare_forcing(meteo_path,varargin)
prepare_dem(dem_path,safran_shp,varargin)
prepare_geology(geology_path,dem_path,varargin)
```

---

# VP_Meteo: meteorological forcing workflow

Documentation:

[SAFRAN S2M workflow](CryoGrid/CryoGridCommunity_source/source/VP_Meteo/README.md)

Main workflow:

[`prepare_forcing.m`](CryoGrid/CryoGridCommunity_source/source/VP_Meteo/prepare_forcing.m)

The workflow combines:

- SAFRAN/S2M meteorological forcing
- ERA5 top-of-atmosphere radiation

It:

1. Reads SAFRAN forcing
2. Reads ERA5 radiation
3. Interpolates radiation to SAFRAN massifs
4. Produces CryoGrid-compatible forcing structures
5. Runs validation and diagnostics

Output:

```text
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

The workflow generates high-resolution topographic products from **IGN LiDAR HD** data over the French Alps.

Generated products are stored separately from the source code:

```text
CryoGridCommunity_forcing/
└── DEM/
    └── LiDAR_HD_DEM_10m/
```

## DEM workflow

Run:

```matlab
prepare_dem(dem_path,safran_shp)
```

The workflow follows these steps:

1. Read SAFRAN massif polygons
2. Download IGN LiDAR HD elevation data through WMS
3. Split large requests into WMS-compatible chunks
4. Reuse cached downloads
5. Build and clip massif DEMs and masks
6. Merge massif DEMs into a continuous Alpine DEM
7. Compute Alpine slope and aspect
8. Compute full-Alps terrain-based sky-view factor
9. Clip Alpine topographic products to SAFRAN massifs
10. Convert aspect to the CryoGrid convention
11. Compute naive slope-based SVF reference products
12. Optionally run LiDAR diagnostics

The workflow is restartable and existing products are reused unless `Overwrite=true`.

### Main options

```matlab
prepare_dem(..., ...
    "Resolution",10, ...
    "Overwrite",false, ...
    "Diagnostics",false, ...
    "SVFNumBins",36, ...
    "SVFMaxDistance",1000)
```

Current default DEM resolution:

```text
10 m
```

All topographic products use:

| Property | Value |
| --- | --- |
| Projection | Lambert-93 |
| EPSG | 2154 |
| Horizontal units | metres |
| Elevation units | metres |
| Vertical reference | IGN69 |

---

## DEM products

For each SAFRAN massif:

```text
DEM/
├── DEM_massif_XX.tif
├── DEM_mask_massif_XX.tif
├── cache/
└── ALPS/
    ├── DEM_ALPS.tif
    └── DEM_ALPS_mask.tif
```

`DEM_massif_XX.tif` contains elevation data clipped to the SAFRAN massif.

Outside pixels are stored as:

```text
-9999
```

The corresponding mask contains:

| Value | Meaning |
| --- | --- |
| 1 | Inside SAFRAN massif |
| 0 | Outside SAFRAN massif |

`DEM_ALPS.tif` is the continuous merged Alpine DEM used as the basis for terrain derivatives and the full-Alps SVF calculation.

The Alpine DEM merge does not resample or reproject the massif DEMs.

---

## Terrain derivatives

Slope and aspect are computed from the continuous Alpine DEM **before** massif clipping. This avoids artificial terrain discontinuities at SAFRAN massif boundaries.

Generated products:

```text
SLOPE/
├── SLOPE_massif_XX.tif
└── ALPS/
    └── SLOPE_ALPS.tif

ASPECT/
├── ASPECT_massif_XX.tif
└── ALPS/
    └── ASPECT_ALPS.tif
```

### Slope

Slope is stored in degrees:

```text
0°  = flat terrain
90° = vertical terrain
```

### Aspect

The physical GIS aspect convention is:

```text
0°   = North
90°  = East
180° = South
270° = West
```

---

## Sky-view factor

The workflow computes two types of SVF.

### Terrain-based SVF

```text
SVF/
├── SVF_massif_XX.tif
└── ALPS/
    └── SVF_ALPS.tif
```

The full-Alps SVF is calculated by horizon ray tracing over the continuous Alpine DEM before massif extraction.

Default configuration:

```text
DEM resolution    : 10 m
Maximum distance  : 1000 m
Azimuth bins      : 36
Azimuth spacing   : 10°
```

For each target pixel, terrain is ray-traced in multiple azimuth directions and the terrain horizon is determined up to the configured maximum distance. The horizon information is combined with the local slope and aspect to calculate the sky-view contribution.

The full-Alps calculation is processed spatially in chunks with surrounding terrain buffers, allowing terrain outside an individual SAFRAN massif to contribute to its SVF.

### Naive SVF

```text
SVF_naive/
└── SVF_naive_massif_XX.tif
```

This is the local slope-only reference:

```text
SVF_naive = (1 + cos(slope)) / 2
           = cos²(slope / 2)
```

It does not account for surrounding terrain.

---

## CryoGrid aspect conversion

CryoGrid uses the following aspect convention:

```text
0°   = South
90°  = East
180° = North
270° = West
```

The workflow therefore generates:

```text
ASPECT_CryoGrid/
└── ASPECT_CryoGrid_massif_XX.tif
```

The original physical GIS aspect products are preserved.

---

## IGN WMS downloads and restartability

IGN WMS requests are limited to:

```text
4000 × 4000 pixels
```

Large requests are automatically subdivided into compatible chunks.

Cached chunks are stored in:

```text
DEM/
└── cache/
```

Existing cached chunks and generated products are reused whenever possible, allowing interrupted processing to be restarted without repeating completed downloads.

---

# LiDAR diagnostics

Diagnostics are generated with:

```matlab
run_lidar_diagnostics(...)
```

They can be enabled directly from `prepare_dem()`:

```matlab
prepare_dem( ...
    dem_path, ...
    safran_shp, ...
    "Diagnostics",true)
```

or run independently:

```matlab
run_lidar_diagnostics( ...
    "CryoGridCommunity_forcing/DEM/LiDAR_HD_DEM_10m", ...
    "CryoGridCommunity_forcing/meteo/SAFRAN/shapefile/massifs_alpes_2154.shp")
```

The diagnostic workflow automatically discovers Alpine products following:

```text
PRODUCT/
└── ALPS/
    └── PRODUCT_ALPS.tif
```

For the current dataset this includes:

```text
DEM/ALPS/DEM_ALPS.tif
SLOPE/ALPS/SLOPE_ALPS.tif
ASPECT/ALPS/ASPECT_ALPS.tif
SVF/ALPS/SVF_ALPS.tif
```

Diagnostics are stored in:

```text
LiDAR_HD_DEM_10m/
└── diagnostics/
```

The complete diagnostics folder contains the generated PNG figures and validation outputs.

Typical outputs include:

```text
diagnostics/
├── LiDAR_HD_DEM_massifs.png
├── LiDAR_HD_DEM_ALPS_overview.png
├── LiDAR_HD_SLOPE_ALPS_overview.png
├── LiDAR_HD_ASPECT_ALPS_overview.png
├── LiDAR_HD_SVF_ALPS_overview.png
├── LiDAR_HD_DEM_missing_pixels.png
├── LiDAR_HD_DEM_validation.csv
└── LiDAR_HD_DEM_validation.md
```

The diagnostics workflow uses common Alpine plotting bounds where appropriate so that Alpine and massif visualizations remain directly comparable.

---

# VP_Geol: BRGM GEO050K_HARM workflow

Documentation:

[BRGM GEO050K_HARM workflow](CryoGrid/CryoGridCommunity_source/source/VP_Geol/README.md)

Main workflow:

[`prepare_geology.m`](CryoGrid/CryoGridCommunity_source/source/VP_Geol/prepare_geology.m)

The workflow prepares CryoGrid-compatible geological inputs:

1. Downloads BRGM GEO050K_HARM data
2. Merges Alpine geological polygons
3. Builds geological inventories
4. Rasterizes geological units onto the DEM grid
5. Builds final masks retaining pixels with valid DEM, slope, aspect, and geology

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

Geological rasters use the same Lambert-93 (EPSG:2154) grid as the corresponding DEM products and preserve traceability to the original BRGM geological units.

---

# CryoGrid integration

The complete preparation chain is:

```text
External datasets
        │
        ▼
┌────────────────────┐
│ prepare_forcing()  │
└────────────────────┘
        │
┌────────────────────┐
│ prepare_dem()      │
└────────────────────┘
        │
┌────────────────────┐
│ prepare_geology()  │
└────────────────────┘
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

The DEM and geology workflows use the same spatial reference and DEM grid, allowing the resulting environmental variables to be combined for CryoGrid simulations and subsequent spatial analyses.

---

# Requirements

Main requirements:

- MATLAB
- Mapping Toolbox

Additional MATLAB toolboxes may be required depending on the workflow and specific processing steps.

---

# Quick start

Clone the repository:

```bash
git clone <repository-url>
```

Add the MATLAB source tree:

```matlab
addpath(genpath("CryoGrid/CryoGridCommunity_source/source"))
```

Then run the required preparation workflow.

### Meteorological forcing

[`prepare_forcing.m`](CryoGrid/CryoGridCommunity_source/source/VP_Meteo/prepare_forcing.m)

[SAFRAN S2M workflow](CryoGrid/CryoGridCommunity_source/source/VP_Meteo/README.md)

### DEM and topography

[`prepare_dem.m`](CryoGrid/CryoGridCommunity_source/source/VP_DEM/LiDAR_HD_DEM/prepare_dem.m)

[IGN LiDAR HD DEM workflow](CryoGrid/CryoGridCommunity_source/source/VP_DEM/LiDAR_HD_DEM/README.md)

### Geology

[`prepare_geology.m`](CryoGrid/CryoGridCommunity_source/source/VP_Geol/prepare_geology.m)

[BRGM GEO050K_HARM workflow](CryoGrid/CryoGridCommunity_source/source/VP_Geol/README.md)