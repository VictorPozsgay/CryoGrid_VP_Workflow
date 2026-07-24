# IGN LiDAR HD DEM workflow (10 m)

Last revision July 2026 (Pozsgay V.)

This folder contains the MATLAB workflow used to download, process and validate **IGN LiDAR HD elevation data** for CryoGrid applications in the French Alps.

The workflow can generate DEMs at user-defined spatial resolutions. The currently generated dataset stored in the repository uses a **10 m resolution**.

The workflow produces:

- one DEM GeoTIFF per SAFRAN massif
- one binary polygon mask per massif
- quality-control diagnostics

The generated data are stored separately from the scripts:

```
forcing/
├── DEM_Script_VP/
│   └── LiDAR_HD_DEM/
│       └── (MATLAB workflow)
│
└── Forcing_Data/
    └── LiDAR_HD_DEM_10m/
        └── (generated DEM dataset)
```

---

# Overview

The workflow performs the following steps:

1. Reads SAFRAN massif polygons
2. Queries IGN LiDAR HD elevation data through the IGN WMS service
3. Automatically splits large requests into smaller chunks
4. Downloads and caches individual tiles
5. Merges tiles while prioritising valid elevation data
6. Clips DEMs to SAFRAN massif boundaries
7. Saves DEM and mask GeoTIFF files
8. Generates automatic quality-control diagnostics

The resulting DEMs are designed as topographic inputs for CryoGrid simulations.

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

# Spatial resolution

The workflow supports arbitrary output resolution.

The requested resolution is controlled using the `Resolution` option of:

```matlab
build_lidar_hd_dem()
```

Example: generate 5 m DEMs:

```matlab
build_lidar_hd_dem( ...
    "massifs_alpes_2154.shp", ...
    "DEM", ...
    "Resolution",5)
```

The current stored dataset was generated using:

```matlab
"Resolution",10
```

and therefore contains:

```
10 m × 10 m pixels
```

in:

```
forcing/Forcing_Data/LiDAR_HD_DEM_10m/
```

The workflow automatically adapts the WMS request size according to the requested resolution. Large SAFRAN massifs are divided into smaller chunks to respect IGN service limitations.

---

# Input data

The main input is the SAFRAN massif shapefile:

```
shapefile_massifs_SAFRAN/

└── massifs_alpes_2154.shp
```

The shapefile must:

- be projected in Lambert-93 (EPSG:2154)
- contain the attribute:

```
massif_num
```

which identifies each SAFRAN massif.

---

# DEM generation

The main workflow is:

```matlab
build_lidar_hd_dem()
```

Example:

```matlab
build_lidar_hd_dem( ...
    "../../Forcing_Data/LiDAR_HD_DEM_10m/shapefile_massifs_SAFRAN/massifs_alpes_2154.shp", ...
    "../../Forcing_Data/LiDAR_HD_DEM_10m/DEM")
```

The function supports:

## Resolution

Default:

```matlab
Resolution = 10
```

Example:

```matlab
build_lidar_hd_dem(...,"Resolution",20)
```

## Overwrite

Existing DEMs are preserved by default.

To rebuild:

```matlab
build_lidar_hd_dem(...,"Overwrite",true)
```

---

# Generated data

The output dataset is located at:

[LiDAR_HD_DEM_10m](/forcing/Forcing_Data/LiDAR_HD_DEM_10m/)

Structure:

```
LiDAR_HD_DEM_10m/

├── DEM/
│
│   ├── cache/
│   │   ├── massif_01/
│   │   │   ├── chunk_001.tif
│   │   │   └── ...
│   │   └── ...
│
│   ├── DEM_massif_01.tif
│   ├── DEM_massif_02.tif
│   └── ...
│
│   ├── DEM_mask_massif_01.tif
│   ├── DEM_mask_massif_02.tif
│   └── ...
│
├── diagnostics/
│
└── shapefile_massifs_SAFRAN/
```

---

# DEM files

Example:

```
DEM_massif_22.tif
```

Each DEM contains:

- elevation values in metres
- Lambert-93 coordinates
- user-defined resolution
- currently 10 m pixels

Pixels outside the SAFRAN polygon are stored as:

```
NaN
```

---

# Mask files

Example:

```
DEM_mask_massif_22.tif
```

The mask is independent from DEM availability.

Values:

| Value | Meaning |
|---|---|
| 1 | inside SAFRAN massif |
| 0 | outside SAFRAN massif |

The mask allows distinguishing:

- missing LiDAR data inside a massif
- areas outside the modelling domain

---

# Quality control

The complete diagnostic workflow is:

```matlab
run_lidar_diagnostics()
```

Example:

```matlab
run_lidar_diagnostics( ...
    "../../Forcing_Data/LiDAR_HD_DEM_10m/DEM", ...
    "../../Forcing_Data/LiDAR_HD_DEM_10m/shapefile_massifs_SAFRAN/massifs_alpes_2154.shp", ...
    "../../Forcing_Data/LiDAR_HD_DEM_10m/diagnostics")
```

Generated files:

```
diagnostics/

├── LiDAR_HD_DEM_massifs.png
├── LiDAR_HD_DEM_missing_pixels.png
└── LiDAR_HD_DEM_validation.csv
```

---

# Diagnostics figures

## DEM overview

![LiDAR DEM overview](/forcing/Forcing_Data/LiDAR_HD_DEM_10m/diagnostics/LiDAR_HD_DEM_massifs.png)

Shows:

- all available massif DEMs
- common elevation scale
- SAFRAN boundaries
- massif numbers

---

## Missing pixels

![Missing LiDAR pixels](/forcing/Forcing_Data/LiDAR_HD_DEM_10m/diagnostics/LiDAR_HD_DEM_missing_pixels.png)

Shows pixels where:

- the pixel is inside a SAFRAN massif
- no valid LiDAR elevation value exists

---

# Validation table

The file:

```
LiDAR_HD_DEM_validation.csv
```

contains one row per massif:

| Variable | Description |
|---|---|
| massif | SAFRAN massif number |
| DEM_pixels | Number of pixels inside polygon |
| missing_pixels | Missing elevation pixels |
| missing_percentage | Percentage missing |

and currently reads

![Missing LiDAR pixels](/forcing/Forcing_Data/LiDAR_HD_DEM_10m/diagnostics/LiDAR_HD_DEM_validation.csv)

---

# MATLAB functions

## Main workflow

| Function | Description |
|---|---|
| `build_lidar_hd_dem.m` | Generate DEMs |
| `run_lidar_diagnostics.m` | Run QC workflow |

---

## Processing utilities

Located in:

```
private/
```

| Function | Description |
|---|---|
| `download_lidar_chunk.m` | Download IGN WMS tiles |
| `split_dem_bbox.m` | Split large requests |
| `merge_dem_chunks.m` | Merge DEM tiles |
| `clip_dem_polygon.m` | Apply massif clipping |
| `write_dem_geotiff.m` | Write GeoTIFF outputs |

---

## Diagnostics utilities

| Function | Description |
|---|---|
| `plot_lidar_dem_base.m` | Create DEM plotting object |
| `plot_all_lidar_massifs.m` | Save DEM overview |
| `plot_lidar_missing_pixels.m` | Plot missing pixels |
| `validate_lidar_dem.m` | Generate validation table |

---

# Notes

- The `cache/` folder should be preserved to avoid repeated downloads.
- DEM generation requires multiple IGN WMS requests and can take significant time.
- The workflow currently targets SAFRAN massifs of the French Alps.
- Other polygon datasets can be used provided they are supplied in Lambert-93.