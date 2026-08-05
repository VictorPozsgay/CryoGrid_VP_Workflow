# BRGM GEO050K_HARM Geology Processing

## Overview

This workflow prepares geological datasets from the **BRGM GEO050K_HARM S_FGEOL** harmonized geological database for use in CryoGrid mountain permafrost simulations.

The workflow:

- downloads the required BRGM department datasets,
- merges geological polygons covering the French Alps,
- builds geological unit inventories,
- rasterizes geological units onto CryoGrid DEM grids,
- creates a reduced inventory containing only geological units present within the modelling domain.

The final products provide a spatial geological classification consistent with the CryoGrid DEM grids.

---

## Data source

The workflow uses:

**BRGM GEO050K_HARM - Carte géologique harmonisée à 1/50 000**

The original data are provided as department-level shapefiles:

- Lambert-93 projection (EPSG:2154)
- polygon geological units
- BRGM geological notation (`NOTATION`)

The workflow downloads only the departments required for the French Alps.

---

## Folder structure

The expected structure is:

```
BRGM_GEO050K_HARM/

├── raw/
│   ├── 004/
│   ├── 005/
│   ├── ...
│   └── 074/
│
├── processed/
│   ├── BRGM_GEO050K_HARM_ALPES.mat
│   ├── BRGM_GEO050K_HARM_inventory.mat
│   ├── BRGM_GEO050K_HARM_raster_inventory.mat
│   │
│   └── raster/
│       ├── GEOLOGY_massif_01.tif
│       ├── GEOLOGY_massif_02.tif
│       └── ...
│
└── README.md
```

---

## Workflow

The complete processing chain is executed with:

```matlab
prepare_geology(forcing_path, dem_folder)
```

The workflow is restartable. Each processing step checks whether its output already exists and skips completed steps.

---

## Processing steps

### 1. Download BRGM datasets

Function:

```matlab
download_BRGM()
```

Downloads the required department shapefiles.

Current departments:

```
04  Alpes-de-Haute-Provence
05  Hautes-Alpes
06  Alpes-Maritimes
26  Drôme
38  Isère
73  Savoie
74  Haute-Savoie
```

The downloaded data are preserved unchanged in `raw/`.

---

### 2. Merge geological polygons

Function:

```matlab
merge_BRGM_departments()
```

Combines all department shapefiles into a single Alpine dataset:

```
processed/BRGM_GEO050K_HARM_ALPES.mat
```

The merged dataset contains:

- polygon geometry,
- BRGM geological notation,
- geological descriptions,
- source attributes.

---

### 3. Build geological inventory

Function:

```matlab
build_BRGM_inventory()
```

Creates:

```
processed/BRGM_GEO050K_HARM_inventory.mat
```

The inventory contains all geological units present in the merged BRGM dataset.

Each geological unit is identified by:

- `ID`
- `NOTATION`
- `DESCR`
- number of polygons
- total mapped area

`NOTATION` is used as the geological unit identifier.

---

### 4. Rasterize geology

Function:

```matlab
rasterize_BRGM_geology()
```

Projects geological polygons onto CryoGrid DEM grids.

Output:

```
processed/raster/

GEOLOGY_massif_XX.tif
```

Raster properties:

- identical grid geometry to the DEM,
- identical spatial extent,
- Lambert-93 projection,
- integer geological IDs,
- `-9999` used as no-data value.

Raster values correspond to the IDs stored in:

```
BRGM_GEO050K_HARM_inventory.mat
```

---

### 5. Build raster-domain inventory

Function:

```matlab
build_BRGM_raster_inventory()
```

Creates:

```
processed/BRGM_GEO050K_HARM_raster_inventory.mat
```

This reduced inventory contains only geological units that occur inside the CryoGrid raster domain.

Units present only outside the modelling area are removed. This can happen because the source departments extend beyond the Alpine massifs and include low-elevation or non-mountain regions.

The complete BRGM inventory is preserved separately.

---

## Output usage

The geological raster can be loaded together with the DEM:

```matlab
[GEO,R] = readgeoraster("GEOLOGY_massif_01.tif");
[Z,Rz] = readgeoraster("DEM_massif_01.tif");
```

The grids are aligned:

- identical dimensions,
- identical spatial limits,
- identical projection.

The geological IDs can be linked to geological properties through:

```
BRGM_GEO050K_HARM_raster_inventory.mat
```

---

## Requirements

MATLAB toolboxes:

- Mapping Toolbox
- Image Processing Toolbox (required for some raster operations)

---

## Notes

- Raw BRGM data are preserved unchanged in `raw/`.
- Intermediate products are stored in `processed/`.
- All processing steps are restartable.
- Geological IDs remain consistent with the original BRGM inventory for traceability.