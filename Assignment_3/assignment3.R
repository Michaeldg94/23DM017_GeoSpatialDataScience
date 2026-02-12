# Take-Home Assignment — Lecture 06: Geospatial Data Sciences
# Bruno Conte | Barcelona School of Economics
# =============================================================================
#
# IMPORTANT: Loading `gdistance` masks tidyverse functions (select, filter,
#            extract, union...). We use dplyr:: prefixes to avoid errors.
#
# =============================================================================


# Load libraries --------------------------------------------------------------

library(tidyverse)
library(sf)
library(terra)
library(exactextractr)
library(spData)         # us_states, world
library(rnaturalearth)
library(rnaturalearthdata)
library(gdistance)      # loads raster, sp, igraph — causes masking!


# Download external data (if needed) ------------------------------------------

dir.create("data", showWarnings = FALSE)

# --- SPEI 1-month NetCDF (from class Dropbox link) ---
spei_path <- "data/spei01.nc"
if (!file.exists(spei_path)) {
  message("Downloading SPEI data... this may take a minute.")
  download.file(
    url      = "https://www.dropbox.com/scl/fi/kmo2gj0iqvu52rat9ydmt/spei01.nc?rlkey=1ahg7k4cs1uf1v52s5x6d0sxj&dl=1",
    destfile = spei_path,
    mode     = "wb"
  )
}


# =============================================================================
# ASSIGNMENT 1/2: Climate Change in USA (page 30)                          ----
# =============================================================================


# 1.1 Prepare US regions geometry ---------------------------------------------

sf_states <- us_states %>%
  dplyr::filter(!NAME %in% c("Alaska", "Hawaii")) %>%
  dplyr::select(NAME, REGION)

# Dissolve states into four Census regions
sf_regions <- sf_states %>%
  group_by(REGION) %>%
  summarise(geometry = st_union(geometry)) %>%
  ungroup()


# 1.2 Load SPEI raster --------------------------------------------------------

r_spei <- rast(spei_path)
r_spei

spei_dates <- time(r_spei)


# 1.3 Subset to last ~50 years (one layer per year, January) ------------------

layer_index <- which(
  year(spei_dates) >= 1966 & month(spei_dates) == 1
)

r_spei_50 <- r_spei[[layer_index]]
spei_years <- year(time(r_spei_50))
names(r_spei_50) <- paste0("spei_", spei_years)


# 1.4 Zonal statistics: average SPEI per region per year ----------------------

df_zonal <- exact_extract(
  x   = r_spei_50,
  y   = sf_regions,
  fun = "mean"
)

# Reshape to long panel format
df_panel <- df_zonal %>%
  mutate(REGION = sf_regions$REGION) %>%
  pivot_longer(
    cols      = starts_with("mean.spei_"),
    names_to  = "year",
    values_to = "spei"
  ) %>%
  mutate(year = as.integer(str_extract(year, "\\d{4}")))


# 1.5 Plot: SPEI evolution by region + geom_smooth ----------------------------

ggplot(df_panel, aes(x = year, y = spei, color = REGION)) +
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


# =============================================================================
# ASSIGNMENT 2/2: Transportation Centrality in Spain (pages 31-32)         ----
# =============================================================================


# 2.1 Spain boundary ----------------------------------------------------------

sf_spain <- world %>%
  dplyr::filter(name_long == "Spain") %>%
  st_transform("EPSG:4326")


# 2.2 Top 10 populated places in Spain ---------------------------------------

sf_places_raw <- ne_download(
  scale = 10, type = "populated_places", category = "cultural",
  destdir = "data", returnclass = "sf"
)

# IMPORTANT: ne_download() writes .gpkg with LOWERCASE column names
# Normalize all column names to lowercase to be safe
names(sf_places_raw) <- tolower(names(sf_places_raw))

# Quick check — run this to verify:
# unique(sf_places_raw$sov0name[grepl("pain", sf_places_raw$sov0name)])

sf_places <- sf_places_raw %>%
  dplyr::filter(iso_a2 == "ES") %>%
  arrange(desc(pop_max)) %>%
  slice_head(n = 10) %>%
  dplyr::select(name, pop_max)

# Should print 10 city names:
sf_places$name


# 2.3 Crop road network within Spain -----------------------------------------

sf_roads_raw <- ne_download(
  scale = 10, type = "roads", category = "cultural",
  destdir = "data", returnclass = "sf"
)

sf_roads_spain <- sf_roads_raw %>%
  st_crop(st_bbox(sf_spain)) %>%
  st_intersection(sf_spain)


# 2.4 Build raster friction surface -------------------------------------------

r_template <- rast() %>%
  crop(sf_spain)

res(r_template) <- 0.1

r_roads <- rasterize(vect(sf_roads_spain), r_template)

# Friction surface: replace NaN/NA with 1/100 (class approach, line 197)
vv <- values(r_roads)
vv[is.nan(vv) | is.na(vv)] <- 1 / 100
values(r_roads) <- vv
rm(vv)

# Visual check
plot(r_roads, main = "Friction Surface - Spain")
plot(st_geometry(sf_spain), add = TRUE, border = "black", lwd = 2)
plot(st_geometry(sf_places), add = TRUE, pch = 20, cex = 1.5)


# 2.5 Create transition matrix -----------------------------------------------

tr_matrix <- transition(
  x                  = raster::raster(r_roads),
  transitionFunction = mean,
  directions         = 8
)

tr_matrix <- geoCorrection(tr_matrix, type = "c")


# 2.6 Bilateral distances between all city pairs -----------------------------

# costDistance is much faster than looping shortestPath (class06 line 304)
dist_matrix <- costDistance(
  tr_matrix,
  as(sf_places, "Spatial")
) %>%
  as.matrix()

city_names <- sf_places$name
rownames(dist_matrix) <- city_names
colnames(dist_matrix) <- city_names

# Convert to km
dist_matrix_km <- dist_matrix / 1000
round(dist_matrix_km, 0)


# 2.7 Visualize path Madrid-Vigo ---------------------------------------------

sf_madrid <- sf_places %>% dplyr::filter(name == "Madrid")
sf_vigo   <- sf_places %>% dplyr::filter(name == "Vigo")

path_mv <- shortestPath(
  x      = tr_matrix,
  origin = st_coordinates(sf_madrid),
  goal   = st_coordinates(sf_vigo),
  output = "SpatialLines"
)

sf_path_mv <- st_as_sf(path_mv) %>% st_set_crs(4326)
st_length(sf_path_mv) / 1000  # distance in km

# Map with road network and path
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


# 2.8 Compare isolation: Madrid vs Vigo --------------------------------------

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


# 2.9 Plot: density of bilateral distances -----------------------------------

ggplot(df_distances, aes(x = distance, fill = origin)) +
  geom_density(alpha = 0.5) +
  xlim(0, 1500) +
  labs(
    title = "Transportation Centrality: Madrid vs. Vigo",
    x     = "Distance (km)",
    y     = "Density",
    fill  = "Origin"
  ) +
  scale_fill_manual(values = c("Madrid" = "salmon", "Vigo" = "cyan3")) +
  theme_minimal()
