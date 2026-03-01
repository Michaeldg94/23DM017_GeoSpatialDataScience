# =============================================================================
# 03_wrangling.R — Compute area, centroids, accessibility scores, join data
#
# If data/04_network/walk_times.rds exists (produced by 00_network_access.R),
# accessibility is measured via actual walking times on the street network.
# Otherwise, falls back to Euclidean 1,200 m buffers.
# =============================================================================

# Area and centroids ----

sf_nbhoods$area_km2 <- as.numeric(st_area(sf_nbhoods)) / 1e6
centroid_sfc <- st_centroid(st_geometry(sf_nbhoods))

# Distance to city centre ----

sf_nbhoods$dist_center_km <- as.numeric(
  st_distance(centroid_sfc, pt_center, by_element = FALSE)[, 1]
) / 1000

# Accessibility score ----

walk_times_path <- file.path(data_dir, "04_network", "walk_times.rds")
use_network <- file.exists(walk_times_path)

if (use_network) {

  message("Using network-based walking times for accessibility")
  walk_time_mat <- readRDS(walk_times_path)  # minutes, 73 x n_pois

  # Category vector aligned with POI columns
  poi_categories <- sf_pois$category

  # Network-based counts: POIs reachable within 15-min walk
  for (cat in categories) {
    col_idx <- which(poi_categories == cat)
    sf_nbhoods[[paste0("n_", tolower(cat))]] <-
      rowSums(walk_time_mat[, col_idx, drop = FALSE] <= 15, na.rm = TRUE)
  }

  count_cols <- paste0("n_", tolower(categories))
  sf_nbhoods <- sf_nbhoods |>
    mutate(access_score = rowSums(across(all_of(count_cols))))

  # Also compute Euclidean counts for robustness comparison
  sf_centroid_buffers <- st_sf(
    neighbourhood = sf_nbhoods$neighbourhood,
    geometry = st_buffer(centroid_sfc, dist = walk_buffer_m)
  )

  count_access <- function(cat_name, buffers, pois) {
    cat_pois <- pois |> filter(category == cat_name)
    lengths(st_intersects(buffers, cat_pois))
  }

  for (cat in categories) {
    sf_nbhoods[[paste0("n_", tolower(cat), "_eucl")]] <-
      count_access(cat, sf_centroid_buffers, sf_pois)
  }

  eucl_cols <- paste0("n_", tolower(categories), "_eucl")
  sf_nbhoods <- sf_nbhoods |>
    mutate(access_score_eucl = rowSums(across(all_of(eucl_cols))))

} else {

  message("Network walk times not found — using Euclidean 1,200 m buffers")

  sf_centroid_buffers <- st_sf(
    neighbourhood = sf_nbhoods$neighbourhood,
    geometry = st_buffer(centroid_sfc, dist = walk_buffer_m)
  )

  count_access <- function(cat_name, buffers, pois) {
    cat_pois <- pois |> filter(category == cat_name)
    lengths(st_intersects(buffers, cat_pois))
  }

  for (cat in categories) {
    sf_nbhoods[[paste0("n_", tolower(cat))]] <-
      count_access(cat, sf_centroid_buffers, sf_pois)
  }

  count_cols <- paste0("n_", tolower(categories))
  sf_nbhoods <- sf_nbhoods |>
    mutate(access_score = rowSums(across(all_of(count_cols))))
}

# Join socioeconomic data ----

sf_nbhoods <- sf_nbhoods |> mutate(codi_barri = as.integer(codi_barri))
df_income <- df_income |> mutate(Codi_Barri = as.integer(Codi_Barri))
df_pop <- df_pop |> mutate(Codi_Barri = as.integer(Codi_Barri))

sf_analysis <- sf_nbhoods |>
  left_join(
    df_income |> select(Codi_Barri, income_eur, rfd_index),
    by = c("codi_barri" = "Codi_Barri")
  ) |>
  left_join(
    df_pop |> select(Codi_Barri, population),
    by = c("codi_barri" = "Codi_Barri")
  ) |>
  filter(!is.na(income_eur), !is.na(population), population > 0) |>
  mutate(
    pop_density = population / area_km2,
    log_access = log(access_score + 1),
    log_rfd_index = log(rfd_index),
    log_income = log(income_eur),
    log_pop_density = log(pop_density),
    log_dist_center = log(dist_center_km)
  ) |>
  st_sf()

message("Analysis dataset: ", nrow(sf_analysis), " neighbourhoods")
