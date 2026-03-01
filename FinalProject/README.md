# Is the Grass Greener Next Door? Evidence from Walking Accessibility in Barcelona

Final project for **Geospatial Data Sciences and Economic Spatial Models**
(BSE Data Science Methodology, March 2026).

**Authors:** Sebastian Dong Uk Paik Sohn, Michael Duarte Goncalves, Gal-la Gelpi Buxade, Maria Victoria Suriel Nunez.

## Research Question

Do lower-income neighbourhoods in Barcelona have worse walking access to essential services (healthcare, schools, groceries, parks, pharmacies, public transit)?

## Approach

1. **Accessibility metric** -- Count of POIs reachable within a 15-minute walk along the street network (`dodgr` routing engine on OpenStreetMap road data), plus a gravity-weighted alternative. Falls back to Euclidean 1,200 m buffers if network data is unavailable.
2. **Spatial analysis** -- Moran's I, LISA cluster maps, and choropleth maps to identify spatial patterns.
3. **Econometric models** -- OLS, SAR, SEM, SDM, and SDEM compared by AIC and likelihood-ratio tests.
4. **Extensions** -- Per-capita adequacy, category-specific regressions, gravity-weighted accessibility, Harris (1954) market-access potential, Gini/Lorenz inequality analysis, income evolution (2015--2022) with convergence tests, Euclidean vs. network distance comparison.

## Project Structure

```
FinalProject/
|-- run_all.R                                       Master script
|-- R/
|   |-- 00_extract_pois.R                           Standalone: download POIs from OSM (run once)
|   |-- 00_network_access.R                         Standalone: pre-compute walking times (run once)
|   |-- 01_setup.R                                  Packages, paths, constants, helpers
|   |-- 02_data.R                                   Load boundaries, income, population, POIs
|   |-- 03_wrangling.R                              Area, centroids, accessibility scores, joins
|   |-- 04_eda.R                                    Summary statistics, Figures 1-4, 7
|   |-- 05_spatial.R                                Spatial weights, Moran's I, LISA, Figures 5-6
|   |-- 06_models.R                                 OLS, SAR, SEM, SDM, SDEM, impacts
|   |-- 07_extensions.R                             Robustness, gravity, Gini/Lorenz, Figures 8-11
|   |-- 08_temporal.R                               Income evolution 2015-2022, Figures 12-14
|   |-- 09_results.R                                Assemble results list, save RDS
|-- data/
|   |-- 01_boundaries/
|   |   |-- bcn_barris.csv                          Neighbourhood polygons (WKT)
|   |-- 02_socioeconomic/
|   |   |-- renda_2015.csv ... renda_2022.csv       Household income per capita, 2015-2022
|   |   |-- poblacio_2025.csv                       Population by neighbourhood, 2025
|   |-- 03_pois/
|   |   |-- poi_all_combined.gpkg                   All POIs combined (used by the analysis)
|   |   |-- poi_summary.csv                         POI counts per category
|   |   |-- poi_healthcare.gpkg ... poi_*.gpkg      Individual category POI files
|   |-- 04_network/
|       |-- Barcelona.osm.pbf                       OSM street data (downloaded by 00_network_access.R)
|       |-- walk_times.rds                           73 x ~28k walking time matrix (minutes)
|-- output/                                         Generated figures (PDF) and results.rds
|-- GeoSpatial-FinalProject_Dong_Duarte_Gelpi_Suriel.Rmd   Report
|-- GeoSpatial-FinalProject_Dong_Duarte_Gelpi_Suriel.pdf   Compiled report
```

## Data Sources

| File | Source | Description |
|---|---|---|
| `bcn_barris.csv` | [Barcelona Open Data](https://opendata-ajuntament.barcelona.cat) | Neighbourhood boundaries (73 *barris*), WKT polygons in WGS 84 |
| `renda_2015.csv` ... `renda_2022.csv` | Barcelona Open Data | Disposable household income per capita by census section, 2015--2022 (downloaded automatically) |
| `poblacio_2025.csv` | Barcelona Open Data | Municipal population register (*padro*), 2025 |
| `poi_all_combined.gpkg` | OpenStreetMap (pre-processed) | 27,546 essential-service POIs across 6 categories, projected to EPSG:25831 |
| `Barcelona.osm.pbf` | [BBBike](https://download.bbbike.org/osm/bbbike/Barcelona/) | OpenStreetMap street network for Barcelona (~64 MB, downloaded by `00_network_access.R`) |

The individual POI GeoPackage files (`poi_healthcare.gpkg`, `poi_parks.gpkg`, etc.) contain the same data split by category. The analysis reads only `poi_all_combined.gpkg` (plus `poi_convenience.gpkg` and `poi_greengrocer.gpkg` for the extended grocery category).

## Reproducing

```bash
cd FinalProject

# Optional: pre-compute walking times (requires dodgr, osmextract; ~4 sec)
Rscript R/00_network_access.R

# Run the full analysis pipeline
Rscript run_all.R
```

Then knit the report:

```r
rmarkdown::render("GeoSpatial-FinalProject_Dong_Duarte_Gelpi_Suriel.Rmd")
```

`run_all.R` sources the nine scripts in `R/` sequentially. Boundaries, income, and population CSVs are downloaded automatically if missing; POIs must be present as `data/03_pois/poi_all_combined.gpkg`. If `data/04_network/walk_times.rds` exists (produced by `00_network_access.R`), the pipeline uses network-based walking times; otherwise it falls back to Euclidean 1,200 m buffers.

## Dependencies

All loaded via `pacman::p_load()`:

`sf`, `dplyr`, `tidyr`, `readr`, `stringr`, `ggplot2`, `spdep`, `spatialreg`, `viridis`, `patchwork`, `scales`, `units`.

For network-based walking distances (optional): `dodgr`, `osmextract`.
