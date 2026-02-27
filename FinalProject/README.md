# 15-Minute City in Barcelona: Income and Access to Essential Services

Final project for the Geospatial Data Science course (BSE Data Science Methodology, 2025).

## Research Question

Do lower-income neighborhoods in Barcelona have worse access to essential services (healthcare, education, food, green spaces)?

## Approach

1. **Accessibility metric**: Count of POIs within a 1200m buffer per neighborhood, queried from OpenStreetMap via the Overpass API.
2. **Spatial analysis**: LISA clusters, Moran's I, and choropleth maps to identify spatial patterns.
3. **Econometric models**: OLS, SAR, SEM, SDM, and SDEM compared by AIC and LR tests. The Spatial Durbin Model (SDM) is the preferred specification, estimated with `spatialreg::lagsarlm(..., Durbin = TRUE)`.

## Data

All sourced from Barcelona Open Data and OpenStreetMap:

| File | Description |
|---|---|
| `data/bcn_barris.csv` | Neighborhood boundaries (polygons) |
| `data/renda_2022.csv` | Household income index by neighborhood (2022) |
| `data/poblacio_2025.csv` | Population by neighborhood (2025) |
| `data/pois_all.rds` | Cached POI geometries from OSM (gitignored; delete to re-download) |

## Files

- `final_project.R` — Full analysis script (data download, cleaning, modeling, plots).
- `final_project.Rmd` — R Markdown report combining narrative and code.

## Reproducing

Run `final_project.R` or knit `final_project.Rmd`. The first run downloads POIs from the Overpass API and caches them in `data/pois_all.rds`; subsequent runs use the cache.

Requires R with: `sf`, `spdep`, `spatialreg`, `osmdata`, `tidyverse`, `viridis`, `patchwork`, and others loaded via `pacman::p_load()`.
