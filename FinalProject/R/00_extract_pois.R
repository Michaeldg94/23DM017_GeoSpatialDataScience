# =============================================================================
# 00_extract_pois.R — Standalone POI extraction from OpenStreetMap
# Geospatial Data Science — BSE
# =============================================================================
# Run this script ONCE to download POIs from the Overpass API and save them as
# GeoPackage files in data/03_pois/. The analysis pipeline (run_all.R) reads
# the resulting poi_all_combined.gpkg; it does NOT re-download.
#
# Output files (saved to data/03_pois/):
#   - poi_supermarkets.gpkg
#   - poi_pharmacies.gpkg
#   - poi_healthcare.gpkg
#   - poi_schools.gpkg
#   - poi_parks.gpkg
#   - poi_public_transport.gpkg
#   - poi_all_combined.gpkg
#   - poi_summary.csv              (count summary table)
#   - poi_map_by_category.png      (validation map)
# =============================================================================

# --- 0. Setup ----------------------------------------------------------------

# Install packages if not already installed
required_pkgs <- c("osmdata", "sf", "tidyverse", "tmap", "ragg")
new_pkgs <- required_pkgs[!(required_pkgs %in% installed.packages()[, "Package"])]
if (length(new_pkgs)) install.packages(new_pkgs)

library(osmdata)
library(sf)
library(tidyverse)
library(tmap)
library(ragg)

# Output directory for POI files
poi_dir <- file.path("data", "03_pois")
if (!dir.exists(poi_dir)) dir.create(poi_dir, recursive = TRUE)

cat("=== Barcelona POI Extraction ===\n\n")

# --- 1. Define Barcelona boundary -------------------------------------------

cat("[1/8] Fetching Barcelona bounding box and municipal boundary...\n")

bbox_bcn <- getbb("Barcelona, Spain")

bcn_polygon <- getbb("Barcelona, Spain", format_out = "sf_polygon")

# getbb returns multiple matches — city AND province
# Select the smallest one (the city, ~101 km²)
if (is.list(bcn_polygon) && !inherits(bcn_polygon, "sf")) {
  areas <- sapply(bcn_polygon, function(x) abs(as.numeric(st_area(st_as_sf(x)))))
  bcn_polygon <- bcn_polygon[[which.min(areas)]]
}

bcn_polygon <- bcn_polygon |>
  st_as_sf() |>
  st_set_crs(4326) |>
  st_make_valid() |>
  st_transform(25831)

# Keep only the city polygon (smallest area)
areas <- abs(as.numeric(st_area(bcn_polygon)))
bcn_polygon <- bcn_polygon[which.min(areas), ]

area_km2 <- as.numeric(st_area(bcn_polygon)) / 1e6
cat(sprintf("   Barcelona boundary retrieved. Area: %.1f km²\n\n", area_km2))

stopifnot("Boundary area looks wrong — expected ~101 km²" = area_km2 > 80 & area_km2 < 120)

# --- Helper function ---------------------------------------------------------
# Standardizes extraction: grabs both points and polygon centroids,
# clips to Barcelona boundary, and returns a clean sf object.

extract_pois <- function(key, value, category_name, bbox, boundary) {
  
  cat(sprintf("   Querying OSM: %s = %s ...\n", key, value))
  
  result <- opq(bbox = bbox, timeout = 120) |>   # <-- increase timeout to 120s
    add_osm_feature(key = key, value = value) |>
    osmdata_sf()
  
  # Extract points
  pts <- NULL
  if (!is.null(result$osm_points) && nrow(result$osm_points) > 0) {
    pts <- result$osm_points |>
      select(osm_id, name, geometry)
  }
  
  # Extract polygon centroids (many POIs are mapped as building footprints)
  poly_centroids <- NULL
  if (!is.null(result$osm_polygons) && nrow(result$osm_polygons) > 0) {
    poly_centroids <- result$osm_polygons |>
      st_centroid() |>
      select(osm_id, name, geometry)
  }
  
  # Combine points and polygon centroids
  combined <- bind_rows(pts, poly_centroids)
  
  if (is.null(combined) || nrow(combined) == 0) {
    cat(sprintf("   WARNING: No features found for %s = %s\n", key, value))
    return(NULL)
  }
  
  # Add category label, set CRS, project, and clip
  combined <- combined |>
    mutate(category = category_name) |>
    st_set_crs(4326) |>
    st_transform(25831) |>
    st_intersection(boundary) |>
    select(osm_id, name, category, geometry)
  
  cat(sprintf("   -> %d features extracted for '%s'\n", nrow(combined), category_name))
  return(combined)
}

# --- 2. Extract Supermarkets -------------------------------------------------

cat("[2/8] Extracting supermarkets...\n")

supermarkets <- extract_pois("shop", "supermarket", "supermarket", bbox_bcn, bcn_polygon)

Sys.sleep(10)  # Pause to avoid Overpass rate limits

# --- 3. Extract Pharmacies ---------------------------------------------------

cat("[3/8] Extracting pharmacies...\n")

pharmacies <- extract_pois("amenity", "pharmacy", "pharmacy", bbox_bcn, bcn_polygon)

Sys.sleep(60)

# --- 4. Extract Healthcare (clinics + doctors) --------------------------------

cat("[4/8] Extracting healthcare facilities...\n")

clinics <- extract_pois("amenity", "clinic", "healthcare", bbox_bcn, bcn_polygon)
Sys.sleep(5)

doctors <- extract_pois("amenity", "doctors", "healthcare", bbox_bcn, bcn_polygon)
Sys.sleep(60)

# Combine and deduplicate
healthcare <- bind_rows(clinics, doctors) |>
  distinct(osm_id, .keep_all = TRUE)

cat(sprintf("   -> %d total unique healthcare facilities\n", nrow(healthcare)))

# --- 5. Extract Schools -------------------------------------------------------

cat("[5/8] Extracting schools...\n")

schools <- extract_pois("amenity", "school", "school", bbox_bcn, bcn_polygon)

Sys.sleep(5)

# --- 6. Extract Parks / Green Spaces ------------------------------------------

cat("[6/8] Extracting parks and green spaces...\n")

parks <- extract_pois("leisure", "park", "park", bbox_bcn, bcn_polygon)

Sys.sleep(60)

# --- 7. Extract Public Transport Stops ----------------------------------------

cat("[7/8] Extracting public transport stops...\n")

pt_stops <- extract_pois("public_transport", "stop_position", "public_transport", bbox_bcn, bcn_polygon)
Sys.sleep(5)

bus_stops <- extract_pois("highway", "bus_stop", "public_transport", bbox_bcn, bcn_polygon)
Sys.sleep(60)

# Also grab metro/railway stations
metro <- extract_pois("railway", "station", "public_transport", bbox_bcn, bcn_polygon)

# Combine and deduplicate
public_transport <- bind_rows(pt_stops, bus_stops, metro) |>
  distinct(osm_id, .keep_all = TRUE)

cat(sprintf("   -> %d total unique transport stops\n", nrow(public_transport)))

# --- 8. Save individual + combined outputs ------------------------------------

cat("[8/8] Saving outputs...\n\n")

# List of individual POI datasets
poi_list <- list(
  supermarkets    = supermarkets,
  pharmacies      = pharmacies,
  healthcare      = healthcare,
  schools         = schools,
  parks           = parks,
  public_transport = public_transport
)

# Save each category as its own GeoPackage
for (name in names(poi_list)) {
  if (!is.null(poi_list[[name]]) && nrow(poi_list[[name]]) > 0) {
    filepath <- file.path(poi_dir, paste0("poi_", name, ".gpkg"))
    st_write(poi_list[[name]], filepath, delete_dsn = TRUE, quiet = TRUE)
    cat(sprintf("   Saved: %s (%d features)\n", filepath, nrow(poi_list[[name]])))
  }
}

# Combine all into one dataset
all_pois <- bind_rows(poi_list)
combined_filepath <- file.path(poi_dir, "poi_all_combined.gpkg")
st_write(all_pois, combined_filepath, delete_dsn = TRUE, quiet = TRUE)
cat(sprintf("   Saved: %s (%d total features)\n", combined_filepath, nrow(all_pois)))

# --- Summary table -----------------------------------------------------------

summary_df <- all_pois |>
  st_drop_geometry() |>
  count(category, name = "count") |>
  arrange(desc(count))

summary_filepath <- file.path(poi_dir, "poi_summary.csv")
write_csv(summary_df, summary_filepath)
cat(sprintf("   Saved: %s\n\n", summary_filepath))

cat("=== POI Count Summary ===\n")
print(as.data.frame(summary_df))
cat("\n")

# --- Validation map -----------------------------------------------------------

cat("Generating validation map...\n")

# tmap v4 syntax
map <- tm_shape(bcn_polygon) +
  tm_borders(col = "grey30", lwd = 1.5) +
  tm_shape(all_pois) +
  tm_dots(
    fill      = "category",
    size      = 0.04,
    fill.scale = tm_scale(values = "Set2"),
    fill.legend = tm_legend(title = "POI Category")
  ) +
  tm_title("Barcelona — OSM Points of Interest") +
  tm_layout(
    legend.outside = TRUE,
    frame          = FALSE
  )

# Use ragg backend instead of Cairo (works on Mac without X11)
map_filepath <- file.path(poi_dir, "poi_map_by_category.png")
tmap_save(map, filename = map_filepath, width = 10, height = 8, dpi = 200,
          device = ragg::agg_png)
cat(sprintf("   Saved: %s\n\n", map_filepath))