# IGN LiDAR HD DEM workflow

Last revision August 2026 (Pozsgay V.)

This folder contains the MATLAB workflow used to download and process **IGN LiDAR HD elevation data** for CryoGrid mountain permafrost applications in the French Alps.

The workflow generates high-resolution topographic inputs from IGN LiDAR HD data, producing:

- one DEM GeoTIFF per SAFRAN massif
- one binary massif mask per massif
- one merged Alpine DEM
- Alpine terrain derivatives (slope and aspect)
- massif-scale clipped terrain derivatives
- optional CryoGrid-compatible aspect products
- cached IGN WMS chunks for restart capability
- quality-control diagnostics

Current dataset:

```matlab
Resolution = 10
```

---

# Organization

The workflow code and generated datasets are separated:

```
CryoGrid/

└── CryoGridCommunity_source/
    └── source/
        └── VP_DEM/
            └── LiDAR_HD_DEM/
                ├── prepare_dem.m
                ├── run_lidar_diagnostics.m
                ├── processing/
                └── README.md


CryoGridCommunity_forcing/

└── DEM/
    └── LiDAR_HD_DEM_10m/

        ├── DEM/
        │   ├── cache/
        │   ├── DEM_massif_XX.tif
        │   ├── DEM_mask_massif_XX.tif
        │   └── ALPS/
        │       ├── DEM_ALPS.tif
        │       └── DEM_ALPS_mask.tif
        │
        ├── SLOPE/
        │   ├── ALPS/
        │   │   └── SLOPE_ALPS.tif
        │   └── SLOPE_massif_XX.tif
        │
        ├── ASPECT/
        │   ├── ALPS/
        │   │   └── ASPECT_ALPS.tif
        │   └── ASPECT_massif_XX.tif
        │
        ├── ASPECT_CryoGrid/
        │   └── ASPECT_CryoGrid_massif_XX.tif
        │
        └── diagnostics/
```

`CryoGridCommunity_forcing/` is excluded from Git because generated DEM products and IGN cache files can become very large.

---

# Workflow overview

The complete workflow is executed through:

```matlab
prepare_dem()
```

The workflow:

1. Reads SAFRAN massif polygons
2. Downloads IGN LiDAR HD elevation data through IGN WMS
3. Splits large requests into WMS-compatible chunks
4. Reuses cached downloads when available
5. Cleans and merges elevation data
6. Clips DEMs to SAFRAN massif boundaries
7. Saves DEM and binary mask GeoTIFF files
8. Merges all massif DEMs into one Alpine DEM
9. Computes Alpine terrain derivatives
10. Clips derivatives to SAFRAN massifs
11. Converts aspect to CryoGrid convention
12. Optionally generates diagnostics

Terrain derivatives are computed from the continuous Alpine DEM before clipping. This avoids artificial discontinuities between SAFRAN massifs.

The Alpine DEM merge is performed without resampling.

---

# Coordinate system

All products use:

| Property | Value |
|---|---|
| Projection | Lambert-93 |
| EPSG | 2154 |
| Horizontal units | metres |
| Elevation units | metres |
| Vertical reference | IGN69 |

---

# DEM generation

Main function:

```matlab
prepare_dem()
```

Example:

```matlab
prepare_dem( ...
    "CryoGridCommunity_forcing/DEM", ...
    "CryoGridCommunity_forcing/meteo/SAFRAN/shapefile/massifs_alpes_2154.shp")
```

The first argument is the parent DEM directory.

The generated dataset is:

```
CryoGridCommunity_forcing/

└── DEM/

    └── LiDAR_HD_DEM_10m/
```

The folder name is automatically generated from the requested resolution.

---

# Options

## Resolution

Default:

```matlab
Resolution = 10
```

Example:

```matlab
prepare_dem(...,"Resolution",5)
```

Controls:

- WMS download resolution
- DEM pixel size
- output folder name

---

## Overwrite

Existing products are reused by default.

Example:

```matlab
prepare_dem(...,"Overwrite",true)
```

forces recomputation.

---

## Diagnostics

Diagnostics can optionally be generated automatically.

Default:

```matlab
Diagnostics = false
```

Example:

```matlab
prepare_dem( ...
    dem_path,...
    shapefile,...
    "Diagnostics",true)
```

When enabled:

```matlab
run_lidar_diagnostics()
```

is called after all products are generated.

Outputs are stored in:

```
LiDAR_HD_DEM_10m/

└── diagnostics/
```

---

# DEM products

For each SAFRAN massif:

```
DEM_massif_XX.tif
```

contains:

- elevation in metres
- Lambert-93 coordinates
- requested spatial resolution
- NoData outside the massif polygon

Outside pixels are stored as:

```
-9999
```

The corresponding mask:

```
DEM_mask_massif_XX.tif
```

contains:

| Value | Meaning |
|---|---|
| 1 | Inside SAFRAN massif |
| 0 | Outside SAFRAN massif |

---

# Alpine DEM

After all massif DEMs are generated:

```
DEM/

└── ALPS/

    ├── DEM_ALPS.tif
    └── DEM_ALPS_mask.tif
```

are created.

The Alpine DEM defines the continuous modelling domain used for terrain derivatives.

---

# Terrain derivatives

Terrain derivatives are computed from:

```
DEM/ALPS/DEM_ALPS.tif
```

before clipping.

Generated products:

```
SLOPE/

├── ALPS/
│   └── SLOPE_ALPS.tif
│
└── SLOPE_massif_XX.tif
```

and:

```
ASPECT/

├── ALPS/
│   └── ASPECT_ALPS.tif
│
└── ASPECT_massif_XX.tif
```

## Slope

Stored in degrees:

```
0°  = flat terrain
90° = vertical terrain
```

## Aspect

Physical geographic convention:

```
0°   = North
90°  = East
180° = South
270° = West
```

---

# Sky-View Factor (SVF)

The workflow computes a terrain-based **sky-view factor (SVF)** from the 10 m Alpine DEM using horizon ray tracing. SVF represents the fraction of the hemispherical sky visible from each DEM pixel, accounting for surrounding topography and the local surface slope/aspect. It is used to represent topographic effects on radiative forcing in the CryoGrid workflow.

## Method

For each target DEM pixel:

1. The local elevation, slope and aspect are obtained from the DEM and pre-computed derivative products.
2. Terrain is ray-traced in a set of azimuth directions.
3. For each ray, the maximum terrain elevation angle (horizon angle) is determined up to a specified maximum distance.
4. The horizon angle is combined with the local slope and aspect to calculate the sky-opening contribution for that azimuth.
5. Contributions are integrated over the full 360° to obtain the SVF.
6. The resulting SVF is written to GeoTIFF.

Ray coordinates are converted to raster indices using continuous-coordinate rounding. Consecutive ray samples that fall in the same raster cell are removed as an optimization, while retaining the first occurrence and therefore the nearest distance to that cell.

Ray tracing is parallelized over independent blocks of target pixels using MATLAB's process-based parallel pool.

## Default parameters

The parameters are configurable. The current default configuration is:

    DEM resolution       : 10 m
    Maximum horizon      : 1000 m
    Azimuth bins         : 36
    Azimuth spacing      : 10°

These values provide a practical compromise between terrain representation and computational cost.

- Increasing the number of azimuth bins improves representation of narrow or strongly directional terrain features but increases computation.
- Increasing the maximum horizon distance allows more distant terrain to contribute but increases computation.
- The parameters can therefore be modified for sensitivity testing or different applications.

## NoData and DEM boundaries

NoData terrain is **not filled or interpolated**. Rays may continue through NoData and can subsequently encounter valid terrain. This avoids inventing elevations but means that SVF close to the outer DEM boundary, or around internal NoData gaps, is potentially less reliable.

The current assumption is that the Alpine DEM boundary is often located near major mountain ridges, so missing terrain beyond the boundary will frequently have a limited effect on the visible sky. This remains an approximation.

## Limitations and hypotheses

The resulting SVF is a terrain-derived approximation rather than an exact hemispherical visibility calculation. The main limitations are:

- **Finite horizon distance:** terrain beyond the selected maximum distance is ignored.
- **Finite azimuthal resolution:** terrain features between sampled azimuths may be missed.
- **DEM resolution:** sub-grid terrain features are not represented.
- **DEM boundaries and NoData:** missing terrain can affect horizons, particularly close to data boundaries.
- **Terrain only:** vegetation, buildings and other non-topographic obstructions are not included.
- **Static topography:** changes in terrain, snow, glaciers or vegetation are not represented.
- **Discrete raster ray tracing:** visibility is evaluated against DEM cells rather than a continuous terrain surface.

For the full-Alps calculation, the Alpine DEM is processed in spatial chunks with a surrounding horizon buffer. This avoids calculating SVF independently for each SAFRAN massif and allows a continuous full-Alps SVF product to be generated before extracting the results for individual massifs.

## Validation

The ray-tracing implementation was validated on a 301 × 301 pixel test window. For the 1 km configuration, the resulting SVF statistics were:

    Minimum SVF  : 0.16047
    Maximum SVF  : 0.99964
    Mean SVF     : 0.78407
    Median SVF   : 0.81738

The exact values depend on the selected test window and terrain, and are primarily used to verify reproducibility and detect unintended changes to the implementation.

## SVF horizon-distance sensitivity

A sensitivity test was performed on a 301 × 301 pixel test window, comparing ray-traced SVF calculations with maximum horizon distances of 1, 2, 3, 4, 5, 7.5 and 10 km.

The 1 km and 5 km results differed by:

    Mean difference    : 0.004613
    Median difference  : 0.001499
    Mean |difference|  : 0.004613
    Max |difference|   : 0.056746
    95th percentile    : 0.019230
    99th percentile    : 0.028998
    |difference| > .01 : 16.16 %
    |difference| > .02 : 4.58 %
    |difference| > .05 : 0.01 %

Increasing the horizon distance progressively reduced the mean SVF, but the effect became increasingly small at longer distances. For comparison, the mean SVF in the test window was approximately 0.7841 at 1 km, 0.7795 at 5 km, and 0.7786 at 10 km.

The difference between 1 and 5 km was considered small enough for the intended CryoGrid application. SVF will subsequently be used as one variable among elevation, slope, aspect, geology and other terrain characteristics in a clustering procedure, so a localized SVF difference of a few hundredths is not expected to have a major impact.

By contrast, replacing the original CryoGrid approximation

    SVF = cos²(slope / 2)

with 1 km ray-traced SVF produced a substantially larger difference:

    Mean difference    : -0.155782
    Median difference  : -0.132831
    Mean |difference|  : 0.155782
    Max |difference|   : 0.591185
    95th percentile    : 0.368943
    99th percentile    : 0.443810

Thus, accounting explicitly for surrounding terrain has a much larger effect than extending the horizon distance from 1 km to several kilometres.

A maximum horizon distance of **1 km is therefore used as the default**, providing a good balance between physical realism and computational cost. The parameter remains configurable for sensitivity testing.

---

# CryoGrid aspect conversion

CryoGrid uses:

```
0°   = South
90°  = East
180° = North
270° = West
```

The workflow therefore creates:

```
ASPECT_CryoGrid/
```

containing:

```
ASPECT_CryoGrid_massif_XX.tif
```

The original physical aspect products are preserved.

---

# IGN WMS limits

Large WMS requests can fail.

The workflow limits requests to:

```
4000 × 4000 pixels
```

Large massifs are automatically subdivided.

Downloaded chunks are stored in:

```
DEM/cache/
```

and reused during restart.

---

# Quality-control diagnostics

Diagnostics are generated using:

```matlab
run_lidar_diagnostics()
```

Example:

```matlab
run_lidar_diagnostics( ...
    "CryoGridCommunity_forcing/DEM/LiDAR_HD_DEM_10m", ...
    "CryoGridCommunity_forcing/meteo/SAFRAN/shapefile/massifs_alpes_2154.shp")
```

The workflow:

- validates massif DEMs
- creates massif overview figures
- plots missing DEM pixels
- generates validation tables
- automatically detects available Alpine topographic products

Any product following:

```
PRODUCT/

└── ALPS/

    └── PRODUCT_ALPS.tif
```

is automatically plotted.

Examples:

```
DEM/ALPS/DEM_ALPS.tif
SLOPE/ALPS/SLOPE_ALPS.tif
ASPECT/ALPS/ASPECT_ALPS.tif
```

Diagnostics include:

```
LiDAR_HD_DEM_massifs.png

LiDAR_HD_<PRODUCT>_ALPS_overview.png

LiDAR_HD_DEM_missing_pixels.png

LiDAR_HD_DEM_validation.csv

LiDAR_HD_DEM_validation.md
```

---

# Diagnostics figures

Example outputs are stored in:

```
diagnostics/
```

and copied into the workflow repository for direct README display.

## DEM overview

![LiDAR DEM overview](diagnostics/LiDAR_HD_DEM_massifs.png)

Shows:

- SAFRAN massif DEMs
- common elevation scale
- massif boundaries
- massif numbers

---

## Alpine topography overview

![LiDAR Alpine DEM overview](diagnostics/LiDAR_HD_DEM_ALPS_overview.png)

The same workflow can display any Alpine product:

```
DEM/ALPS/DEM_ALPS.tif

SLOPE/ALPS/SLOPE_ALPS.tif

ASPECT/ALPS/ASPECT_ALPS.tif
```

---

## Missing LiDAR pixels

![Missing LiDAR pixels](diagnostics/LiDAR_HD_DEM_missing_pixels.png)

Shows pixels where:

- the location is inside a SAFRAN massif
- no valid LiDAR elevation exists

---

# Validation table

Generated files:

```
diagnostics/

├── LiDAR_HD_DEM_validation.csv
└── LiDAR_HD_DEM_validation.md
```

Markdown table:

[LiDAR DEM validation table](diagnostics/LiDAR_HD_DEM_validation.md)

CSV file:

[LiDAR DEM validation CSV](diagnostics/LiDAR_HD_DEM_validation.csv)

Variables:

| Variable | Description |
|---|---|
| massif | SAFRAN massif number |
| DEM_pixels | Number of pixels inside massif |
| missing_pixels | Pixels without valid elevation |
| missing_percentage | Percentage missing |

---

# MATLAB functions

## Main workflow

| Function | Description |
|---|---|
| [`prepare_dem.m`](./prepare_dem.m) | Complete DEM workflow |
| [`run_lidar_diagnostics.m`](./run_lidar_diagnostics.m) | Quality-control workflow |

---

## Processing utilities

Located in:

```
processing/
```

| Function | Description |
|---|---|
| [`download_lidar_chunk.m`](./processing/download_lidar_chunk.m) | Download IGN WMS tiles |
| [`clean_lidar_chunk.m`](./processing/clean_lidar_chunk.m) | Remove WMS artefacts |
| [`split_dem_bbox.m`](./processing/split_dem_bbox.m) | Split large requests |
| [`merge_dem_chunks.m`](./processing/merge_dem_chunks.m) | Merge DEM chunks |
| [`clip_dem_polygon.m`](./processing/clip_dem_polygon.m) | Clip to SAFRAN polygon |
| [`write_dem_geotiff.m`](./processing/write_dem_geotiff.m) | Write GeoTIFF outputs |
| [`merge_massif_DEMs.m`](./processing/merge_massif_DEMs.m) | Merge massif DEMs into Alpine DEM |
| [`compute_dem_derivatives.m`](./processing/compute_dem_derivatives.m) | Compute slope and aspect |
| [`clip_topography_products.m`](./processing/clip_topography_products.m) | Clip terrain products to massifs |
| [`convert_aspect_to_cryogrid.m`](./processing/convert_aspect_to_cryogrid.m) | Convert aspect convention |

---

# Notes

* The workflow is fully restartable.
* Preserve the `cache/` folder.
* Terrain derivatives are computed from the Alpine DEM before clipping.
* Physical aspect products are preserved.
* CryoGrid aspect conversion is stored separately.
* Generated DEM products are excluded from Git.
* The workflow currently targets the French Alps SAFRAN massif domain.