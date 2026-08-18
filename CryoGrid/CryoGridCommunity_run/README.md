# CryoGridCommunity_run

This folder is the **user-facing entry point** for the CryoGrid VP workflow.

The workflow is divided into two parts:

1. **Preparation** — build all required meteorological, topographic, and geological input data.
2. **Simulation** — run CryoGrid using the prepared datasets.

## 1. Configure the workflow

Copy:

[`VP_config_template.m`](./VP_config_template.m)

to:

[`VP_config.m`](./VP_config.m)

and edit the user-specific settings.

`VP_config.m` contains the paths and configuration required by the workflow. It is intentionally ignored by Git because it contains local machine-specific information.

## 2. Prepare the datasets

Run:

[`prepare_VP.m`](./prepare_VP.m)

from MATLAB:

```matlab
prepare_VP
```

This automatically initializes the CryoGrid VP paths and runs:

1. **VP_Meteo** — [`source/VP_Meteo/`](../CryoGridCommunity_source/source/VP_Meteo/) — SAFRAN/S2M and ERA5 forcing
2. **VP_DEM** — [`source/VP_DEM/`](../CryoGridCommunity_source/source/VP_DEM/) — DEM, terrain derivatives, and SVF
3. **VP_Geol** — [`source/VP_Geol/`](../CryoGridCommunity_source/source/VP_Geol/) — BRGM geology and CryoGrid validity masks

The preparation workflow is restartable and skips products that already exist.

## 3. Run CryoGrid

After preparation, the resulting datasets can be used to run CryoGrid.

The current entry point is:

[`run_spatial.m`](./run_spatial.m)

```matlab
run_spatial
```

The exact simulation workflow and user interface are **work in progress** and will evolve as the VP workflow is developed.

For now, [`run_spatial.m`](./run_spatial.m) should be considered the starting point for the actual CryoGrid simulation after [`prepare_VP.m`](./prepare_VP.m) has completed.

## Recommended workflow

```matlab
prepare_VP
run_spatial
```

Users should normally not need to interact directly with the individual functions in [`CryoGridCommunity_source/source/`](../CryoGridCommunity_source/source/). Those functions remain available for advanced or standalone use.