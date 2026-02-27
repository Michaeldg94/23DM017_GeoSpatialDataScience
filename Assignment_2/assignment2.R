# =============================================================================
# Assignment 2: Geospatial Data Sciences and Economic Spatial Models
# Authors: Sebastian Dong Uk Paik Sohn, Michael Duarte Gonçalves,
#          Gal·la Gelpí Buxadé, Maria Victoria Suriel Nuñez
# =============================================================================

# Setup -----------------------------------------------------------------------

if (!require("pacman")) install.packages("pacman")

pacman::p_load(
  sf, dplyr, tidyr, ggplot2, spData, rnaturalearth, rnaturalearthdata,
  scales, viridis, here, readxl, janitor, patchwork
)

output_dir <- here("Assignment_2", "output")
if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)

# Load Natural Earth Data -----------------------------------------------------

sf_world <- spData::world

sf_places <- ne_download(scale = 10, type = "populated_places",
                         category = "cultural", returnclass = "sf")
sf_ports <- ne_download(scale = 10, type = "ports",
                        category = "cultural", returnclass = "sf")
sf_airports <- ne_download(scale = 10, type = "airports",
                           category = "cultural", returnclass = "sf")

# =============================================================================
# PART 1: World Population and Transportation
# =============================================================================

# Population by country -------------------------------------------------------

places_with_country <- st_join(sf_places, sf_world[, c("name_long", "continent")],
                               join = st_within)

pop_by_country <- places_with_country |>
  st_drop_geometry() |>
  group_by(name_long) |>
  summarise(total_pop = sum(POP_MAX, na.rm = TRUE), .groups = "drop") |>
  filter(!is.na(name_long))

world_pop <- sf_world |>
  left_join(pop_by_country, by = "name_long")

# Figure 01: Linear vs log scale comparison -----------------------------------

p_linear <- ggplot() +
  geom_sf(data = world_pop, aes(fill = total_pop / 1e6),
          color = "grey50", linewidth = 0.1) +
  scale_fill_viridis_c(name = "Pop.", na.value = "lightgrey", labels = comma) +
  labs(title = "Linear scale") +
  theme_minimal() +
  theme(legend.position = "bottom", legend.key.width = unit(0.8, "cm"))

p_log <- ggplot() +
  geom_sf(data = world_pop, aes(fill = total_pop / 1e6),
          color = "grey50", linewidth = 0.1) +
  scale_fill_viridis_c(name = "Pop.", na.value = "lightgrey",
                       trans = "log10", labels = comma) +
  labs(title = "Log scale") +
  theme_minimal() +
  theme(legend.position = "bottom", legend.key.width = unit(0.8, "cm"))

fig_01 <- p_linear + p_log
ggsave(file.path(output_dir, "01_population_map_scale_comparison.pdf"),
       fig_01, width = 12, height = 5)

# Figure 02: Final population map ---------------------------------------------

fig_02 <- ggplot() +
  geom_sf(data = world_pop, aes(fill = total_pop / 1e6),
          color = "grey50", linewidth = 0.2) +
  scale_fill_viridis_c(name = "Pop.\n(millions)", na.value = "lightgrey",
                       trans = "log10", labels = comma) +
  labs(title = "Total Population by Country") +
  theme_minimal() +
  theme(legend.position = "right")

ggsave(file.path(output_dir, "02_population_map_world.pdf"),
       fig_02, width = 10, height = 6)

# Data coverage ---------------------------------------------------------------

pop_continent <- world_pop |>
  st_drop_geometry() |>
  filter(!is.na(total_pop), !is.na(continent), total_pop > 0)

n_matched <- nrow(pop_continent)

# Figure 03: Population histogram ---------------------------------------------

p_hist_linear <- ggplot(pop_continent, aes(x = total_pop / 1e6)) +
  geom_histogram(bins = 30, fill = "grey40", color = "white") +
  scale_x_continuous(labels = comma) +
  labs(title = "Linear scale", x = "Population (millions)", y = "Count") +
  theme_minimal()

p_hist_log <- ggplot(pop_continent, aes(x = total_pop / 1e6)) +
  geom_histogram(bins = 30, fill = "grey40", color = "white") +
  scale_x_log10(labels = comma) +
  labs(title = "Log scale", x = "Population (millions)", y = "Count") +
  theme_minimal()

fig_03 <- p_hist_linear + p_hist_log
ggsave(file.path(output_dir, "03_population_histogram_scale_comparison.pdf"),
       fig_03, width = 10, height = 4)

# Figure 04: Distribution by continent ----------------------------------------

fig_04 <- ggplot(pop_continent, aes(x = total_pop / 1e6)) +
  geom_histogram(bins = 25, fill = "grey40", color = "white") +
  facet_wrap(~continent, scales = "free_y", ncol = 3) +
  scale_x_log10(labels = comma) +
  scale_y_continuous(breaks = pretty_breaks()) +
  labs(title = "Country Population Distribution",
       subtitle = paste0("N = ", n_matched, " countries"),
       x = "Population (millions, log scale)", y = "Count") +
  theme_minimal() +
  theme(strip.text = element_text(face = "bold"))

ggsave(file.path(output_dir, "04_population_distribution_by_continent.pdf"),
       fig_04, width = 10, height = 7)

# Distance to infrastructure --------------------------------------------------

places_proj <- st_transform(sf_places, crs = 4326)
ports_proj <- st_transform(sf_ports, crs = 4326)
airports_proj <- st_transform(sf_airports, crs = 4326)

nearest_port <- st_nearest_feature(places_proj, ports_proj)
nearest_airport <- st_nearest_feature(places_proj, airports_proj)

places_proj <- places_proj |>
  mutate(
    dist_port_km = as.numeric(st_distance(
      geometry, ports_proj[nearest_port, ]$geometry, by_element = TRUE)) / 1000,
    dist_airport_km = as.numeric(st_distance(
      geometry, airports_proj[nearest_airport, ]$geometry, by_element = TRUE)) / 1000
  )

# Figure 05: Average distance to airport by continent -------------------------

places_with_cont <- st_join(places_proj, sf_world[, "continent"], join = st_within)

dist_airport <- places_with_cont |>
  st_drop_geometry() |>
  filter(!is.na(continent)) |>
  summarise(avg_dist = mean(dist_airport_km, na.rm = TRUE), .by = continent)

fig_05 <- ggplot(dist_airport, aes(x = reorder(continent, avg_dist), y = avg_dist)) +
  geom_col(fill = "darkgreen", alpha = 0.8) +
  coord_flip() +
  labs(title = "Average Distance to Nearest Airport", x = NULL, y = "Distance (km)") +
  theme_minimal()

ggsave(file.path(output_dir, "05_distance_to_airport_by_continent.pdf"),
       fig_05, width = 8, height = 5)

# =============================================================================
# PART 2: African Markets (Porteous 2019)
# =============================================================================

# Load data -------------------------------------------------------------------

zip_path <- here("Assignment_2", "data", "ReplicationData_HighTradeCosts.zip")
extract_dir <- here("Assignment_2", "data", "extracted")
if (!dir.exists(extract_dir)) unzip(zip_path, exdir = extract_dir)

data_dir <- file.path(extract_dir, "data", "1.-Price--Production--and-Population-Data")

mktcoords <- read_excel(file.path(data_dir, "MktCoords.xlsx"),
                        sheet = "MarketCoordinates") |>
  clean_names() |>
  rename(lon = longitude, lat = latitude)

prices_wide <- read_excel(file.path(data_dir, "PriceMaster4GAMS.xlsx")) |>
  clean_names()

# Compute average prices ------------------------------------------------------

time_cols <- setdiff(names(prices_wide), c("mktcode", "country", "market", "crop"))

prices_long <- prices_wide |>
  pivot_longer(cols = all_of(time_cols), names_to = "period", values_to = "price") |>
  mutate(price = if_else(price <= 0, NA_real_, as.numeric(price)))

avg_price <- prices_long |>
  summarise(
    avg_price = mean(price, na.rm = TRUE),
    sd_price = sd(price, na.rm = TRUE),
    n_obs = sum(!is.na(price)),
    .by = mktcode
  )

markets <- mktcoords |>
  left_join(avg_price, by = "mktcode")

# Detect outliers (IQR method) ------------------------------------------------

q1 <- quantile(markets$avg_price, 0.25, na.rm = TRUE)
q3 <- quantile(markets$avg_price, 0.75, na.rm = TRUE)
iqr <- q3 - q1

markets <- markets |>
  mutate(is_outlier = avg_price < (q1 - 1.5 * iqr) | avg_price > (q3 + 1.5 * iqr))

# Figure 06: Price distribution by country ------------------------------------

top_countries <- markets |>
  count(ctrycode, sort = TRUE) |>
  slice_head(n = 10) |>
  pull(ctrycode)

fig_06 <- markets |>
  filter(ctrycode %in% top_countries) |>
  ggplot(aes(x = reorder(ctrycode, avg_price, FUN = median, na.rm = TRUE),
             y = avg_price)) +
  geom_violin(fill = "grey85", color = NA) +
  geom_boxplot(width = 0.12, fill = "white",
               outlier.shape = 21, outlier.fill = "tomato", outlier.size = 1.5) +
  geom_jitter(width = 0.08, alpha = 0.25, size = 0.8) +
  coord_flip() +
  scale_y_continuous(labels = comma) +
  labs(title = "Price Distribution by Country",
       subtitle = "Top 10 countries by market count",
       x = NULL, y = "Average price") +
  theme_minimal() +
  theme(panel.grid.major.y = element_blank())

ggsave(file.path(output_dir, "06_price_distribution_by_country.pdf"),
       fig_06, width = 8, height = 6)

# Map setup -------------------------------------------------------------------

markets_sf <- st_as_sf(markets, coords = c("lon", "lat"), crs = 4326, remove = FALSE)
africa <- ne_countries(scale = 50, continent = "Africa", returnclass = "sf")

theme_map <- function() {
  theme_void() +
    theme(
      plot.title = element_text(size = 12, face = "bold"),
      plot.subtitle = element_text(size = 9, color = "grey40"),
      plot.caption = element_text(size = 7, color = "grey50"),
      legend.position = "bottom",
      legend.title = element_text(size = 8),
      legend.text = element_text(size = 7)
    )
}

# Figure 07: Price map comparison ---------------------------------------------

p_price_linear <- ggplot() +
  geom_sf(data = africa, fill = "#e8e8e8", color = "white", linewidth = 0.2) +
  geom_sf(data = markets_sf, aes(color = avg_price), size = 1.5, alpha = 0.8) +
  scale_color_viridis_c(option = "inferno", labels = comma, na.value = "grey70") +
  labs(title = "Linear scale", color = "Price") +
  theme_void() +
  theme(legend.position = "bottom", legend.key.width = unit(0.6, "cm"))

p_price_log <- ggplot() +
  geom_sf(data = africa, fill = "#e8e8e8", color = "white", linewidth = 0.2) +
  geom_sf(data = markets_sf, aes(color = avg_price), size = 1.5, alpha = 0.8) +
  scale_color_viridis_c(option = "inferno", trans = "log10",
                        labels = comma, na.value = "grey70") +
  labs(title = "Log scale", color = "Price") +
  theme_void() +
  theme(legend.position = "bottom", legend.key.width = unit(0.6, "cm"))

fig_07 <- p_price_linear + p_price_log
ggsave(file.path(output_dir, "07_africa_price_map_scale_comparison.pdf"),
       fig_07, width = 12, height = 6)

# Figure 08: African market prices map ----------------------------------------

fig_08 <- ggplot() +
  geom_sf(data = africa, fill = "#e8e8e8", color = "white", linewidth = 0.25) +
  geom_sf(data = filter(markets_sf, is_outlier), shape = 21, size = 3,
          fill = NA, color = "tomato", stroke = 1) +
  geom_sf(data = markets_sf, aes(fill = avg_price, size = n_obs),
          shape = 21, color = "white", stroke = 0.2, alpha = 0.85) +
  scale_fill_viridis_c(option = "inferno", trans = "log10", labels = comma,
                       na.value = "grey70",
                       guide = guide_colorbar(title = "Avg Price",
                                              barwidth = 10, barheight = 0.4)) +
  scale_size_continuous(range = c(1, 4), breaks = c(100, 500, 1000),
                        guide = guide_legend(title = "Obs",
                                             override.aes = list(fill = "grey50"))) +
  labs(title = "Agricultural Market Prices Across Africa",
       subtitle = "230 markets from Porteous (2019)",
       caption = "Data: Porteous (2019) AEJ: Applied Economics") +
  theme_map()

ggsave(file.path(output_dir, "08_africa_market_prices_map.pdf"),
       fig_08, width = 10, height = 10)

# Distance to infrastructure (Africa) -----------------------------------------

coast <- ne_download(scale = 10, type = "coastline",
                     category = "physical", returnclass = "sf")
roads <- ne_download(scale = 10, type = "roads",
                     category = "cultural", returnclass = "sf")
airports <- ne_download(scale = 10, type = "airports",
                        category = "cultural", returnclass = "sf")

africa_bbox <- st_bbox(africa)
africa_bbox[c("xmin", "ymin")] <- africa_bbox[c("xmin", "ymin")] - 5
africa_bbox[c("xmax", "ymax")] <- africa_bbox[c("xmax", "ymax")] + 5

coast_af <- st_crop(coast, africa_bbox)
roads_af <- st_crop(roads, africa_bbox)
airports_af <- st_crop(airports, africa_bbox)

# Albers Equal Area for Africa (20°N/23°S parallels, 25°E central meridian)
crs_aea <- "+proj=aea +lat_1=20 +lat_2=-23 +lat_0=0 +lon_0=25 +datum=WGS84"

markets_p <- st_transform(markets_sf, crs = crs_aea)
coast_p <- st_transform(coast_af, crs = crs_aea)
roads_p <- st_transform(roads_af, crs = crs_aea)
airports_p <- st_transform(airports_af, crs = crs_aea)

markets_p <- markets_p |>
  mutate(
    dist_coast_km = as.numeric(st_distance(
      geometry, coast_p[st_nearest_feature(geometry, coast_p), ],
      by_element = TRUE)) / 1000,
    dist_road_km = as.numeric(st_distance(
      geometry, roads_p[st_nearest_feature(geometry, roads_p), ],
      by_element = TRUE)) / 1000,
    dist_airport_km = as.numeric(st_distance(
      geometry, airports_p[st_nearest_feature(geometry, airports_p), ],
      by_element = TRUE)) / 1000
  )

markets_df <- st_drop_geometry(markets_p)

# Figure 09: Distance distributions -------------------------------------------

fig_09 <- markets_df |>
  select(mktcode, dist_coast_km, dist_road_km, dist_airport_km) |>
  pivot_longer(cols = starts_with("dist_"), names_to = "type", values_to = "distance") |>
  mutate(type = case_match(type,
                           "dist_coast_km" ~ "Coast",
                           "dist_road_km" ~ "Road",
                           "dist_airport_km" ~ "Airport")) |>
  ggplot(aes(x = type, y = distance, fill = type)) +
  geom_violin(alpha = 0.7, color = NA) +
  geom_boxplot(width = 0.12, fill = "white",
               outlier.shape = 21, outlier.fill = "tomato", outlier.size = 1) +
  scale_fill_manual(values = c(Coast = "steelblue", Road = "darkorange",
                               Airport = "darkgreen")) +
  labs(title = "Distance Distributions", x = NULL, y = "Distance (km)") +
  theme_minimal() +
  theme(legend.position = "none")

ggsave(file.path(output_dir, "09_distance_distributions_africa.pdf"),
       fig_09, width = 8, height = 5)

# Helper: transformation plot -------------------------------------------------

make_transform_plot <- function(df, x_var, log_x, log_y, color, title, label) {
  plot_df <- filter(df, .data[[x_var]] > 0, avg_price > 0)
  
  x_vals <- if (log_x) log10(plot_df[[x_var]]) else plot_df[[x_var]]
  y_vals <- if (log_y) log10(plot_df$avg_price) else plot_df$avg_price
  r <- round(cor(x_vals, y_vals, use = "complete.obs"), 3)
  
  p <- ggplot(plot_df, aes(x = .data[[x_var]], y = avg_price)) +
    geom_point(alpha = 0.5, size = 1.5, color = color) +
    geom_smooth(method = "lm", se = TRUE, color = "grey20",
                fill = "grey80", linewidth = 0.8, alpha = 0.3) +
    labs(title = title, subtitle = paste0("r = ", r),
         x = paste(label, if (log_x) "(log km)" else "(km)"),
         y = if (log_y) "Price (log)" else "Price") +
    theme_minimal(base_size = 9) +
    theme(plot.title = element_text(size = 10, face = "bold"),
          plot.subtitle = element_text(size = 9, color = "grey40"),
          axis.title = element_text(size = 8),
          axis.text = element_text(size = 7))
  
  if (log_x) p <- p + scale_x_log10(labels = label_number(scale_cut = cut_short_scale()))
  if (log_y) p <- p + scale_y_log10(labels = comma)
  p
}

# Figures 10-12: Transformation comparisons -----------------------------------

fig_10 <- (make_transform_plot(markets_df, "dist_coast_km", FALSE, FALSE,
                               "steelblue", "Linear-Linear", "Coast") +
             make_transform_plot(markets_df, "dist_coast_km", TRUE, FALSE,
                                 "steelblue", "Log Distance", "Coast")) /
  (make_transform_plot(markets_df, "dist_coast_km", FALSE, TRUE,
                       "steelblue", "Log Price", "Coast") +
     make_transform_plot(markets_df, "dist_coast_km", TRUE, TRUE,
                         "steelblue", "Log-Log", "Coast"))

ggsave(file.path(output_dir, "10_transformation_comparison_coast.pdf"),
       fig_10, width = 9, height = 7)

fig_11 <- (make_transform_plot(markets_df, "dist_road_km", FALSE, FALSE,
                               "darkorange", "Linear-Linear", "Road") +
             make_transform_plot(markets_df, "dist_road_km", TRUE, FALSE,
                                 "darkorange", "Log Distance", "Road")) /
  (make_transform_plot(markets_df, "dist_road_km", FALSE, TRUE,
                       "darkorange", "Log Price", "Road") +
     make_transform_plot(markets_df, "dist_road_km", TRUE, TRUE,
                         "darkorange", "Log-Log", "Road"))

ggsave(file.path(output_dir, "11_transformation_comparison_road.pdf"),
       fig_11, width = 9, height = 7)

fig_12 <- (make_transform_plot(markets_df, "dist_airport_km", FALSE, FALSE,
                               "darkgreen", "Linear-Linear", "Airport") +
             make_transform_plot(markets_df, "dist_airport_km", TRUE, FALSE,
                                 "darkgreen", "Log Distance", "Airport")) /
  (make_transform_plot(markets_df, "dist_airport_km", FALSE, TRUE,
                       "darkgreen", "Log Price", "Airport") +
     make_transform_plot(markets_df, "dist_airport_km", TRUE, TRUE,
                         "darkgreen", "Log-Log", "Airport"))

ggsave(file.path(output_dir, "12_transformation_comparison_airport.pdf"),
       fig_12, width = 9, height = 7)

# Correlation summary ---------------------------------------------------------

compute_cor <- function(df, dist_var, log_x, log_y) {
  df_clean <- filter(df, .data[[dist_var]] > 0, avg_price > 0)
  x <- if (log_x) log10(df_clean[[dist_var]]) else df_clean[[dist_var]]
  y <- if (log_y) log10(df_clean$avg_price) else df_clean$avg_price
  cor(x, y, use = "complete.obs")
}

cor_results <- expand.grid(
  Distance = c("Coast", "Road", "Airport"),
  Transform = c("Lin-Lin", "Log Dist", "Log Price", "Log-Log"),
  stringsAsFactors = FALSE
)

cor_results$r <- mapply(function(dist, trans) {
  d_var <- switch(dist, Coast = "dist_coast_km", Road = "dist_road_km",
                  Airport = "dist_airport_km")
  log_x <- trans %in% c("Log Dist", "Log-Log")
  log_y <- trans %in% c("Log Price", "Log-Log")
  compute_cor(markets_df, d_var, log_x, log_y)
}, cor_results$Distance, cor_results$Transform)

cor_wide <- cor_results |>
  pivot_wider(names_from = Transform, values_from = r) |>
  mutate(across(where(is.numeric), \(x) round(x, 3)))

print(cor_wide)

# Helper: scatter plot --------------------------------------------------------

make_scatter <- function(df, x_var, label, color) {
  plot_df <- filter(df, .data[[x_var]] > 0, avg_price > 0)
  r <- round(cor(plot_df[[x_var]], log10(plot_df$avg_price), use = "complete.obs"), 3)
  
  ggplot(plot_df, aes(x = .data[[x_var]], y = avg_price)) +
    geom_point(aes(shape = is_outlier), alpha = 0.6, size = 2, color = color) +
    geom_smooth(method = "lm", se = TRUE, color = "grey20",
                fill = color, alpha = 0.2, linewidth = 1) +
    scale_y_log10(labels = comma) +
    scale_shape_manual(values = c("FALSE" = 16, "TRUE" = 1), guide = "none") +
    annotate("label", x = Inf, y = Inf, label = paste0("r = ", r),
             hjust = 1.1, vjust = 1.3, size = 3.5, fontface = "bold",
             fill = "white", label.size = 0) +
    labs(title = label, x = paste("Distance to", label, "(km)"),
         y = "Average Price (log scale)") +
    theme_minimal(base_size = 10) +
    theme(plot.title = element_text(size = 10, face = "bold"),
          axis.title = element_text(size = 9))
}

# Figure 13: Final scatter plots ----------------------------------------------

fig_13 <- make_scatter(markets_df, "dist_coast_km", "Coast", "steelblue") +
  make_scatter(markets_df, "dist_road_km", "Road", "darkorange") +
  make_scatter(markets_df, "dist_airport_km", "Airport", "darkgreen") +
  plot_layout(ncol = 3) +
  plot_annotation(title = "Price vs Infrastructure Distance (Semi-Log)",
                  subtitle = "Open circles indicate statistical outliers",
                  theme = theme(plot.title = element_text(size = 12, face = "bold"),
                                plot.subtitle = element_text(size = 9, color = "grey40")))

ggsave(file.path(output_dir, "13_price_vs_distance_semilog.pdf"),
       fig_13, width = 14, height = 5)

# =============================================================================
# PART 3: Coastal Importers vs Inland Exporters
# =============================================================================

# Load production and population data -----------------------------------------

alloc_pct <- read_excel(file.path(data_dir, "AllocPCT.xlsx")) |> clean_names()
pop_raw <- read_excel(file.path(data_dir, "realCNH.xlsx"), sheet = "N")
harvest_raw <- read_excel(file.path(data_dir, "realCNH.xlsx"), sheet = "H")

# Compute net trade position --------------------------------------------------

pop_clean <- pop_raw |>
  rename(market = 1) |>
  mutate(across(-market, as.numeric)) |>
  rowwise() |>
  mutate(avg_pop_millions = mean(c_across(-market), na.rm = TRUE)) |>
  ungroup() |>
  select(market, avg_pop_millions)

harvest_clean <- harvest_raw |>
  rename(market = 1, crop = 2) |>
  mutate(across(-c(market, crop), as.numeric)) |>
  group_by(market) |>
  summarise(total_prod = sum(c_across(-crop), na.rm = TRUE), .groups = "drop") |>
  mutate(annual_prod_000t = total_prod / 11)

per_capita_kg <- 150

net_trade <- pop_clean |>
  inner_join(harvest_clean, by = "market") |>
  mutate(
    consumption_000t = avg_pop_millions * 1000 * (per_capita_kg / 1000),
    net_exports_000t = annual_prod_000t - consumption_000t,
    trade_status = if_else(net_exports_000t > 0, "Net Exporter", "Net Importer")
  )

# Classify coastal markets (50 km threshold) ----------------------------------

coastal_threshold_km <- 50

net_trade <- net_trade |>
  left_join(markets_df |> select(market, dist_coast_km), by = "market") |>
  mutate(is_coastal = dist_coast_km <= coastal_threshold_km)

# Hypothesis test -------------------------------------------------------------

trade_table <- net_trade |>
  filter(!is.na(is_coastal)) |>
  mutate(location = if_else(is_coastal, "Coastal", "Inland")) |>
  count(location, trade_status) |>
  pivot_wider(names_from = trade_status, values_from = n, values_fill = 0)

print(trade_table)

chisq_result <- chisq.test(table(
  net_trade$is_coastal[!is.na(net_trade$is_coastal)],
  net_trade$trade_status[!is.na(net_trade$is_coastal)] == "Net Exporter"
))

cat("\nChi-square test: X2 =", round(chisq_result$statistic, 2),
    ", p =", format.pval(chisq_result$p.value, digits = 3), "\n")

# Figure 14: Net trade position map -------------------------------------------

markets_trade <- markets_sf |>
  left_join(net_trade |> select(market, net_exports_000t, trade_status, is_coastal),
            by = "market") |>
  filter(!is.na(trade_status))

fig_14 <- ggplot() +
  geom_sf(data = africa, fill = "#f5f5f5", color = "white", linewidth = 0.3) +
  geom_sf(data = markets_trade,
          aes(fill = trade_status, size = abs(net_exports_000t)),
          shape = 21, color = "white", stroke = 0.3, alpha = 0.8) +
  scale_fill_manual(values = c("Net Exporter" = "#2d8659",
                               "Net Importer" = "#c44e52"),
                    name = "Trade Status") +
  scale_size_continuous(range = c(1, 6), name = "Volume\n(000 tonnes)",
                        labels = comma) +
  labs(title = "Net Trade Position of African Grain Markets",
       subtitle = "Green = surplus (exports), Red = deficit (imports)",
       caption = "Data: Porteous (2019)") +
  theme_void() +
  theme(plot.title = element_text(size = 12, face = "bold"),
        plot.subtitle = element_text(size = 10, color = "grey40"),
        legend.position = "right")

ggsave(file.path(output_dir, "14_net_trade_position_map.pdf"),
       fig_14, width = 10, height = 10)

# Figure 15: Coastal vs inland comparison -------------------------------------

p_box <- net_trade |>
  filter(!is.na(is_coastal)) |>
  mutate(location = if_else(is_coastal, "Coastal", "Inland")) |>
  ggplot(aes(x = location, y = net_exports_000t, fill = location)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
  geom_boxplot(alpha = 0.7, outlier.shape = 21) +
  scale_fill_manual(values = c(Coastal = "steelblue", Inland = "darkgreen")) +
  labs(title = "Net Exports by Location", x = NULL, y = "Net Exports (000 tonnes)") +
  theme_minimal() +
  theme(legend.position = "none")

p_bar <- net_trade |>
  filter(!is.na(is_coastal)) |>
  mutate(location = if_else(is_coastal, "Coastal", "Inland")) |>
  count(location, trade_status) |>
  group_by(location) |>
  mutate(pct = n / sum(n)) |>
  ggplot(aes(x = location, y = pct, fill = trade_status)) +
  geom_col(position = "fill", alpha = 0.8) +
  geom_text(aes(label = percent(pct, accuracy = 1)),
            position = position_fill(vjust = 0.5),
            color = "white", fontface = "bold", size = 4) +
  scale_fill_manual(values = c("Net Exporter" = "#2d8659",
                               "Net Importer" = "#c44e52"), name = "Status") +
  scale_y_continuous(labels = percent) +
  labs(title = "Proportion by Trade Status", x = NULL, y = NULL) +
  theme_minimal()

fig_15 <- p_box + p_bar
ggsave(file.path(output_dir, "15_coastal_vs_inland_comparison.pdf"),
       fig_15, width = 12, height = 5)

# =============================================================================
# PART 4: Market Catchment Areas (Porteous Figure 4)
# =============================================================================

catchment_path <- here("Assignment_2", "data", "extracted", "data",
                       "1.-Price--Production--and-Population-Data",
                       "Catchments", "MktCatch6Plus5_Dissolve.shp")

if (file.exists(catchment_path)) {
  catchments <- st_read(catchment_path, quiet = TRUE)
  catchments_wgs84 <- st_transform(catchments, crs = 4326)
  
  n_catchments <- nrow(catchments_wgs84)
  catchments_wgs84$fill_color <- gray(runif(n_catchments, 0.25, 0.85))
  
  fig_16 <- ggplot() +
    geom_sf(data = catchments_wgs84, aes(fill = fill_color),
            color = "white", linewidth = 0.1, show.legend = FALSE) +
    scale_fill_identity() +
    geom_sf(data = africa, fill = NA, color = "darkred", linewidth = 0.5) +
    geom_sf(data = markets_sf, color = "black", size = 1) +
    coord_sf(xlim = c(-20, 55), ylim = c(-37, 40)) +
    labs(title = "230 Market Catchment Areas",
         subtitle = "Each shaded region represents the area served by its nearest market",
         caption = "Methodology based on Pozzi and Robinson (2008)") +
    theme_void() +
    theme(plot.title = element_text(size = 14, face = "bold", hjust = 0.5),
          plot.subtitle = element_text(size = 10, color = "grey40", hjust = 0.5),
          plot.caption = element_text(size = 8, color = "grey50", face = "italic"))
  
  ggsave(file.path(output_dir, "16_market_catchment_areas.pdf"),
         fig_16, width = 10, height = 12)
} else {
  message("Catchment shapefile not found at: ", catchment_path)
}

cat("\n=== Analysis Complete ===\n")
