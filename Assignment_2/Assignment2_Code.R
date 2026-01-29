# Lecture 04 - Take-Home Assignment
# Geospatial Data Sciences and Economic Spatial Models
# Bruno Conte - BSE
# Author: Michael
# Date: January 2026

# Setup ----

rm(list = ls())

# Load the libraries we'll need for this assignment
# sf for spatial operations, tidyverse for data wrangling and plots
library(sf)
library(tidyverse)
library(spData)
library(rnaturalearth)
library(rnaturalearthdata)
library(units)

# Create output directory to save all our plots
dir.create("output", showWarnings = FALSE)

# I prefer minimal theme for cleaner visualizations
theme_set(theme_minimal())

# PART 1: WORLD POPULATION AND TRANSPORTATION ----

## 1.1 Load Natural Earth Data ----

# First, let's get the world countries shapefile
# Natural Earth is a great free source for this kind of data
# See: https://www.naturalearthdata.com/

sf_world <- ne_countries(scale = "medium", returnclass = "sf") |>
  select(name, continent, iso_a3, pop_est, geometry)

# Now I need population data as POINTS (the assignment says no rasters!)
# Natural Earth has "populated_places" which contains cities with population estimates
# Let's download it - this might take a moment...

sf_places <- ne_download(
  scale = "large",
  type = "populated_places",
  category = "cultural",
  returnclass = "sf"
)

# We also need ports and airports for the distance calculations
# These are also available from Natural Earth under "cultural" category

sf_ports <- ne_download(
  scale = "large",
  type = "ports",
  category = "cultural",
  returnclass = "sf"
)

sf_airports <- ne_download(
  scale = "large",
  type = "airports",
  category = "cultural",
  returnclass = "sf"
)

# Let's check what we got
cat("World countries:", nrow(sf_world), "\n")
cat("Populated places:", nrow(sf_places), "\n")
cat("Ports:", nrow(sf_ports), "\n")
cat("Airports:", nrow(sf_airports), "\n")

# Quick look at the populated places columns to find the population variable
# names(sf_places)
# Looks like POP_MAX has the population estimates

## 1.2 Calculate Total Population by Country ----

# Before joining, I need to make sure both datasets use the same CRS
# Otherwise the spatial join won't work properly
sf_places <- st_transform(sf_places, st_crs(sf_world))

# Now let's do a spatial join to assign each city to its country
# Using st_within because we want points that fall INSIDE country polygons
sf_places_joined <- st_join(sf_places, sf_world, join = st_within)

# Aggregate population by country
# POP_MAX contains the population estimate for each place
pop_by_country <- sf_places_joined |>
  st_drop_geometry() |>
  group_by(iso_a3, name.y, continent) |>
  summarise(
    total_pop = sum(POP_MAX, na.rm = TRUE),
    n_places = n(),  # also counting how many cities per country
    .groups = "drop"
  ) |>
  rename(country_name = name.y)

# Join this back to the world shapefile so we can map it
sf_world_pop <- sf_world |>
  left_join(pop_by_country, by = c("iso_a3", "continent"))

# Quick check - did it work?
# head(sf_world_pop)

## 1.3 Map: Total Population by Country ----

# Creating the choropleth map
# Using log scale because population varies enormously across countries
p_map_pop <- ggplot() +
  geom_sf(
    data = sf_world_pop,
    aes(fill = total_pop / 1e6),  # converting to millions for readability
    color = "white",
    linewidth = 0.1
  ) +
  scale_fill_viridis_c(
    option = "plasma",
    name = "Population\n(millions)",
    na.value = "grey80",
    trans = "log10",
    labels = scales::comma
  ) +
  labs(
    title = "Total Urban Population by Country",
    subtitle = "Based on Natural Earth populated places data",
    caption = "Source: Natural Earth"
  ) +
  theme(
    legend.position = "bottom",
    legend.key.width = unit(2, "cm")
  )

print(p_map_pop)

ggsave(
  filename = "output/01_map_population.png",
  plot = p_map_pop,
  width = 12,
  height = 8,
  dpi = 300
)

## 1.4 Histogram: Population Distribution by Continent ----

# Filter out missing values before plotting
pop_data <- sf_world_pop |>
  st_drop_geometry() |>
  filter(!is.na(continent), !is.na(total_pop), total_pop > 0)

# Faceted histogram by continent
p_hist_pop <- ggplot(pop_data, aes(x = total_pop / 1e6, fill = continent)) +
  geom_histogram(bins = 30, color = "white", alpha = 0.7) +
  facet_wrap(~continent, scales = "free_y", ncol = 3) +
  scale_x_log10(labels = scales::comma) +
  scale_fill_brewer(palette = "Set2") +
  labs(
    title = "Distribution of Country Population by Continent",
    x = "Total Population (millions, log scale)",
    y = "Number of Countries"
  ) +
  theme(legend.position = "none")  # legend not needed with facets

print(p_hist_pop)

ggsave(
  filename = "output/02_histogram_population_continent.png",
  plot = p_hist_pop,
  width = 10,
  height = 6,
  dpi = 300
)

## 1.5 Calculate Distances to Ports and Airports ----

# For distance calculations, we need a PROJECTED CRS (not lat/lon)
# Robinson projection works well for global data
crs_robinson <- "+proj=robin +lon_0=0 +x_0=0 +y_0=0 +datum=WGS84 +units=m"

sf_places_proj <- st_transform(sf_places, crs_robinson)
sf_ports_proj <- st_transform(sf_ports, crs_robinson)
sf_airports_proj <- st_transform(sf_airports, crs_robinson)
sf_world_proj <- st_transform(sf_world, crs_robinson)

# The assignment says to filter top 20 ports/airports if there are too many
# Let's check the scalerank variable - lower values = more important
# head(sf_ports_proj |> arrange(scalerank))

sf_ports_top20 <- sf_ports_proj |>
  arrange(scalerank) |>
  slice_head(n = 20)

sf_airports_top20 <- sf_airports_proj |>
  arrange(scalerank) |>
  slice_head(n = 20)

cat("Selected top 20 ports and airports by importance\n")

# Computing distances for ALL places would take forever...
# Let's sample 500 places to make it manageable
set.seed(42)  # for reproducibility
n_sample <- min(500, nrow(sf_places_proj))

sf_places_sample <- sf_places_proj |>
  slice_sample(n = n_sample)

# Now calculate distance matrices using st_distance()
# This gives us distance from each place to each port/airport
cat("Calculating distances to ports (this might take a moment)...\n")
dist_to_ports <- st_distance(sf_places_sample, sf_ports_top20)

cat("Calculating distances to airports...\n")
dist_to_airports <- st_distance(sf_places_sample, sf_airports_top20)

# For each place, we want the MINIMUM distance (nearest port/airport)
# apply() with MARGIN=1 operates on rows
sf_places_sample$min_dist_port <- dist_to_ports |>
  apply(1, min) |>
  set_units("km") |>
  as.numeric()

sf_places_sample$min_dist_airport <- dist_to_airports |>
  apply(1, min) |>
  set_units("km") |>
  as.numeric()

# Now join with world to get continent for each place
sf_places_dist <- sf_places_sample |>
  st_join(sf_world_proj, join = st_within) |>
  filter(!is.na(continent))

# Let's see the average distances by continent
avg_distances <- sf_places_dist |>
  st_drop_geometry() |>
  group_by(continent) |>
  summarise(
    avg_dist_port = mean(min_dist_port, na.rm = TRUE),
    avg_dist_airport = mean(min_dist_airport, na.rm = TRUE),
    n = n()
  )

print(avg_distances)
# Interesting! Africa and Asia have higher average distances, makes sense geographically

## 1.6 Histogram: Distances by Continent ----

# Histogram for distance to ports
p_hist_ports <- ggplot(
  data = sf_places_dist,
  aes(x = min_dist_port, fill = continent)
) +
  geom_histogram(bins = 25, color = "white", alpha = 0.7) +
  facet_wrap(~continent, scales = "free_y", ncol = 3) +
  scale_fill_brewer(palette = "Set2") +
  labs(
    title = "Distribution of Minimum Distance to Nearest Port",
    subtitle = "By continent (using top 20 global ports)",
    x = "Distance to Nearest Port (km)",
    y = "Number of Locations"
  ) +
  theme(legend.position = "none")

print(p_hist_ports)

ggsave(
  filename = "output/03_histogram_distance_ports.png",
  plot = p_hist_ports,
  width = 10,
  height = 6,
  dpi = 300
)

# Same thing for airports
p_hist_airports <- ggplot(
  data = sf_places_dist,
  aes(x = min_dist_airport, fill = continent)
) +
  geom_histogram(bins = 25, color = "white", alpha = 0.7) +
  facet_wrap(~continent, scales = "free_y", ncol = 3) +
  scale_fill_brewer(palette = "Set2") +
  labs(
    title = "Distribution of Minimum Distance to Nearest Airport",
    subtitle = "By continent (using top 20 global airports)",
    x = "Distance to Nearest Airport (km)",
    y = "Number of Locations"
  ) +
  theme(legend.position = "none")

print(p_hist_airports)

ggsave(
  filename = "output/04_histogram_distance_airports.png",
  plot = p_hist_airports,
  width = 10,
  height = 6,
  dpi = 300
)

# PART 2: AFRICAN AGRICULTURAL MARKETS (Porteous 2019) ----

cat("\n========================================\n")
cat("PART 2: Porteous (2019) Analysis\n")
cat("========================================\n\n")

# The paper studies how high trade costs affect African agricultural markets
# We need to download the replication data from ICPSR

## 2.1 Load Market Data ----

# IMPORTANT: The actual data needs to be downloaded from:
# https://www.openicpsr.org/openicpsr/project/113555
# 
# After downloading, you would load it like this:
# df_markets <- read_csv("data/porteous2019/market_data.csv")
#
# The paper's appendix has details on the variables
# For now, I'll create sample data to show the structure

cat("NOTE: Using simulated data for demonstration.\n")
cat("You need to replace this with actual Porteous (2019) data!\n\n")

# Get Africa shapefile
sf_africa <- sf_world |>
  filter(continent == "Africa")

# Creating sample market data - REPLACE THIS WITH ACTUAL DATA
set.seed(123)

sf_africa_union <- sf_africa |>
  st_union() |>
  st_sf()

n_markets <- 150
sample_points <- st_sample(sf_africa_union, n_markets)

# Simulating some market data
df_markets <- tibble(
  market_id = 1:n_markets,
  market_name = paste0("Market_", 1:n_markets),
  avg_price = runif(n_markets, min = 80, max = 250),
  commodity = sample(
    x = c("maize", "rice", "sorghum", "millet"),
    size = n_markets,
    replace = TRUE
  )
)

sf_markets <- st_sf(df_markets, geometry = sample_points) |>
  st_set_crs(4326)

## 2.2 Map Market Locations ----

# Let's visualize where the markets are located
p_markets_map <- ggplot() +
  geom_sf(
    data = sf_africa,
    fill = "lightgray",
    color = "white",
    linewidth = 0.3
  ) +
  geom_sf(
    data = sf_markets,
    aes(color = avg_price),
    size = 2.5,
    alpha = 0.8
  ) +
  scale_color_viridis_c(option = "magma", name = "Average\nPrice") +
  labs(
    title = "Agricultural Market Locations Across Africa",
    subtitle = "Sample data - replace with Porteous (2019) market data",
    caption = "Data source: Simulated (replace with actual data)"
  ) +
  theme_minimal() +
  theme(legend.position = "right")

print(p_markets_map)

ggsave(
  filename = "output/05_map_african_markets.png",
  plot = p_markets_map,
  width = 10,
  height = 10,
  dpi = 300
)

## 2.3 Load Transportation Infrastructure ----

# We need coastline, roads, and airports for Africa
# Coastline from Natural Earth
sf_coastline <- ne_coastline(scale = "medium", returnclass = "sf")

# Filter airports to only those in Africa
sf_airports_africa <- sf_airports |>
  st_transform(st_crs(sf_africa)) |>
  st_filter(sf_africa)

cat("Airports in Africa:", nrow(sf_airports_africa), "\n")

# Roads are tricky - Natural Earth doesn't have great coverage
# Alternative would be GRIP database or OpenStreetMap
# Let's try to get what's available
sf_roads <- tryCatch(
  expr = {
    ne_download(
      scale = "large",
      type = "roads",
      category = "cultural",
      returnclass = "sf"
    )
  },
  error = function(e) {
    cat("Roads data not available from Natural Earth.\n")
    cat("Will use populated places as proxy for accessibility.\n")
    NULL
  }
)

## 2.4 Calculate Distances ----

# For Africa, let's use Albers Equal Area projection centered on Africa
# This gives more accurate distance measurements
crs_africa <- paste0(
  "+proj=aea +lat_1=20 +lat_2=-23 +lat_0=0 +lon_0=25 ",
  "+x_0=0 +y_0=0 +datum=WGS84 +units=m"
)

# Transform everything to this CRS
sf_markets_proj <- st_transform(sf_markets, crs_africa)
sf_africa_proj <- st_transform(sf_africa, crs_africa)
sf_coastline_proj <- st_transform(sf_coastline, crs_africa)
sf_airports_africa_proj <- st_transform(sf_airports_africa, crs_africa)

# Clip coastline to Africa region only
africa_bbox <- st_bbox(sf_africa_proj)
sf_coastline_africa <- st_crop(sf_coastline_proj, africa_bbox)

# 1. DISTANCE TO COAST
cat("\nCalculating distance to coast...\n")
dist_coast <- st_distance(sf_markets_proj, sf_coastline_africa)

sf_markets_proj$dist_coast_km <- dist_coast |>
  apply(1, min) |>
  set_units("km") |>
  as.numeric()

# 2. DISTANCE TO AIRPORT
cat("Calculating distance to airports...\n")
dist_airport <- st_distance(sf_markets_proj, sf_airports_africa_proj)

sf_markets_proj$dist_airport_km <- dist_airport |>
  apply(1, min) |>
  set_units("km") |>
  as.numeric()

# 3. DISTANCE TO ROAD
# If roads aren't available, use distance to urban centers as proxy
cat("Calculating distance to roads/urban areas...\n")

if (!is.null(sf_roads)) {
  
  sf_roads_africa <- sf_roads |>
    st_transform(crs_africa) |>
    st_filter(sf_africa_proj)
  
  dist_road <- st_distance(sf_markets_proj, sf_roads_africa)
  
  sf_markets_proj$dist_road_km <- dist_road |>
    apply(1, min) |>
    set_units("km") |>
    as.numeric()
  
} else {
  
  # Fallback: use populated places as proxy for road access
  # The idea is that larger cities are usually better connected
  sf_places_africa <- sf_places |>
    st_transform(crs_africa) |>
    st_filter(sf_africa_proj)
  
  dist_road <- st_distance(sf_markets_proj, sf_places_africa)
  
  sf_markets_proj$dist_road_km <- dist_road |>
    apply(1, min) |>
    set_units("km") |>
    as.numeric()
  
}

# Let's see what we got
cat("\n=== Distance Summary Statistics ===\n")

sf_markets_proj |>
  st_drop_geometry() |>
  select(dist_coast_km, dist_road_km, dist_airport_km) |>
  summary() |>
  print()

## 2.5 Scatter Plots: Prices vs Distances ----

# Now the interesting part - do prices relate to infrastructure access?
# Porteous (2019) argues that trade costs (related to distance) affect prices

# Prepare data for plotting
df_analysis <- sf_markets_proj |>
  st_drop_geometry()

# Plot 1: Price vs Distance to Coast
# Hypothesis: markets further from coast might have higher prices (import costs)
p_scatter_coast <- ggplot(
  data = df_analysis,
  aes(x = dist_coast_km, y = avg_price)
) +
  geom_point(alpha = 0.6, color = "#2166ac", size = 2.5) +
  geom_smooth(method = "lm", se = TRUE, color = "#b2182b", linetype = "dashed") +
  labs(
    title = "Market Prices vs. Distance to Coast",
    x = "Distance to Coast (km)",
    y = "Average Price",
    caption = "Note: Sample data - replace with Porteous (2019) data"
  ) +
  theme_minimal()

print(p_scatter_coast)

ggsave(
  filename = "output/06_scatter_price_coast.png",
  plot = p_scatter_coast,
  width = 8,
  height = 6,
  dpi = 300
)

# Check the correlation
cor_coast <- cor(
  x = df_analysis$dist_coast_km,
  y = df_analysis$avg_price,
  use = "complete.obs"
)
cat("\nCorrelation (Price vs Coast):", round(cor_coast, 3), "\n")

# Plot 2: Price vs Distance to Road/Urban Center
# Better road access should mean lower transport costs and lower prices
p_scatter_road <- ggplot(
  data = df_analysis,
  aes(x = dist_road_km, y = avg_price)
) +
  geom_point(alpha = 0.6, color = "#1a9850", size = 2.5) +
  geom_smooth(method = "lm", se = TRUE, color = "#b2182b", linetype = "dashed") +
  labs(
    title = "Market Prices vs. Distance to Roads",
    subtitle = "(Using populated places as proxy for road network)",
    x = "Distance to Nearest Road/Urban Center (km)",
    y = "Average Price",
    caption = "Note: Sample data - replace with Porteous (2019) data"
  ) +
  theme_minimal()

print(p_scatter_road)

ggsave(
  filename = "output/07_scatter_price_road.png",
  plot = p_scatter_road,
  width = 8,
  height = 6,
  dpi = 300
)

cor_road <- cor(
  x = df_analysis$dist_road_km,
  y = df_analysis$avg_price,
  use = "complete.obs"
)
cat("Correlation (Price vs Road):", round(cor_road, 3), "\n")

# Plot 3: Price vs Distance to Airport
# Airports probably less relevant for bulk agricultural goods, but let's see
p_scatter_airport <- ggplot(
  data = df_analysis,
  aes(x = dist_airport_km, y = avg_price)
) +
  geom_point(alpha = 0.6, color = "#762a83", size = 2.5) +
  geom_smooth(method = "lm", se = TRUE, color = "#b2182b", linetype = "dashed") +
  labs(
    title = "Market Prices vs. Distance to Airport",
    x = "Distance to Nearest Airport (km)",
    y = "Average Price",
    caption = "Note: Sample data - replace with Porteous (2019) data"
  ) +
  theme_minimal()

print(p_scatter_airport)

ggsave(
  filename = "output/08_scatter_price_airport.png",
  plot = p_scatter_airport,
  width = 8,
  height = 6,
  dpi = 300
)

cor_airport <- cor(
  x = df_analysis$dist_airport_km,
  y = df_analysis$avg_price,
  use = "complete.obs"
)
cat("Correlation (Price vs Airport):", round(cor_airport, 3), "\n")

## 2.6 Combined Panel Plot ----

# It would be nice to see all three relationships side by side
# Let's reshape the data for a faceted plot

df_long <- df_analysis |>
  select(market_id, avg_price, dist_coast_km, dist_road_km, dist_airport_km) |>
  pivot_longer(
    cols = starts_with("dist"),
    names_to = "distance_type",
    values_to = "distance"
  ) |>
  mutate(
    distance_type = case_when(
      distance_type == "dist_coast_km" ~ "Distance to Coast",
      distance_type == "dist_road_km" ~ "Distance to Road",
      distance_type == "dist_airport_km" ~ "Distance to Airport"
    )
  )

p_combined <- ggplot(df_long, aes(x = distance, y = avg_price)) +
  geom_point(alpha = 0.5, size = 1.5, color = "steelblue") +
  geom_smooth(method = "lm", se = TRUE, color = "#b2182b", linetype = "dashed") +
  facet_wrap(~distance_type, scales = "free_x") +
  labs(
    title = "Relationship Between Market Prices and Distance to Infrastructure",
    subtitle = "African Agricultural Markets",
    x = "Distance (km)",
    y = "Average Price",
    caption = "Data: Sample (replace with Porteous 2019 replication data)"
  ) +
  theme_minimal() +
  theme(strip.text = element_text(face = "bold"))

print(p_combined)

ggsave(
  filename = "output/09_scatter_combined.png",
  plot = p_combined,
  width = 12,
  height = 5,
  dpi = 300
)

# Final Notes ----

cat("\n========================================\n")
cat("ANALYSIS COMPLETE!\n")
cat("========================================\n\n")

cat("Remember to replace the sample data with actual Porteous (2019) data:\n")
cat("1. Download from ICPSR: https://www.openicpsr.org/openicpsr/project/113555\n")
cat("2. Check the paper's appendix for variable descriptions\n")
cat("3. The market coordinates and prices should be in the replication files\n\n")

cat("All plots have been saved to the 'output/' folder.\n")
cat("Good luck with the submission!\n")

# Session Info ----

sessionInfo()