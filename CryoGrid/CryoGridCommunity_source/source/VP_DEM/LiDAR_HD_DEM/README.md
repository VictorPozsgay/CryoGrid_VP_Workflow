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