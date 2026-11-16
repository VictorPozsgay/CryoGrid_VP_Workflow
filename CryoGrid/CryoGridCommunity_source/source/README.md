# Terrain scales relevant to mountain snow processes

## Main takeaway

For improving the CryoGrid `LAT_SNOW_CROCUS_wind_drift` parameterization, the literature suggests separating two terrain scales:

\[
\boxed{\text{TPI} \approx 25\text{–}30\ \mathrm{m}}
\]

for **local snow accumulation/depletion associated with ridges, hollows and small terrain features**, and

\[
\boxed{S_x \approx 200\text{–}300\ \mathrm{m}}
\]

for **directional wind exposure and snow redistribution**.

This fits the intended modelling approach:

- independent **1-D simulations**;
- no lateral coupling between DEM pixels;
- no explicit snow source–sink redistribution;
- terrain variables act only as **local modifiers of wind-driven snow transport/deposition**.

---

## 1. Topographic Position Index (TPI)

TPI is defined as

\[
TPI=z_{\mathrm{pixel}}-\overline{z}_{\mathrm{neighbourhood}}
\]

where \(z_{\mathrm{pixel}}\) is the elevation of the target pixel and \(\overline{z}_{\mathrm{neighbourhood}}\) is the mean elevation within a surrounding neighbourhood.

Therefore:

- **TPI > 0** → local high / ridge
- **TPI < 0** → local low / depression
- **TPI ≈ 0** → elevation similar to the surroundings

TPI is scale-dependent: changing the neighbourhood changes which terrain features are represented.

---

## 2. Relevant TPI scale for mountain snow

The strongest evidence points to a **local snow–terrain scale of roughly 15–40 m**, with approximately **25 m** being a particularly well-supported value.

### Key evidence

**Revuelto et al. (2014)** studied snow-depth distribution in the Spanish Pyrenees and found TPI to be one of the strongest terrain predictors, with an approximately **25 m search distance** providing the best performance.

**Mendoza et al. (2020)** independently analysed **24 snow-depth maps covering six winters** in the same general Pyrenean environment. Their spatial-scaling analysis identified a short-range snow-depth scale break close to **25 m**, consistent with the earlier TPI result.

Other mountain studies support the same order of magnitude:

- **Deems et al. (2006):** snow-depth scale breaks of approximately **15–40 m** in Colorado.
- **Deems et al. (2008):** approximately **15 m and 40 m** scale breaks at two Colorado mountain sites, with similar patterns between years.
- **Trujillo et al. (2007):** snow-depth scaling breaks approximately **7–45 m** across five mountain sites.
- **Cristea et al. (2017):** effective TPI neighbourhoods of approximately **27 m at 3 m resolution** and **60 m at 30 m resolution**.

### Working choice for the 10 m Alpine DEM

\[
\boxed{TPI_{25m}}
\]

A reasonable sensitivity range would be approximately **15–40 m**.

---

## 3. Directional \(S_x\): a larger scale

A second, substantially larger spatial scale appears to be associated with **wind exposure and redistribution** rather than local terrain position.

Mendoza et al. (2020) identified a second snow-depth scale of approximately

\[
\boxed{185\text{–}300\ \mathrm{m}}
\]

and found that this larger-scale structure was aligned with the dominant wind direction.

This is consistent with the use of the Winstral-style \(S_x\) terrain-exposure metric.

### Conceptual distinction

| Metric | Approximate scale | Main interpretation |
|---|---:|---|
| **TPI** | ~25 m | Local ridge/depression |
| **\(S_x\)** | ~200–300 m | Directional wind exposure/shelter |

TPI and \(S_x\) should therefore be treated as **complementary**, not interchangeable.

---

## 4. Proposed research direction for CryoGrid

A simple, literature-based starting point is:

\[
\boxed{
\text{terrain effect}
=
f(TPI_{25m}, S_x^{200-300m}, U, \theta)
}
\]

where:

- \(TPI_{25m}\) = local terrain position;
- \(S_x\) = terrain exposure in the actual wind direction;
- \(U\) = SAFRAN wind speed;
- \(\theta\) = SAFRAN wind direction.

The simulations remain completely independent 1-D simulations. No lateral snow transport between DEM cells is required.

### Proposed workflow

1. Compute **\(TPI_{25m}\)** from the 10 m DEM.
2. Compute directional **\(S_x\)** over approximately 200–300 m.
3. At each timestep, use the actual SAFRAN wind direction to select the appropriate \(S_x\).
4. Investigate how TPI and \(S_x\) should modify the existing `LAT_SNOW_CROCUS_wind_drift` formulation.
5. Validate the resulting parameterization against available snow observations.
6. Only introduce additional spatial scales if the observations show that they are necessary.

The literature provides evidence for the **spatial scales**, but it does **not** provide a universal equation converting TPI or \(S_x\) into a snow-drift coefficient. That relationship therefore needs to be investigated and calibrated for the CryoGrid application.

---

## 5. Key references

1. **Revuelto, J. et al. (2014).**  
   *Topographic control of snowpack distribution in a small catchment in the central Spanish Pyrenees: intra- and inter-annual persistence.*  
   **The Cryosphere, 8, 1989–2006.**  
   Key reference for the approximately **25 m TPI scale**.

2. **Mendoza, P. A. et al. (2020).**  
   *Interannual and Seasonal Variability of Snow Depth Scaling Behavior in a Subalpine Catchment.*  
   **Water Resources Research.**  
   Analyses 24 snow-depth maps over six winters; identifies an approximately **25 m short-range scale** and a **185–300 m wind-aligned scale**.  
   https://doi.org/10.1029/2020WR027343

3. **Deems, J. S., Fassnacht, S. R. & Elder, K. J. (2006).**  
   *Fractal Distribution of Snow Depth from LiDAR Data.*  
   **Journal of Hydrometeorology, 7, 285–297.**  
   Evidence for approximately **15–40 m** snow-depth scale breaks in Colorado mountain terrain.

4. **Deems, J. S., Fassnacht, S. R. & Elder, K. J. (2008).**  
   *Interannual consistency in fractal snow depth patterns at two Colorado mountain sites.*  
   **Journal of Hydrometeorology, 9, 977–988.**  
   Evidence for approximately **15 m and 40 m** scale breaks that persisted between years.

5. **Trujillo, E., Ramírez, J. A. & Elder, K. J. (2007).**  
   *Topographic, meteorologic, and canopy controls on the scaling characteristics of the spatial distribution of snow depth fields.*  
   **Water Resources Research, 43, W07409.**  
   Finds snow-depth scaling breaks approximately between **7 and 45 m** across five mountain sites.  
   https://doi.org/10.1029/2006WR005317

6. **Cristea, N. C. et al. (2017).**  
   *An evaluation of terrain-based downscaling of fractional snow covered area datasets based on LiDAR-derived snow data and orthoimagery.*  
   **Water Resources Research.**  
   Finds effective TPI neighbourhoods of approximately **27 m at 3 m resolution** and **60 m at 30 m resolution**.  
   https://doi.org/10.1002/2017WR020799

7. **Mendoza, P. A. et al. (2020).**  
   *Spatial Distribution and Scaling Properties of Lidar-Derived Snow Depth in the Extratropical Andes.*  
   **Water Resources Research.**  
   Provides independent evidence for multiscale snow-depth structure in mountain terrain.

---

## Bottom line

For the next CryoGrid research step, use:

\[
\boxed{TPI_{25m}}
\]

as the initial representation of **local terrain position**, and

\[
\boxed{S_x\ \text{at approximately}\ 200\text{–}300\,m}
\]

as the initial representation of **directional wind exposure**.

These are **literature-based starting hypotheses**, not yet validated CryoGrid parameterizations.