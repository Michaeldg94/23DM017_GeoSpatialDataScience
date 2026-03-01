# =============================================================================
# run_all.R — Master script: sources each analysis step in order
#
# Course: Geospatial Data Sciences and Economic Spatial Models (BSE)
# Final Project - March 2026
#
# NOTE: R/00_extract_pois.R is a standalone data-preparation script that
#       downloads POIs from OpenStreetMap and saves them as GeoPackage files.
#       It only needs to run once; the analysis pipeline below reads the
#       resulting data/03_pois/poi_all_combined.gpkg.
# =============================================================================

source("R/01_setup.R")
source("R/02_data.R")
source("R/03_wrangling.R")
source("R/04_eda.R")
source("R/05_spatial.R")
source("R/06_models.R")
source("R/07_extensions.R")
source("R/08_temporal.R")
source("R/09_results.R")
