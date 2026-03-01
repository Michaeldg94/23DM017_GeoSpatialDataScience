# =============================================================================
# 00_setup.R — Packages, paths, constants, helper functions
# =============================================================================

if (!require("pacman")) install.packages("pacman")

pacman::p_load(
  sf, dplyr, tidyr, readr, stringr, ggplot2,
  spdep, spatialreg,
  viridis, patchwork, scales, units
)

data_dir <- file.path(getwd(), "data")
output_dir <- file.path(getwd(), "output")

if (!dir.exists(data_dir)) dir.create(data_dir, recursive = TRUE)
if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)

crs_proj <- "EPSG:25831"

# City centre reference: Placa Catalunya
pt_center <- st_sfc(st_point(c(2.1700, 41.3870)), crs = 4326) |>
  st_transform(crs_proj)

walk_buffer_m <- 1200

# Display names used throughout the analysis and the Rmd report.
# The raw gpkg uses lowercase names; we map them here once.
category_map <- c(
  "healthcare"       = "Healthcare",
  "park"             = "Park",
  "pharmacy"         = "Pharmacy",
  "public_transport" = "Transit",
  "school"           = "School",
  "supermarket"      = "Grocery"
)

categories <- unname(category_map)

# Helpers ----

theme_map <- function(...) {
  theme_void() +
    theme(
      plot.title = element_text(size = 11, face = "bold", hjust = 0),
      plot.subtitle = element_text(size = 9, color = "grey40", hjust = 0),
      legend.position = "right",
      legend.key.width = unit(0.4, "cm"),
      plot.margin = margin(5, 5, 5, 5),
      ...
    )
}

gini <- function(x) {
  x <- sort(x[x > 0])
  n <- length(x)
  2 * sum(seq_len(n) * x) / (n * sum(x)) - (n + 1) / n
}
