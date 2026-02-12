# Take-Home Assignment — Lecture 06: Geospatial Data Sciences


# Load libraries --------------------------------------------------------------

library(tidyverse)
library(sf)
library(terra)
library(exactextractr)
library(spData)
library(rnaturalearth)
library(rnaturalearthdata)
library(gdistance)


# Download external data (if needed) ------------------------------------------

dir.create("data", showWarnings = FALSE)

# SPEI 1-month NetCDF from the course Dropbox — we only download it once
spei_path <- "data/spei01.nc"

if (!file.exists(spei_path)) {
  message("Downloading SPEI data (~340 MB)...")
  download.file(
    url = paste0(
      "https://www.dropbox.com/scl/fi/kmo2gj0iqvu52rat9ydmt/",
      "spei01.nc?rlkey=1ahg7k4cs1uf1v52s5x6d0sxj&dl=1"
    ),
    destfile = spei_path,
    mode     = "wb"
  )
}


# PART 1: Climate Change in the USA


# 1.1 Prepare US regions geometry ---------------------------------------------

# We start from us_states (spData), drop Alaska and Hawaii, and dissolve
# state boundaries into the four Census regions
sf_states <- us_states %>%
  dplyr::filter(!NAME %in% c("Alaska", "Hawaii")) %>%
  dplyr::select(NAME, REGION)

# Merge states into region-level polygons
sf_regions <- sf_states %>%
  group_by(REGION) %>%
  summarise(geometry = st_union(geometry)) %>%
  ungroup()


# 1.2 Load SPEI raster --------------------------------------------------------

# The NetCDF has 1,380 monthly layers (Jan 1901 - Dec 2015). We keep only
# January of each year from 1966 onward — a clean 50-year annual panel.
r_spei     <- rast(spei_path)
spei_dates <- time(r_spei)

# One January layer per year, 1966-2015
layer_index <- which(
  year(spei_dates) >= 1966 & month(spei_dates) == 1
)

r_spei_50  <- r_spei[[layer_index]]
spei_years <- year(time(r_spei_50))

names(r_spei_50) <- paste0("spei_", spei_years)


# 1.3 Zonal statistics --------------------------------------------------------

# We compute the area-weighted mean SPEI within each region for every year,
# then reshape into long (tidy) format for plotting
df_zonal <- exact_extract(
  x   = r_spei_50,
  y   = sf_regions,
  fun = "mean"
)

# Pivot into a tidy panel: one row per region-year
df_panel <- df_zonal %>%
  mutate(region = sf_regions$REGION) %>%
  pivot_longer(
    cols      = starts_with("mean.spei_"),
    names_to  = "year",
    values_to = "spei"
  ) %>%
  mutate(year = as.integer(str_extract(year, "\\d{4}")))


# 1.4 Figure 1: SPEI evolution by region + LOESS trend ------------------------

# Positive SPEI = wetter than normal, negative = drought.
# The blue LOESS smoother captures the overall trend across all four regions.
ggplot(df_panel, aes(x = year, y = spei, color = region)) +
  geom_line(alpha = 0.7, linewidth = 0.6) +
  geom_smooth(
    aes(group = 1),
    method    = "loess",
    color     = "blue",
    linewidth = 1.2,
    se        = TRUE
  ) +
  labs(
    title = "Climate Change in USA: SPEI Index by Region (1966-2015)",
    x     = "Year",
    y     = "SPEI",
    color = "Region"
  ) +
  theme_minimal()


# PART 2: Transportation Centrality in Spain


# 2.1 Spain boundary ----------------------------------------------------------

# We grab Spain's boundary from spData::world
sf_spain <- world %>%
  dplyr::filter(name_long == "Spain") %>%
  st_transform("EPSG:4326")


# 2.2 Top 10 populated places in Spain ----------------------------------------

# Download Natural Earth populated places at 10m resolution
sf_places_raw <- ne_download(
  scale    = 10,
  type     = "populated_places",
  category = "cultural",
  destdir  = "data",
  returnclass = "sf"
)

# Ensure lowercase columns (gpkg vs shp inconsistency)
names(sf_places_raw) <- tolower(names(sf_places_raw))

# Top 10 Spanish cities by population
sf_places <- sf_places_raw %>%
  dplyr::filter(iso_a2 == "ES") %>%
  arrange(desc(pop_max)) %>%
  slice_head(n = 10) %>%
  dplyr::select(name, pop_max)


# 2.3 Crop road network within Spain ------------------------------------------

# Download roads and clip to Spain's bounding box + boundary
sf_roads_raw <- ne_download(
  scale    = 10,
  type     = "roads",
  category = "cultural",
  destdir  = "data",
  returnclass = "sf"
)

sf_roads_spain <- sf_roads_raw %>%
  st_crop(st_bbox(sf_spain)) %>%
  st_intersection(sf_spain)


# 2.4 Build raster friction surface -------------------------------------------

# We rasterize roads at 0.1 deg resolution. Road cells = 1, off-road = 1/100,
# so off-road travel is 100x more costly
r_template <- rast() %>% crop(sf_spain)
res(r_template) <- 0.1

# Burn roads into the grid
r_roads <- rasterize(vect(sf_roads_spain), r_template)

# Off-road pixels become 1/100 (costly but not impossible)
vv <- values(r_roads)
vv[is.nan(vv) | is.na(vv)] <- 1 / 100
values(r_roads) <- vv
rm(vv)


# 2.5 Figure 2: Friction surface ----------------------------------------------

plot(r_roads, main = "Friction Surface - Spain")
plot(st_geometry(sf_spain), add = TRUE, border = "black", lwd = 2)
plot(st_geometry(sf_places), add = TRUE, pch = 20, cex = 1.5)


# 2.6 Transition matrix and bilateral distances --------------------------------

# We convert the friction raster into a transition matrix with gdistance,
# then correct for lat/lon distortion
tr_matrix <- transition(
  x                  = raster::raster(r_roads),
  transitionFunction = mean,
  directions         = 8
)

# Correct for diagonal distortion in geographic coordinates
tr_matrix <- geoCorrection(tr_matrix, type = "c")

# All pairwise distances in one call — much faster than looping shortestPath()
dist_matrix <- costDistance(
  tr_matrix,
  as(sf_places, "Spatial")
) %>%
  as.matrix()

# Label and convert to km
city_names <- sf_places$name
rownames(dist_matrix) <- city_names
colnames(dist_matrix) <- city_names

dist_matrix_km <- dist_matrix / 1000
round(dist_matrix_km, 0)


# 2.7 Figure 3: Madrid-Vigo shortest path -------------------------------------

# We also want to see the actual route on a map, not just the distance number
sf_madrid <- sf_places %>% dplyr::filter(name == "Madrid")
sf_vigo   <- sf_places %>% dplyr::filter(name == "Vigo")

# shortestPath gives us the line geometry for plotting
path_mv <- shortestPath(
  x      = tr_matrix,
  origin = st_coordinates(sf_madrid),
  goal   = st_coordinates(sf_vigo),
  output = "SpatialLines"
)

# Convert to sf and assign CRS (shortestPath drops it)
sf_path_mv <- st_as_sf(path_mv) %>% st_set_crs(4326)

cat("Madrid-Vigo network distance:", round(st_length(sf_path_mv) / 1000, 0), "km\n")

# Map with road network and shortest path
ggplot() +
  geom_sf(data = sf_spain, fill = "grey90", color = "black") +
  geom_sf(data = sf_roads_spain, color = "grey40", linewidth = 0.3) +
  geom_sf(data = sf_path_mv, color = "red", linewidth = 1) +
  geom_sf(data = sf_places, size = 2, color = "black") +
  geom_sf(data = sf_madrid, size = 4, color = "red") +
  geom_sf(data = sf_vigo, size = 4, color = "blue") +
  geom_sf_label(data = sf_madrid, aes(label = name), nudge_y = 0.3) +
  geom_sf_label(data = sf_vigo, aes(label = name), nudge_y = 0.3) +
  labs(title = "Road Network and Shortest Path: Madrid - Vigo") +
  theme_minimal()


# 2.8 Compare isolation: Madrid vs Vigo ---------------------------------------

# We extract each city's distances and stack them into a tidy tibble
idx_madrid <- which(city_names == "Madrid")
idx_vigo   <- which(city_names == "Vigo")

df_distances <- bind_rows(
  tibble(
    origin   = "Madrid",
    dest     = city_names[-idx_madrid],
    distance = dist_matrix_km[idx_madrid, -idx_madrid]
  ),
  tibble(
    origin   = "Vigo",
    dest     = city_names[-idx_vigo],
    distance = dist_matrix_km[idx_vigo, -idx_vigo]
  )
)


# 2.9 Figure 4: density of bilateral distances --------------------------------

# Madrid's curve should cluster left (well connected), Vigo's shifts right
# (more isolated from the rest of Spain's major cities)
ggplot(df_distances, aes(x = distance, fill = origin)) +
  geom_density(alpha = 0.5) +
  xlim(0, 1500) +
  labs(
    title = "Transportation Centrality: Madrid vs. Vigo",
    x     = "Distance (km)",
    y     = "Density",
    fill  = "Origin"
  ) +
  scale_fill_manual(values = c("Madrid" = "orangered", "Vigo" = "forestgreen")) +
  theme_minimal()
