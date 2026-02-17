# Take-Home Assignment — Lecture 06: Geospatial Data Sciences


# Load libraries ----------------------------------------------------------

# Clean working environment
rm(list = ls())

library(tidyverse)
library(sf)
library(terra)
library(exactextractr)
library(spData)
library(rnaturalearth)
library(rnaturalearthdata)
library(gdistance)


# Download external data (if needed) --------------------------------------

dir.create("data", showWarnings = FALSE)

# SPEI 1-month NetCDF from the course Dropbox
spei_path <- "data/spei01.nc"

if (!file.exists(spei_path)) {
  message("Downloading SPEI data (~340 MB)...")
  download.file(
    url = str_c(
      "https://www.dropbox.com/scl/fi/",
      "kmo2gj0iqvu52rat9ydmt/",
      "spei01.nc?rlkey=1ahg7k4cs1uf1v52s5x6d0sxj",
      "&dl=1"
    ),
    destfile = spei_path,
    mode     = "wb"
  )
}


# PART 1: Climate Change in the USA =======================================


# 1.1 Prepare US regions geometry -----------------------------------------

# Drop Alaska & Hawaii, dissolve into four Census regions
sf_states <- us_states %>%
  dplyr::filter(!NAME %in% c("Alaska", "Hawaii")) %>%
  dplyr::select(NAME, REGION)

# Merge states into region-level polygons
sf_regions <- sf_states %>%
  group_by(REGION) %>%
  summarise(geometry = st_union(geometry)) %>%
  ungroup()


# 1.2 Load SPEI raster ----------------------------------------------------

# The NetCDF has 1,380 monthly layers (Jan 1901 – Dec 2015).
# We keep all months from 1966–2015 and average by year.
r_spei     <- rast(spei_path)
spei_dates <- time(r_spei)

# Keep all monthly layers from 1966 to 2015
layer_index <- which(
  year(spei_dates) >= 1966 & year(spei_dates) <= 2015
)

r_spei_monthly <- r_spei[[layer_index]]

# Compute yearly averages (mean of 12 months per year)
spei_years_all <- year(time(r_spei_monthly))
r_spei_50 <- tapp(
  r_spei_monthly, spei_years_all, fun = mean
)
spei_years <- names(r_spei_50) %>%
  str_extract("\\d{4}") %>%
  as.integer()

names(r_spei_50) <- str_c("spei_", spei_years)


# 1.3 Zonal statistics ----------------------------------------------------

# Area-weighted mean SPEI per region per year
df_zonal <- exact_extract(
  x   = r_spei_50,
  y   = sf_regions,
  fun = "mean"
)

# Pivot into a tidy panel: one row per region-year
df_panel <- df_zonal %>%
  mutate(REGION = sf_regions$REGION) %>%
  pivot_longer(
    cols      = starts_with("mean.spei_"),
    names_to  = "year",
    values_to = "spei"
  ) %>%
  mutate(
    year = str_extract(year, "\\d{4}") %>%
      as.integer()
  )


# 1.4 Figure 1: SPEI by region + LOESS trend ------------------------------

# Positive SPEI = wetter than normal, negative = drought.
# Blue LOESS smoother = overall trend across all regions.
ggplot(
  df_panel,
  aes(x = year, y = spei, color = REGION)
) +
  geom_line(alpha = 0.7, linewidth = 0.6) +
  geom_smooth(
    aes(group = 1),
    method    = "loess",
    color     = "blue",
    linewidth = 1.2,
    se        = TRUE
  ) +
  labs(x = "year", y = "spei", color = "REGION") +
  theme_bw()


# PART 2: Transportation Centrality in Spain ==============================


# 2.1 Spain boundary ------------------------------------------------------

sf_spain <- world %>%
  dplyr::filter(name_long == "Spain") %>%
  st_transform("EPSG:4326")


# 2.2 Top 10 populated places in Spain ------------------------------------

# Download Natural Earth populated places (10m)
sf_places_raw <- ne_download(
  scale       = 10,
  type        = "populated_places",
  category    = "cultural",
  destdir     = "data",
  returnclass = "sf"
)

# Lowercase columns (gpkg vs shp inconsistency)
names(sf_places_raw) <- tolower(names(sf_places_raw))

# Top 10 Spanish cities by population
sf_places <- sf_places_raw %>%
  dplyr::filter(iso_a2 == "ES") %>%
  arrange(desc(pop_max)) %>%
  slice_head(n = 10) %>%
  dplyr::select(name, pop_max)


# 2.3 Crop road network within Spain --------------------------------------

sf_roads_raw <- ne_download(
  scale       = 10,
  type        = "roads",
  category    = "cultural",
  destdir     = "data",
  returnclass = "sf"
)

sf_roads_spain <- sf_roads_raw %>%
  st_crop(st_bbox(sf_spain)) %>%
  st_intersection(sf_spain)


# 2.4 Build raster friction surface ----------------------------------------

# Rasterize roads at 0.1° resolution.
# Road cells = 1, off-road = 1/100 (100× costlier)
r_template <- rast() %>% crop(sf_spain)
res(r_template) <- 0.1

r_roads <- rasterize(
  vect(sf_roads_spain), r_template
)

# Off-road pixels: costly but not impossible
vv <- values(r_roads)
vv[is.nan(vv) | is.na(vv)] <- 1 / 100
values(r_roads) <- vv
rm(vv)


# 2.5 Figure 2: Friction surface ------------------------------------------

plot(r_roads, main = "Friction Surface - Spain")
plot(
  st_geometry(sf_spain),
  add = TRUE, border = "black", lwd = 2
)
plot(
  st_geometry(sf_places),
  add = TRUE, pch = 20, cex = 1.5
)


# 2.6 Transition matrix & bilateral distances -----------------------------

# Convert friction raster to transition matrix,
# then correct for lat/lon distortion
tr_matrix <- transition(
  x                  = raster::raster(r_roads),
  transitionFunction = mean,
  directions         = 8
) %>%
  geoCorrection(type = "c")

# All pairwise distances in one call
dist_matrix <- costDistance(
  tr_matrix,
  as(sf_places, "Spatial")
) %>%
  as.matrix()

# Label rows/cols and convert to km
city_names <- sf_places$name
rownames(dist_matrix) <- city_names
colnames(dist_matrix) <- city_names

dist_matrix_km <- dist_matrix / 1000
round(dist_matrix_km, 0)


# 2.7 Figure 3: Madrid–Vigo shortest path ---------------------------------

sf_madrid <- sf_places %>%
  dplyr::filter(name == "Madrid")
sf_vigo <- sf_places %>%
  dplyr::filter(name == "Vigo")

# Compute shortest path geometry
path_mv <- shortestPath(
  x      = tr_matrix,
  origin = st_coordinates(sf_madrid),
  goal   = st_coordinates(sf_vigo),
  output = "SpatialLines"
)

# Convert to sf and assign CRS
sf_path_mv <- path_mv %>%
  st_as_sf() %>%
  st_set_crs(4326)

  # Print distance
sf_path_mv %>%
  st_length() %>%
  `/`(1000) %>%
  round(0) %>%
  str_c("Madrid-Vigo distance: ", ., " km") %>%
  cat("\n")

# Map with road network and shortest path
ggplot() +
  geom_sf(
    data  = sf_spain,
    fill  = "grey90",
    color = "black"
  ) +
  geom_sf(
    data      = sf_roads_spain,
    color     = "grey40",
    linewidth = 0.3
  ) +
  geom_sf(
    data      = sf_path_mv,
    color     = "red",
    linewidth = 1
  ) +
  geom_sf(
    data  = sf_places,
    size  = 2,
    color = "black"
  ) +
  geom_sf(
    data  = sf_madrid,
    size  = 4,
    color = "red"
  ) +
  geom_sf(
    data  = sf_vigo,
    size  = 4,
    color = "blue"
  ) +
  geom_sf_label(
    data    = sf_madrid,
    aes(label = name),
    nudge_y = 0.3
  ) +
  geom_sf_label(
    data    = sf_vigo,
    aes(label = name),
    nudge_y = 0.3
  ) +
  labs(
    title = "Road Network & Shortest Path: Madrid - Vigo"
  ) +
  theme_minimal()


# 2.8 Compare isolation: Madrid vs Vigo -----------------------------------

idx_madrid <- which(city_names == "Madrid")
idx_vigo   <- which(city_names == "Vigo")

df_distances <- bind_rows(
  tibble(
    origin   = "Madrid",
    dest     = city_names[-idx_madrid],
    distance = dist_matrix_km[
      idx_madrid, -idx_madrid
    ]
  ),
  tibble(
    origin   = "Vigo",
    dest     = city_names[-idx_vigo],
    distance = dist_matrix_km[
      idx_vigo, -idx_vigo
    ]
  )
)


# 2.9 Figure 4: density of bilateral distances ----------------------------

# Madrid clusters left (central), Vigo right (isolated)
ggplot(
  df_distances,
  aes(x = distance, fill = origin)
) +
  geom_density(alpha = 0.5) +
  xlim(0, 1500) +
  scale_fill_manual(
    values = c(
      "Madrid" = "orangered",
      "Vigo"   = "forestgreen"
    )
  ) +
  labs(
    title = "Transportation Centrality: Madrid vs. Vigo",
    x     = "Distance (km)",
    y     = "Density",
    fill  = "Origin"
  ) +
  theme_minimal()