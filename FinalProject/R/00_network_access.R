# =============================================================================
# 00_network_access.R — Pre-compute walking travel times via street network
#
# Standalone script (run once). Uses dodgr to compute a walking-time matrix
# between neighbourhood centroids and all POIs. The main pipeline reads the
# cached result from data/04_network/walk_times.rds.
#
# Requirements: dodgr, osmextract, sf (no Java needed)
# Output:       data/04_network/walk_times.rds  (73 x ~28k numeric matrix, seconds)
# =============================================================================

# --- 0. Setup ----------------------------------------------------------------

required_pkgs <- c("dodgr", "osmextract", "sf")
new_pkgs <- required_pkgs[!(required_pkgs %in% installed.packages()[, "Package"])]
if (length(new_pkgs)) install.packages(new_pkgs)

library(dodgr)
library(osmextract)
library(sf)

net_dir <- file.path("data", "04_network")
if (!dir.exists(net_dir)) dir.create(net_dir, recursive = TRUE)

cat("=== Walking Network Pre-computation ===\n\n")

# --- 1. Download Barcelona street network ------------------------------------

cat("[1/5] Downloading Barcelona street network (BBBike PBF)...\n")

pbf_path <- file.path(net_dir, "Barcelona.osm.pbf")

if (!file.exists(pbf_path)) {
  download.file(
    url = "https://download.bbbike.org/osm/bbbike/Barcelona/Barcelona.osm.pbf",
    destfile = pbf_path,
    mode = "wb"
  )
  cat(sprintf("   Downloaded: %s (%.1f MB)\n", pbf_path,
              file.size(pbf_path) / 1e6))
} else {
  cat(sprintf("   Already present: %s (%.1f MB)\n", pbf_path,
              file.size(pbf_path) / 1e6))
}

# --- 2. Read and weight the street network -----------------------------------

cat("[2/5] Reading and weighting street network for walking...\n")

# Read the lines layer (roads/paths) from the PBF
sf_roads <- oe_read(
  pbf_path,
  layer = "lines",
  quiet = TRUE,
  extra_tags = c("foot", "sidewalk", "footway", "access")
)

cat(sprintf("   Road segments read: %d\n", nrow(sf_roads)))

# Weight for pedestrian routing
graph <- weight_streetnet(sf_roads, wt_profile = "foot")
cat(sprintf("   Graph edges: %d\n", nrow(graph)))

# Contract graph (removes degree-2 nodes for speed)
graph_c <- dodgr_contract_graph(graph)
cat(sprintf("   Contracted graph edges: %d\n", nrow(graph_c)))

# --- 3. Prepare origins and destinations -------------------------------------

cat("[3/5] Preparing origin and destination coordinates...\n")

# Load neighbourhood boundaries and POIs using the same logic as the pipeline
# (we need 01_setup.R constants but avoid sourcing the full pipeline)
crs_proj <- "EPSG:25831"

# Read boundaries
barris_file <- file.path("data", "01_boundaries", "bcn_barris.csv")
stopifnot("Barris file not found" = file.exists(barris_file))

sf_nbhoods <- readr::read_csv(barris_file, show_col_types = FALSE) |>
  st_as_sf(wkt = "geometria_wgs84", crs = 4326) |>
  st_transform(crs_proj)
st_geometry(sf_nbhoods) <- "geometry"

# Centroids in WGS84 (dodgr needs lon/lat)
centroids_proj <- st_centroid(st_geometry(sf_nbhoods))
centroids_wgs <- st_transform(centroids_proj, 4326)
from_coords <- st_coordinates(centroids_wgs)  # matrix: lon, lat
cat(sprintf("   Origins (centroids): %d\n", nrow(from_coords)))

# Load POIs
poi_file <- file.path("data", "03_pois", "poi_all_combined.gpkg")
stopifnot("POI file not found" = file.exists(poi_file))
sf_pois <- st_read(poi_file, quiet = TRUE)

# Also load convenience and greengrocer
for (extra in c("poi_convenience.gpkg", "poi_greengrocer.gpkg")) {
  extra_path <- file.path("data", "03_pois", extra)
  if (file.exists(extra_path)) {
    sf_extra <- st_read(extra_path, quiet = TRUE) |>
      dplyr::mutate(category = "supermarket") |>
      dplyr::select(osm_id, name, category)
    sf_pois <- dplyr::bind_rows(sf_pois, sf_extra)
  }
}
sf_pois <- dplyr::distinct(sf_pois, osm_id, .keep_all = TRUE)

# Transform POIs to WGS84
pois_wgs <- st_transform(sf_pois, 4326)
to_coords <- st_coordinates(pois_wgs)  # matrix: lon, lat
cat(sprintf("   Destinations (POIs): %d\n", nrow(to_coords)))

# --- 4. Compute walking time matrix -----------------------------------------

cat("[4/5] Computing walking time matrix (this may take a few minutes)...\n")

t0 <- Sys.time()
time_mat <- dodgr_times(graph_c, from = from_coords, to = to_coords)
elapsed <- as.numeric(difftime(Sys.time(), t0, units = "secs"))

# Convert seconds to minutes
time_mat <- time_mat / 60

cat(sprintf("   Done in %.1f seconds\n", elapsed))
cat(sprintf("   Matrix dimensions: %d origins x %d destinations\n",
            nrow(time_mat), ncol(time_mat)))

n_reachable <- sum(!is.na(time_mat))
n_total <- length(time_mat)
cat(sprintf("   Reachable pairs: %d / %d (%.1f%%)\n",
            n_reachable, n_total, 100 * n_reachable / n_total))

# Quick sanity check: median walking time for reachable pairs
med_time <- median(time_mat, na.rm = TRUE)
cat(sprintf("   Median walking time (reachable pairs): %.1f min\n", med_time))

# --- 5. Save results ---------------------------------------------------------

cat("[5/5] Saving results...\n")

# Save the full walking time matrix (minutes)
walk_times_path <- file.path(net_dir, "walk_times.rds")
saveRDS(time_mat, walk_times_path)
cat(sprintf("   Saved: %s (%.1f MB)\n", walk_times_path,
            file.size(walk_times_path) / 1e6))

# Also save a summary: access counts at 10 and 15 minutes per neighbourhood
access_15 <- rowSums(time_mat <= 15, na.rm = TRUE)
access_10 <- rowSums(time_mat <= 10, na.rm = TRUE)
cat(sprintf("   15-min walk access: min=%d, max=%d, mean=%.0f\n",
            min(access_15), max(access_15), mean(access_15)))
cat(sprintf("   10-min walk access: min=%d, max=%d, mean=%.0f\n",
            min(access_10), max(access_10), mean(access_10)))

cat("\n=== Done. The main pipeline will use data/04_network/walk_times.rds ===\n")
