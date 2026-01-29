# Assignment 2: Geometry Operations with Natural Earth Data
# Geospatial Course
# February 2026

# Setup -----------------------------------------------------------------------

# Load required packages
# https://github.com/ropensci/rnaturalearth
if (!require("pacman")) install.packages("pacman")

pacman::p_load(
  sf,           
  dplyr,        
  ggplot2,      
  spData,       
  rnaturalearth,
  rnaturalearthdata, 
  scales,       # Scale functions for visualization
  viridis       # Color palettes
)

# Data Loading ----------------------------------------------------------------

# Load world boundaries from spData
sf_world <- world

# Download populated places (cities/towns) from Natural Earth
# This is point data
sf_places <- ne_download(
  scale = 10,
  type = "populated_places",
  category = "cultural",
  returnclass = "sf"
)

# Download ports from Natural Earth
sf_ports <- ne_download(
  scale = 10,
  type = "ports",
  category = "cultural",
  returnclass = "sf"
)

# Download airports from Natural Earth
sf_airports <- ne_download(
  scale = 10,
  type = "airports",
  category = "cultural",
  returnclass = "sf"
)

# Data Exploration ------------------------------------------------------------

# Check the structure of our datasets

head(sf_world)
head(sf_places)
head(sf_ports)
head(sf_airports)

# Check available columns for population data
names(sf_places)

# Data Processing -------------------------------------------------------------

# Transform all data to the same CRS (WGS84 for simplicity)
sf_world <- st_transform(sf_world, 4326)
sf_places <- st_transform(sf_places, 4326)
sf_ports <- st_transform(sf_ports, 4326)
sf_airports <- st_transform(sf_airports, 4326)

# Aggregate population by country using spatial join
# First, join places to countries
sf_places_joined <- st_join(
  sf_places,
  sf_world[, c("name_long", "continent")],
  join = st_within # which points lie within the polygon
)

# Calculate total population per country from point data
pop_by_country <- sf_places_joined %>%
  st_drop_geometry() %>%
  filter(!is.na(name_long)) %>%
  group_by(name_long) %>%
  summarise(
    total_pop_points = sum(POP_MAX, na.rm = TRUE),
    n_cities = n(),
    .groups = "drop"
  )

# Merge population back to world sf object
sf_world_pop <- sf_world %>%
  left_join(pop_by_country, by = "name_long")

# Filter total airports
sf_airports <- sf_airports %>%
  arrange(desc(natlscale))

# Filter total ports
sf_ports <- sf_ports %>%
  arrange(desc(natlscale))

