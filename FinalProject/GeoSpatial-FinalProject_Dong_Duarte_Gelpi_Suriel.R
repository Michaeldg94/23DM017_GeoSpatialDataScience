# =============================================================================
# Course: Geospatial Data Sciences and Economic Spatial Models (BSE)
# Final Project - March 2026
#
# Data sources (all from official Barcelona Open Data):
#   - Neighbourhood boundaries: Ajuntament de Barcelona, Open Data BCN
#   - Income: Renda disponible de les llars per capita (2022), Open Data BCN
#   - Population: Padro municipal d'habitants (2025), Open Data BCN
#   - POIs: OpenStreetMap via osmdata package
# =============================================================================

# 0. Setup -------------------------------------------------------------------

if (!require("pacman")) install.packages("pacman")

pacman::p_load(
  sf, dplyr, tidyr, readr, stringr, ggplot2,
  osmdata,
  spdep, spatialreg,
  viridis, patchwork, scales, units
)

project_dir <- getwd()
data_dir    <- file.path(project_dir, "data")
output_dir  <- file.path(project_dir, "output")

if (!dir.exists(data_dir))   dir.create(data_dir, recursive = TRUE)
if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)

# Projected CRS for Barcelona (metric distances)
crs_proj <- "EPSG:25831"  # ETRS89 / UTM zone 31N

# City center reference point: Placa Catalunya
pt_center <- st_sfc(st_point(c(2.1700, 41.3870)), crs = 4326) |>
  st_transform(crs_proj)

# Walking-distance threshold: 1,200 m ~ 15-minute walk at 4.8 km/h
walk_buffer_m <- 1200

# Custom map theme (matching course style)
theme_map <- function(...) {
  theme_void() +
    theme(
      plot.title    = element_text(size = 11, face = "bold", hjust = 0),
      plot.subtitle = element_text(size = 9, color = "grey40", hjust = 0),
      legend.position  = "right",
      legend.key.width = unit(0.4, "cm"),
      plot.margin = margin(5, 5, 5, 5),
      ...
    )
}

# 1. Data Acquisition --------------------------------------------------------

# 1.1 Barcelona neighbourhood boundaries ------------------------------------
# Source: Ajuntament de Barcelona, Open Data BCN
# Dataset: "Unitats administratives de la ciutat de Barcelona"
# URL: https://opendata-ajuntament.barcelona.cat/data/en/dataset/20170706-districtes-barris
# Format: CSV with WGS84 geometry (WKT) for each barri

barris_file <- file.path(data_dir, "bcn_barris.csv")

if (!file.exists(barris_file)) {
  message("Downloading Barcelona neighbourhood boundaries...")
  download.file(
    url = paste0(
      "https://opendata-ajuntament.barcelona.cat/data/dataset/",
      "808daafa-d9ce-48c0-925a-fa5afdb1ed41/resource/",
      "b21fa550-56ea-4f4c-9adc-b8009381896e/download"
    ),
    destfile = barris_file,
    mode = "wb"
  )
}

df_barris_raw <- read_csv(barris_file, show_col_types = FALSE)

sf_nbhoods <- df_barris_raw |>
  st_as_sf(wkt = "geometria_wgs84", crs = 4326) |>
  st_transform(crs_proj) |>
  select(
    codi_districte, nom_districte,
    codi_barri, nom_barri
  ) |>
  rename(neighbourhood = nom_barri) |>
  st_set_geometry("geometria_wgs84")  # ensure clean geometry column name

# Rename geometry column to standard "geometry"
names(sf_nbhoods)[names(sf_nbhoods) == attr(sf_nbhoods, "sf_column")] <- "geometry"
st_geometry(sf_nbhoods) <- "geometry"

message("Loaded ", nrow(sf_nbhoods), " barris")

# 1.2 Household income data -------------------------------------------------
# Source: Ajuntament de Barcelona, Open Data BCN
# Dataset: "Renda disponible de les llars per capita (EUR)"
# Year: 2022 (most recent available)
# URL: https://opendata-ajuntament.barcelona.cat/data/es/dataset/renda-disponible-llars-bcn
# Note: data at census-section level; we aggregate to barri (mean income)

income_file <- file.path(data_dir, "renda_2022.csv")

if (!file.exists(income_file)) {
  message("Downloading 2022 household income data...")
  download.file(
    url = paste0(
      "https://opendata-ajuntament.barcelona.cat/data/dataset/",
      "78db0c75-fa56-4604-9510-8b92834a7fd2/resource/",
      "3df0c5b9-de69-4c94-b924-57540e52932f/download/",
      "2022_renda_disponible_llars_per_persona.csv"
    ),
    destfile = income_file,
    mode = "wb"
  )
}

df_income <- read_csv(income_file, show_col_types = FALSE) |>
  group_by(Codi_Barri, Nom_Barri) |>
  summarise(income_eur = mean(Import_Euros, na.rm = TRUE), .groups = "drop")

# Compute RFD-style index (Barcelona average = 100)
bcn_avg_income <- mean(df_income$income_eur, na.rm = TRUE)
df_income <- df_income |>
  mutate(rfd_index = (income_eur / bcn_avg_income) * 100)

message("Income data: ", nrow(df_income), " barris, Barcelona avg = ",
        round(bcn_avg_income, 0), " EUR/person")

# 1.3 Population data -------------------------------------------------------
# Source: Ajuntament de Barcelona, Open Data BCN
# Dataset: "Padro municipal d'habitants" (2025, as of 1 Jan)
# URL: https://opendata-ajuntament.barcelona.cat/data/es/dataset/pad_mdbas
# Note: data at census-section level; we aggregate to barri (sum)

pop_file <- file.path(data_dir, "poblacio_2025.csv")

if (!file.exists(pop_file)) {
  message("Downloading 2025 population data...")
  download.file(
    url = paste0(
      "https://opendata-ajuntament.barcelona.cat/data/dataset/",
      "2f6e0561-30f4-44a0-8446-e27442d4754c/resource/",
      "eb82adf2-a7b0-40e6-9624-b4b9eff23018/download"
    ),
    destfile = pop_file,
    mode = "wb"
  )
}

df_pop <- read_csv(pop_file, show_col_types = FALSE) |>
  group_by(Codi_Barri, Nom_Barri) |>
  summarise(population = sum(Valor, na.rm = TRUE), .groups = "drop")

message("Population data: ", nrow(df_pop), " barris, total = ",
        format(sum(df_pop$population), big.mark = ","))

# 1.4 Download POIs from OpenStreetMap --------------------------------------

message("Downloading POIs from OpenStreetMap for Barcelona...")

bbox_bcn <- c(2.0528, 41.3200, 2.2282, 41.4680)

# Helper: download OSM POIs with retry logic for Overpass API reliability
get_osm_pois <- function(key, value, bbox = bbox_bcn, max_retries = 5) {
  for (attempt in seq_len(max_retries)) {
    result <- tryCatch(
      {
        opq(bbox = bbox, timeout = 120) |>
          add_osm_feature(key = key, value = value) |>
          osmdata_sf()
      },
      error = function(e) {
        if (attempt < max_retries) {
          wait <- 10 * attempt
          message("    Overpass error (attempt ", attempt, "/", max_retries,
                  "): ", conditionMessage(e),
                  "\n    Retrying in ", wait, "s...")
          Sys.sleep(wait)
        }
        NULL
      }
    )
    if (!is.null(result)) break
  }

  if (is.null(result)) {
    warning("Failed to download ", key, "=", value, " after ", max_retries,
            " attempts. Returning empty set.")
    return(st_sf(geometry = st_sfc(crs = crs_proj)))
  }

  # Combine points and polygon centroids
  pts <- result$osm_points
  if (!is.null(result$osm_polygons) && nrow(result$osm_polygons) > 0) {
    poly_centroids <- st_centroid(result$osm_polygons) |>
      select(geometry)
    if (!is.null(pts) && nrow(pts) > 0) {
      pts <- bind_rows(pts |> select(geometry), poly_centroids)
    } else {
      pts <- poly_centroids
    }
  } else if (!is.null(pts) && nrow(pts) > 0) {
    pts <- pts |> select(geometry)
  } else {
    pts <- st_sf(geometry = st_sfc(crs = 4326))
  }

  # Brief pause between queries to avoid rate limiting
  Sys.sleep(3)

  pts |> st_transform(crs_proj)
}

# Download each service category (cached to RDS for speed)
poi_file <- file.path(data_dir, "pois_all.rds")

if (!file.exists(poi_file)) {
  message("  Grocery/supermarket...")
  sf_grocery <- bind_rows(
    get_osm_pois("shop", "supermarket"),
    get_osm_pois("shop", "grocery"),
    get_osm_pois("shop", "convenience")
  ) |> mutate(category = "Grocery")

  message("  Pharmacy...")
  sf_pharmacy <- get_osm_pois("amenity", "pharmacy") |>
    mutate(category = "Pharmacy")

  message("  Primary school...")
  sf_school <- get_osm_pois("amenity", "school") |>
    mutate(category = "School")

  message("  Healthcare (clinic/hospital/doctors)...")
  sf_health <- bind_rows(
    get_osm_pois("amenity", "clinic"),
    get_osm_pois("amenity", "hospital"),
    get_osm_pois("amenity", "doctors"),
    get_osm_pois("healthcare", "centre")
  ) |> mutate(category = "Healthcare")

  message("  Park/green space...")
  sf_park <- get_osm_pois("leisure", "park") |>
    mutate(category = "Park")

  message("  Public transport (metro/bus stops)...")
  sf_transit <- bind_rows(
    get_osm_pois("railway", "station"),
    get_osm_pois("railway", "halt"),
    get_osm_pois("highway", "bus_stop"),
    get_osm_pois("public_transport", "stop_position"),
    get_osm_pois("amenity", "bus_station")
  ) |> mutate(category = "Transit")

  # Combine all POIs
  sf_pois <- bind_rows(
    sf_grocery, sf_pharmacy, sf_school,
    sf_health, sf_park, sf_transit
  )

  # Clip to Barcelona boundary
  sf_bcn_boundary <- sf_nbhoods |> st_union()
  sf_pois <- sf_pois[st_intersects(sf_pois, sf_bcn_boundary,
                                    sparse = FALSE)[, 1], ]

  saveRDS(sf_pois, poi_file)
  message("POIs saved to ", poi_file)
} else {
  sf_pois <- readRDS(poi_file)
  message("POIs loaded from cache (", nrow(sf_pois), " features)")
}

# Summary of POIs by category
poi_summary <- sf_pois |>
  st_drop_geometry() |>
  count(category, name = "n_pois")
message("\nPOI counts:")
print(poi_summary)

# 2. Data Wrangling ----------------------------------------------------------

# 2.1 Compute neighbourhood area and centroids
sf_nbhoods$area_km2 <- as.numeric(st_area(sf_nbhoods)) / 1e6

# Compute centroids as an sfc column
centroid_sfc <- st_centroid(st_geometry(sf_nbhoods))

# 2.2 Distance from centroid to city center
sf_nbhoods$dist_center_km <- as.numeric(
  st_distance(centroid_sfc, pt_center, by_element = FALSE)[, 1]
) / 1000

# 2.3 Compute accessibility score -------------------------------------------
# For each neighbourhood centroid, buffer by 1,200 m and count the number of
# POIs of each category that fall within that buffer. The composite score is the
# total POI count, giving a continuous measure of service density.

categories <- c("Grocery", "Pharmacy", "School", "Healthcare", "Park", "Transit")

# Create centroid buffers
sf_centroid_buffers <- st_sf(
  neighbourhood = sf_nbhoods$neighbourhood,
  geometry = st_buffer(centroid_sfc, dist = walk_buffer_m)
)

# Function: count POIs of a given category within each buffer
count_access <- function(cat_name, buffers, pois) {
  cat_pois <- pois |> filter(category == cat_name)
  intersections <- st_intersects(buffers, cat_pois)
  lengths(intersections)
}

# Apply to each category
for (cat in categories) {
  col_name <- paste0("n_", tolower(cat))
  sf_nbhoods[[col_name]] <- count_access(cat, sf_centroid_buffers, sf_pois)
}

# Composite accessibility score: total POI count across all categories
count_cols <- paste0("n_", tolower(categories))

sf_nbhoods <- sf_nbhoods |>
  mutate(access_score = rowSums(across(all_of(count_cols))))

# 2.4 Join socioeconomic data ------------------------------------------------
# Match on barri code (robust to name encoding differences)
sf_nbhoods <- sf_nbhoods |>
  mutate(codi_barri = as.integer(codi_barri))

df_income <- df_income |>
  mutate(Codi_Barri = as.integer(Codi_Barri))

df_pop <- df_pop |>
  mutate(Codi_Barri = as.integer(Codi_Barri))

sf_analysis <- sf_nbhoods |>
  left_join(df_income |> select(Codi_Barri, income_eur, rfd_index),
            by = c("codi_barri" = "Codi_Barri")) |>
  left_join(df_pop |> select(Codi_Barri, population),
            by = c("codi_barri" = "Codi_Barri")) |>
  filter(!is.na(income_eur), !is.na(population), population > 0)

# Compute derived variables
sf_analysis <- sf_analysis |>
  mutate(
    pop_density      = population / area_km2,
    log_access       = log(access_score + 1),
    log_rfd_index    = log(rfd_index),
    log_income       = log(income_eur),
    log_pop_density  = log(pop_density),
    log_dist_center  = log(dist_center_km)
  )

# Ensure geometry column is active
sf_analysis <- st_sf(sf_analysis)

# Summary
message("\nAnalysis dataset: ", nrow(sf_analysis), " neighbourhoods")
message("Access score range: ", min(sf_analysis$access_score), " - ",
        max(sf_analysis$access_score))
message("Mean access score: ", round(mean(sf_analysis$access_score), 2))
message("Income range: ", round(min(sf_analysis$income_eur)), " - ",
        round(max(sf_analysis$income_eur)), " EUR/person")

# 3. Descriptive Analysis & Maps ---------------------------------------------

# 3.1 Summary statistics table -----------------------------------------------
df_summary <- sf_analysis |>
  st_drop_geometry() |>
  summarise(
    across(
      c(access_score, rfd_index, income_eur, population, pop_density,
        dist_center_km),
      list(mean = ~mean(., na.rm = TRUE), sd = ~sd(., na.rm = TRUE),
           min = ~min(., na.rm = TRUE), max = ~max(., na.rm = TRUE)),
      .names = "{.col}__{.fn}"
    )
  ) |>
  pivot_longer(
    everything(),
    names_to = c("variable", "stat"),
    names_sep = "__"
  ) |>
  pivot_wider(names_from = stat, values_from = value) |>
  mutate(across(where(is.numeric), ~round(., 2)))

message("\n--- Summary Statistics ---")
print(as.data.frame(df_summary), row.names = FALSE)

# Mean POI counts per category
service_rates <- sf_analysis |>
  st_drop_geometry() |>
  summarise(across(all_of(count_cols), list(
    mean = ~round(mean(.), 1),
    min  = ~min(.),
    max  = ~max(.)
  ), .names = "{.col}__{.fn}")) |>
  pivot_longer(everything(),
               names_to = c("service", "stat"), names_sep = "__") |>
  pivot_wider(names_from = stat, values_from = value) |>
  mutate(service = str_remove(service, "n_") |> str_to_title())
message("\nMean POI counts per category within 1200m buffer:")
print(as.data.frame(service_rates), row.names = FALSE)

# 3.2 Figure 1: POI locations by category ------------------------------------

fig_01 <- ggplot() +
  geom_sf(data = sf_analysis, fill = "grey95", color = "grey70",
          linewidth = 0.15) +
  geom_sf(data = sf_pois, aes(color = category), size = 0.3, alpha = 0.5) +
  scale_color_viridis_d(name = "Service\ncategory", option = "turbo") +
  labs(
    title = "Essential Services in Barcelona",
    subtitle = "Points of interest from OpenStreetMap"
  ) +
  theme_map()

ggsave(file.path(output_dir, "01_poi_locations.pdf"),
       fig_01, width = 8, height = 7)

# 3.3 Figure 2: Choropleth of accessibility score ----------------------------

fig_02 <- ggplot() +
  geom_sf(data = sf_analysis, aes(fill = access_score),
          color = "white", linewidth = 0.2) +
  scale_fill_viridis_c(
    name = "Total\nPOIs",
    option = "mako", direction = -1
  ) +
  labs(
    title = "15-Minute City Accessibility Score",
    subtitle = "Total essential service POIs within a 15-minute walk (1,200 m buffer)"
  ) +
  theme_map()

ggsave(file.path(output_dir, "02_accessibility_score_map.pdf"),
       fig_02, width = 8, height = 7)

# 3.4 Figure 3: Choropleth of income -----------------------------------------

fig_03 <- ggplot() +
  geom_sf(data = sf_analysis, aes(fill = income_eur / 1000),
          color = "white", linewidth = 0.2) +
  scale_fill_viridis_c(
    name = "Income\n(thousand\nEUR/person)",
    option = "magma", direction = -1
  ) +
  labs(
    title = "Disposable Household Income per Capita by Neighbourhood",
    subtitle = "Renda disponible de les llars, 2022 (Ajuntament de Barcelona)"
  ) +
  theme_map()

ggsave(file.path(output_dir, "03_income_map.pdf"),
       fig_03, width = 8, height = 7)

# 3.5 Figure 4: Scatter of accessibility vs income ---------------------------

fig_04 <- ggplot(sf_analysis, aes(x = income_eur / 1000, y = access_score)) +
  geom_point(aes(size = population / 1000), alpha = 0.6, color = "#2c7bb6") +
  geom_smooth(method = "lm", se = TRUE, color = "firebrick",
              linewidth = 0.8) +
  scale_size_continuous(name = "Pop.\n(thousands)") +
  labs(
    title = "Accessibility vs. Household Income",
    x = "Disposable income per capita (thousand EUR, 2022)",
    y = "Accessibility score (total POIs within 15-min walk)"
  ) +
  theme_minimal() +
  theme(plot.title = element_text(size = 11, face = "bold"))

ggsave(file.path(output_dir, "04_access_vs_income_scatter.pdf"),
       fig_04, width = 7, height = 5)

# 4. Spatial Weights Matrix --------------------------------------------------

nb_queen <- poly2nb(sf_analysis, queen = TRUE)
w_queen  <- nb2listw(nb_queen, style = "W", zero.policy = TRUE)

message("\n--- Spatial Weights Summary ---")
summary(nb_queen)

# 5. Spatial Autocorrelation -------------------------------------------------

# 5.1 Global Moran's I on accessibility score --------------------------------
moran_access <- moran.test(
  sf_analysis$access_score, w_queen, zero.policy = TRUE
)

message("\n--- Global Moran's I: Accessibility Score ---")
print(moran_access)

# 5.2 Local Moran's I (LISA) -------------------------------------------------
lisa <- localmoran(sf_analysis$access_score, w_queen, zero.policy = TRUE)

sf_analysis <- sf_analysis |>
  mutate(
    lisa_i = lisa[, 1],
    lisa_p = lisa[, 5],
    # Spatial lag of the standardised score
    score_std = as.numeric(scale(access_score)),
    lag_std   = lag.listw(w_queen, score_std, zero.policy = TRUE),
    # LISA cluster classification
    lisa_cluster = case_when(
      lisa_p > 0.05                    ~ "Not significant",
      score_std > 0 & lag_std > 0      ~ "High-High",
      score_std < 0 & lag_std < 0      ~ "Low-Low",
      score_std > 0 & lag_std < 0      ~ "High-Low",
      score_std < 0 & lag_std > 0      ~ "Low-High",
      TRUE                             ~ "Not significant"
    ),
    lisa_cluster = factor(
      lisa_cluster,
      levels = c("High-High", "Low-Low", "High-Low", "Low-High",
                 "Not significant")
    )
  )

# 5.3 Figure 5: LISA cluster map ---------------------------------------------

lisa_colors <- c(
  "High-High"       = "#d7191c",
  "Low-Low"         = "#2c7bb6",
  "High-Low"        = "#fdae61",
  "Low-High"        = "#abd9e9",
  "Not significant" = "grey90"
)

fig_05 <- ggplot() +
  geom_sf(data = sf_analysis, aes(fill = lisa_cluster),
          color = "white", linewidth = 0.2) +
  scale_fill_manual(values = lisa_colors, name = "LISA cluster",
                    drop = FALSE) +
  labs(
    title = "Local Spatial Autocorrelation of Accessibility",
    subtitle = paste0("Global Moran's I = ",
                      round(moran_access$estimate[1], 3),
                      ", p = ",
                      format.pval(moran_access$p.value, digits = 3))
  ) +
  theme_map()

ggsave(file.path(output_dir, "05_lisa_clusters_map.pdf"),
       fig_05, width = 8, height = 7)

# 5.4 Figure 6: Moran scatter plot -------------------------------------------

fig_06 <- ggplot(sf_analysis, aes(x = score_std, y = lag_std)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey60") +
  geom_vline(xintercept = 0, linetype = "dashed", color = "grey60") +
  geom_point(aes(color = lisa_cluster), size = 2, alpha = 0.7) +
  geom_smooth(method = "lm", se = FALSE, color = "black",
              linewidth = 0.7) +
  scale_color_manual(values = lisa_colors, name = "LISA cluster",
                     drop = FALSE) +
  labs(
    title = "Moran Scatter Plot: Accessibility Score",
    x = "Accessibility score (standardised)",
    y = "Spatially lagged accessibility (standardised)"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 11, face = "bold"),
    legend.position = "bottom"
  )

ggsave(file.path(output_dir, "06_moran_scatter.pdf"),
       fig_06, width = 7, height = 6)

# 6. OLS Baseline Regression -------------------------------------------------

reg_formula <- log_access ~ log_income + log_pop_density + log_dist_center

ols_model <- lm(reg_formula, data = sf_analysis)

message("\n--- OLS Regression Results ---")
print(summary(ols_model))

# Moran's I test on OLS residuals
moran_resid <- lm.morantest(ols_model, w_queen, zero.policy = TRUE)
message("\n--- Moran's I on OLS Residuals ---")
print(moran_resid)

# Lagrange Multiplier tests for spatial model selection
lm_tests <- lm.RStests(
  ols_model, w_queen,
  test = c("RSlag", "RSerr", "adjRSlag", "adjRSerr"),
  zero.policy = TRUE
)
message("\n--- Lagrange Multiplier Tests ---")
print(summary(lm_tests))

# 7. Spatial Models: SAR, SEM, SDM, SDEM ------------------------------------
# Following LeSage and Pace (2009), we estimate a family of spatial models
# and compare them. The Spatial Durbin Model (SDM) is the most general
# specification: it includes both a spatial lag of Y and spatial lags of X.
# This allows decomposing the income effect into direct (own-neighbourhood)
# and indirect (spillover) components.

# 7.1 Spatial Lag Model (SAR) ------------------------------------------------
sar_model <- lagsarlm(
  reg_formula, data = sf_analysis, listw = w_queen, zero.policy = TRUE
)
message("\n--- Spatial Lag Model (SAR) ---")
print(summary(sar_model))

# 7.2 Spatial Error Model (SEM) ----------------------------------------------
sem_model <- errorsarlm(
  reg_formula, data = sf_analysis, listw = w_queen, zero.policy = TRUE
)
message("\n--- Spatial Error Model (SEM) ---")
print(summary(sem_model))

# 7.3 Spatial Durbin Model (SDM) ---------------------------------------------
# Adds spatial lags of the X variables (W*X) alongside the spatial lag of Y.
# This is the recommended default (LeSage & Pace, 2009) because:
#   - SAR is a special case of SDM (when W*X coefficients = 0)
#   - SEM is a special case of SDM (when W*X = -rho * beta)
#   - SDM captures global spillovers: a change in X_i propagates to all
#     neighbours through the spatial multiplier (I - rho*W)^{-1}
sdm_model <- lagsarlm(
  reg_formula, data = sf_analysis, listw = w_queen,
  Durbin = TRUE,
  zero.policy = TRUE
)
message("\n--- Spatial Durbin Model (SDM) ---")
print(summary(sdm_model))

# 7.4 Spatial Durbin Error Model (SDEM) --------------------------------------
# Like SDM but with a spatial error process instead of a spatial lag of Y.
# Captures local spillovers only (effects limited to immediate neighbours).
sdem_model <- errorsarlm(
  reg_formula, data = sf_analysis, listw = w_queen,
  Durbin = TRUE,
  zero.policy = TRUE
)
message("\n--- Spatial Durbin Error Model (SDEM) ---")
print(summary(sdem_model))

# 8. Model Comparison & Selection --------------------------------------------

# 8.1 AIC / Log-likelihood comparison ----------------------------------------
aic_table <- data.frame(
  Model  = c("OLS", "SAR", "SEM", "SDM", "SDEM"),
  AIC    = c(AIC(ols_model), AIC(sar_model), AIC(sem_model),
             AIC(sdm_model), AIC(sdem_model)),
  logLik = c(logLik(ols_model), logLik(sar_model), logLik(sem_model),
             logLik(sdm_model), logLik(sdem_model))
)
aic_table <- aic_table |> arrange(AIC)

message("\n")
message("=============================================================")
message("              MODEL COMPARISON (AIC / Log-Likelihood)        ")
message("=============================================================")
message("Dependent variable: log(accessibility score + 1)")
message("-------------------------------------------------------------")
print(aic_table, row.names = FALSE)

# 8.2 Likelihood ratio tests between nested models ---------------------------
# SDM vs SAR: are spatially lagged X terms jointly significant?
lr_sdm_sar <- as.numeric(2 * (logLik(sdm_model) - logLik(sar_model)))
lr_sdm_sar_df <- length(coef(sdm_model)) - length(coef(sar_model))
lr_sdm_sar_p  <- pchisq(lr_sdm_sar, df = lr_sdm_sar_df, lower.tail = FALSE)

# SDEM vs SEM: same test for the error family
lr_sdem_sem <- as.numeric(2 * (logLik(sdem_model) - logLik(sem_model)))
lr_sdem_sem_df <- length(coef(sdem_model)) - length(coef(sem_model))
lr_sdem_sem_p  <- pchisq(lr_sdem_sem, df = lr_sdem_sem_df, lower.tail = FALSE)

message("\n--- Likelihood Ratio Tests ---")
message(sprintf("  SDM vs SAR:   LR = %.3f, df = %d, p = %.4f %s",
                lr_sdm_sar, lr_sdm_sar_df, lr_sdm_sar_p,
                ifelse(lr_sdm_sar_p < 0.05, "*", "")))
message(sprintf("  SDEM vs SEM:  LR = %.3f, df = %d, p = %.4f %s",
                lr_sdem_sem, lr_sdem_sem_df, lr_sdem_sem_p,
                ifelse(lr_sdem_sem_p < 0.05, "*", "")))

# 8.3 Select best model and compute impacts ----------------------------------
# Identify best model by AIC
best_name <- aic_table$Model[1]
message("\nBest model by AIC: ", best_name)

# Compute impacts for SDM (the most informative decomposition)
# SDM impacts decompose each covariate into:
#   Direct   = effect of X_i on Y_i (own neighbourhood)
#   Indirect = effect of X_i on Y_j (spillover to neighbours)
#   Total    = Direct + Indirect
sdm_impacts <- impacts(sdm_model, listw = w_queen, R = 500)
message("\n--- SDM: Direct, Indirect, and Total Effects ---")
print(summary(sdm_impacts, zstats = TRUE, short = TRUE))

# Also compute SAR impacts for comparison
sar_impacts <- impacts(sar_model, listw = w_queen, R = 500)
message("\n--- SAR: Direct, Indirect, and Total Effects ---")
print(summary(sar_impacts, zstats = TRUE, short = TRUE))

# 8.4 Summary table ----------------------------------------------------------
message("\n")
message("=============================================================")
message("      COEFFICIENT COMPARISON ACROSS SPATIAL MODELS           ")
message("=============================================================")
message("Dependent variable: log(accessibility score + 1)")
message("-------------------------------------------------------------")

ols_coefs <- coef(summary(ols_model))
sar_coefs <- summary(sar_model)$Coef
sdm_coefs <- summary(sdm_model)$Coef

x_vars <- c("log_income", "log_pop_density", "log_dist_center")

message(sprintf("  %-22s  %12s  %12s  %12s",
                "Variable", "OLS", "SAR", "SDM"))
message("  ", paste(rep("-", 62), collapse = ""))

for (v in x_vars) {
  ols_str <- sprintf("%6.3f (%5.3f)", ols_coefs[v, 1], ols_coefs[v, 2])
  sar_str <- sprintf("%6.3f (%5.3f)", sar_coefs[v, 1], sar_coefs[v, 2])
  sdm_str <- sprintf("%6.3f (%5.3f)", sdm_coefs[v, 1], sdm_coefs[v, 2])
  message(sprintf("  %-22s  %12s  %12s  %12s", v, ols_str, sar_str, sdm_str))
}

# Spatial lag of X terms (SDM only)
lag_vars <- paste0("lag.", x_vars)
for (v in lag_vars) {
  if (v %in% rownames(sdm_coefs)) {
    sdm_str <- sprintf("%6.3f (%5.3f)", sdm_coefs[v, 1], sdm_coefs[v, 2])
    message(sprintf("  %-22s  %12s  %12s  %12s", v, "---", "---", sdm_str))
  }
}

message(sprintf("  %-22s  %12s  %12s  %12s",
                "rho", "---",
                sprintf("%6.3f (%5.3f)", sar_model$rho, sar_model$rho.se),
                sprintf("%6.3f (%5.3f)", sdm_model$rho, sdm_model$rho.se)))
message("  ", paste(rep("-", 62), collapse = ""))
message(sprintf("  %-22s  %12.1f  %12.1f  %12.1f",
                "AIC", AIC(ols_model), AIC(sar_model), AIC(sdm_model)))
message(sprintf("  %-22s  %12.1f  %12.1f  %12.1f",
                "Log-likelihood",
                as.numeric(logLik(ols_model)),
                as.numeric(logLik(sar_model)),
                as.numeric(logLik(sdm_model))))
message(sprintf("  %-22s  %12.3f  %12s  %12s",
                "R-squared", summary(ols_model)$r.squared, "---", "---"))
message(sprintf("  %-22s  Moran p = %s",
                "Resid. spatial dep.", format.pval(moran_resid$p.value, 3)))
message("=============================================================")
message("N = ", nrow(sf_analysis), " neighbourhoods")
message("Spatial weights: Queen contiguity, row-standardised")
message("=============================================================")

# 8.5 Figure 7: Side-by-side accessibility and income maps -------------------

p_access <- ggplot() +
  geom_sf(data = sf_analysis, aes(fill = access_score),
          color = "white", linewidth = 0.15) +
  scale_fill_viridis_c(
    name = "Total\nPOIs", option = "mako", direction = -1
  ) +
  labs(title = "Accessibility") +
  theme_map(legend.key.height = unit(0.8, "cm"))

p_income <- ggplot() +
  geom_sf(data = sf_analysis, aes(fill = income_eur / 1000),
          color = "white", linewidth = 0.15) +
  scale_fill_viridis_c(
    name = "Income\n(k EUR)", option = "magma", direction = -1
  ) +
  labs(title = "Household Income") +
  theme_map(legend.key.height = unit(0.8, "cm"))

fig_07 <- p_access + p_income +
  plot_annotation(
    title = "Accessibility and Income Across Barcelona Neighbourhoods",
    theme = theme(plot.title = element_text(size = 12, face = "bold"))
  )

ggsave(file.path(output_dir, "07_access_income_sidebyside.pdf"),
       fig_07, width = 14, height = 6)

# 9. Robustness & Extensions -------------------------------------------------
# Motivated by critiques of the 15-minute city framework:
#   - Service overload: high POI counts may not mean adequate per-capita provision
#   - Equity non-linearity: the gap may be steepest for the poorest neighborhoods
#   - Category heterogeneity: which service types drive the overall inequality?
#   - Sensitivity to walking threshold: does the result hold at shorter distances?

# 9.1 Per-capita accessibility ------------------------------------------------
# Addresses the "service capacity" critique: dense areas may have many POIs but
# also many residents competing for them. POIs per 1,000 residents is a better
# measure of service adequacy.

sf_analysis <- sf_analysis |>
  mutate(
    access_per_capita = access_score / (population / 1000),
    log_access_pc     = log(access_per_capita + 1)
  )

ols_percap <- lm(
  log_access_pc ~ log_income + log_pop_density + log_dist_center,
  data = sf_analysis
)
message("\n--- Robustness: Per-Capita Accessibility (OLS) ---")
print(summary(ols_percap))

sdm_percap <- lagsarlm(
  log_access_pc ~ log_income + log_pop_density + log_dist_center,
  data = sf_analysis, listw = w_queen,
  Durbin = TRUE, zero.policy = TRUE
)
message("\n--- Robustness: Per-Capita Accessibility (SDM) ---")
print(summary(sdm_percap))

sdm_percap_impacts <- impacts(sdm_percap, listw = w_queen, R = 500)
message("\n--- Per-Capita SDM: Direct, Indirect, Total Effects ---")
print(summary(sdm_percap_impacts, zstats = TRUE, short = TRUE))

# 9.2 Non-linear income effects -----------------------------------------------
# Tests whether the income-accessibility relationship is steeper at the bottom
# of the income distribution (quadratic term in log income).

sf_analysis <- sf_analysis |>
  mutate(log_income_sq = log_income^2)

ols_nonlin <- lm(
  log_access ~ log_income + log_income_sq + log_pop_density + log_dist_center,
  data = sf_analysis
)
message("\n--- Robustness: Non-Linear Income Effect (OLS) ---")
print(summary(ols_nonlin))
message(sprintf("  Quadratic term p-value: %.4f",
                coef(summary(ols_nonlin))["log_income_sq", "Pr(>|t|)"]))

# 9.3 Category-specific income regressions ------------------------------------
# Identifies which service types drive the overall income-accessibility gap.
# Runs a separate OLS for each of the six categories.

message("\n--- Robustness: Category-Specific Income Elasticities ---")
message(sprintf("  %-15s  %8s  %8s  %8s", "Category", "Elast.", "Std.Err", "p-value"))
message("  ", paste(rep("-", 45), collapse = ""))

cat_results <- list()
for (cat in categories) {
  col <- paste0("n_", tolower(cat))
  sf_analysis[[paste0("log_", tolower(cat))]] <- log(sf_analysis[[col]] + 1)

  cat_mod <- lm(
    as.formula(paste0("log_", tolower(cat),
                      " ~ log_income + log_pop_density + log_dist_center")),
    data = sf_analysis
  )
  cat_coef <- coef(summary(cat_mod))["log_income", ]
  cat_results[[cat]] <- cat_coef

  message(sprintf("  %-15s  %8.3f  %8.3f  %8.4f %s",
                  cat, cat_coef[1], cat_coef[2], cat_coef[4],
                  ifelse(cat_coef[4] < 0.01, "***",
                         ifelse(cat_coef[4] < 0.05, "**",
                                ifelse(cat_coef[4] < 0.1, "*", "")))))
}

# 9.4 Figure 8: Category-specific income elasticities -------------------------

df_cat_elast <- tibble(
  category = names(cat_results),
  elasticity = sapply(cat_results, `[`, 1),
  se = sapply(cat_results, `[`, 2),
  p_value = sapply(cat_results, `[`, 4)
) |>
  mutate(
    significant = p_value < 0.05,
    category = factor(category, levels = category[order(elasticity)])
  )

fig_08 <- ggplot(df_cat_elast, aes(x = category, y = elasticity)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey60") +
  geom_pointrange(
    aes(ymin = elasticity - 1.96 * se, ymax = elasticity + 1.96 * se,
        color = significant),
    linewidth = 0.8, size = 0.8
  ) +
  scale_color_manual(values = c("TRUE" = "#d7191c", "FALSE" = "grey50"),
                     labels = c("TRUE" = "p < 0.05", "FALSE" = "p >= 0.05"),
                     name = "") +
  coord_flip() +
  labs(
    title = "Income Elasticity of Accessibility by Service Category",
    subtitle = "OLS coefficient on log(income), with 95% confidence intervals",
    x = NULL, y = "Income elasticity"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 11, face = "bold"),
    legend.position = "bottom"
  )

ggsave(file.path(output_dir, "08_category_income_elasticities.pdf"),
       fig_08, width = 7, height = 5)

# 9.5 Alternative buffer distance (800 m ~ 10-minute walk) --------------------
# Tests sensitivity of the main results to a stricter walking threshold.

walk_buffer_alt <- 800

sf_buffers_alt <- st_sf(
  neighbourhood = sf_nbhoods$neighbourhood,
  geometry = st_buffer(centroid_sfc, dist = walk_buffer_alt)
)

for (cat in categories) {
  col <- paste0("n_", tolower(cat), "_800m")
  cat_pois <- sf_pois |> filter(category == cat)
  sf_nbhoods[[col]] <- lengths(st_intersects(sf_buffers_alt, cat_pois))
}

alt_cols <- paste0("n_", tolower(categories), "_800m")
sf_nbhoods$access_800m <- rowSums(sf_nbhoods[, alt_cols] |> st_drop_geometry())

# Join to analysis dataset
sf_analysis$access_800m <- sf_nbhoods$access_800m[
  match(sf_analysis$codi_barri, sf_nbhoods$codi_barri)
]
sf_analysis <- sf_analysis |>
  mutate(log_access_800m = log(access_800m + 1))

ols_800m <- lm(
  log_access_800m ~ log_income + log_pop_density + log_dist_center,
  data = sf_analysis
)
message("\n--- Robustness: 800m Buffer (OLS) ---")
print(summary(ols_800m))

sdm_800m <- lagsarlm(
  log_access_800m ~ log_income + log_pop_density + log_dist_center,
  data = sf_analysis, listw = w_queen,
  Durbin = TRUE, zero.policy = TRUE
)
message("\n--- Robustness: 800m Buffer (SDM) ---")
print(summary(sdm_800m))

sdm_800m_impacts <- impacts(sdm_800m, listw = w_queen, R = 500)
message("\n--- 800m SDM: Direct, Indirect, Total Effects ---")
print(summary(sdm_800m_impacts, zstats = TRUE, short = TRUE))

# 9.6 Figure 9: Per-capita accessibility map ----------------------------------

fig_09 <- ggplot() +
  geom_sf(data = sf_analysis, aes(fill = access_per_capita),
          color = "white", linewidth = 0.2) +
  scale_fill_viridis_c(
    name = "POIs per\n1,000 pop.", option = "mako", direction = -1
  ) +
  labs(
    title = "Per-Capita Service Accessibility",
    subtitle = "POIs within 15-min walk per 1,000 residents"
  ) +
  theme_map()

ggsave(file.path(output_dir, "09_percapita_accessibility_map.pdf"),
       fig_09, width = 8, height = 7)

# 9.7 Summary of robustness checks -------------------------------------------

message("\n")
message("=============================================================")
message("              ROBUSTNESS CHECKS SUMMARY                      ")
message("=============================================================")

# Income coefficient across specifications
rob_income <- data.frame(
  Specification = c(
    "Baseline (1200m, total POIs)",
    "Per-capita (POIs/1000 pop)",
    "800m buffer (10-min walk)",
    "Non-linear (quadratic income)"
  ),
  Income_coef = c(
    coef(ols_model)["log_income"],
    coef(ols_percap)["log_income"],
    coef(ols_800m)["log_income"],
    coef(ols_nonlin)["log_income"]
  ),
  p_value = c(
    coef(summary(ols_model))["log_income", 4],
    coef(summary(ols_percap))["log_income", 4],
    coef(summary(ols_800m))["log_income", 4],
    coef(summary(ols_nonlin))["log_income", 4]
  )
)

rob_income$Income_coef <- round(rob_income$Income_coef, 3)
rob_income$p_value     <- round(rob_income$p_value, 4)

print(rob_income, row.names = FALSE)
message("=============================================================")

# 9.8 Gravity-weighted accessibility (structural analog) ---------------------
# Motivated by the gravity equation from quantitative spatial economics
# (Redding & Rossi-Hansberg, 2017; Lecture 8). In the structural model,
# market access is:  MA_n = Σ_i A_i * (w_i * d_{ni})^{-θ}
# Treating each POI as a unit of "supply", the gravity-weighted accessibility
# score for neighbourhood n is:
#   GravAccess_n = Σ_j exp(-β * d_{nj})
# where j indexes all POIs and β controls distance decay.
# This penalises services that are reachable but far away, unlike the simple
# buffer-based count which treats all POIs within 1,200m equally.

message("\n--- Extension: Gravity-Weighted Accessibility ---")

analysis_centroids <- st_centroid(st_geometry(sf_analysis))

# Compute distance from each centroid to every POI (matrix: n_barris × n_pois)
dist_to_pois <- st_distance(analysis_centroids, sf_pois)
dist_num <- matrix(as.numeric(dist_to_pois), nrow = nrow(sf_analysis))

# Distance decay parameter: β = 0.001 => half-life ≈ 693 m
beta_decay <- 0.001
gravity_scores <- rowSums(exp(-beta_decay * dist_num))

sf_analysis$gravity_access     <- gravity_scores
sf_analysis$log_gravity_access <- log(gravity_scores)

message("  Gravity accessibility range: ",
        round(min(sf_analysis$gravity_access), 1), " - ",
        round(max(sf_analysis$gravity_access), 1))

# OLS with gravity-weighted dependent variable
ols_gravity <- lm(
  log_gravity_access ~ log_income + log_pop_density + log_dist_center,
  data = sf_analysis
)
message("\n--- Gravity Accessibility OLS ---")
print(summary(ols_gravity))

# SDM with gravity-weighted dependent variable
sdm_gravity <- lagsarlm(
  log_gravity_access ~ log_income + log_pop_density + log_dist_center,
  data = sf_analysis, listw = w_queen,
  Durbin = TRUE, zero.policy = TRUE
)
message("\n--- Gravity Accessibility SDM ---")
print(summary(sdm_gravity))

sdm_gravity_impacts <- impacts(sdm_gravity, listw = w_queen, R = 500)
message("\n--- Gravity SDM: Direct, Indirect, Total Effects ---")
print(summary(sdm_gravity_impacts, zstats = TRUE, short = TRUE))

# 9.9 Market access control (Harris potential) --------------------------------
# Harris (1954) market potential: MA_n = Σ_{i≠n} Pop_i / d_{ni}
# This captures a neighbourhood's centrality relative to population mass,
# providing a structural alternative to the simple distance-to-center control.
# In the spatial GE framework, this is the denominator of the location choice
# probability (Lecture 8, Slide 16).

message("\n--- Extension: Market Access (Harris Potential) ---")

dist_nn <- st_distance(analysis_centroids)
dist_nn_num <- matrix(as.numeric(dist_nn), nrow = nrow(sf_analysis))
diag(dist_nn_num) <- Inf  # exclude self

pop_vec <- sf_analysis$population
market_access <- numeric(nrow(sf_analysis))
for (i in seq_len(nrow(sf_analysis))) {
  market_access[i] <- sum(pop_vec / dist_nn_num[i, ])
}

sf_analysis$market_access     <- market_access
sf_analysis$log_market_access <- log(market_access)

# OLS with market access replacing distance-to-center
ols_ma <- lm(
  log_access ~ log_income + log_pop_density + log_market_access,
  data = sf_analysis
)
message("\n--- OLS with Market Access Control ---")
print(summary(ols_ma))

# SDM with market access
sdm_ma <- lagsarlm(
  log_access ~ log_income + log_pop_density + log_market_access,
  data = sf_analysis, listw = w_queen,
  Durbin = TRUE, zero.policy = TRUE
)
message("\n--- SDM with Market Access Control ---")
print(summary(sdm_ma))

sdm_ma_impacts <- impacts(sdm_ma, listw = w_queen, R = 500)
message("\n--- Market Access SDM: Direct, Indirect, Total Effects ---")
print(summary(sdm_ma_impacts, zstats = TRUE, short = TRUE))

# 9.10 Accessibility inequality: Gini & Lorenz curve -------------------------
# The Gini coefficient quantifies the degree of inequality in accessibility.
# A Gini of 0 = perfectly equal distribution of services; 1 = all services
# in one neighbourhood. We compute Gini for total accessibility and by category.

message("\n--- Extension: Accessibility Inequality (Gini) ---")

gini <- function(x) {
  x <- sort(x[x > 0])
  n <- length(x)
  2 * sum(seq_len(n) * x) / (n * sum(x)) - (n + 1) / n
}

gini_total    <- gini(sf_analysis$access_score)
gini_percap   <- gini(sf_analysis$access_per_capita)
gini_gravity  <- gini(sf_analysis$gravity_access)

gini_by_cat <- sapply(categories, function(cat) {
  col <- paste0("n_", tolower(cat))
  gini(sf_analysis[[col]])
})

message(sprintf("  Gini (total POI count):      %.3f", gini_total))
message(sprintf("  Gini (per-capita):           %.3f", gini_percap))
message(sprintf("  Gini (gravity-weighted):     %.3f", gini_gravity))
message("  Gini by category:")
for (i in seq_along(categories)) {
  message(sprintf("    %-12s: %.3f", categories[i], gini_by_cat[i]))
}

# Lorenz curve data: population-weighted
lorenz_data <- sf_analysis |>
  st_drop_geometry() |>
  arrange(access_score) |>
  mutate(
    cum_pop    = cumsum(population) / sum(population),
    cum_access = cumsum(access_score * population) /
                 sum(access_score * population)
  )

# 9.11 Figure 10: Lorenz curve of accessibility --------------------------------

fig_10 <- ggplot(lorenz_data, aes(x = cum_pop, y = cum_access)) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed",
              color = "grey50") +
  geom_line(color = "#d7191c", linewidth = 1) +
  geom_ribbon(aes(ymin = cum_access, ymax = cum_pop),
              fill = "#d7191c", alpha = 0.15) +
  annotate("text", x = 0.65, y = 0.35,
           label = paste0("Gini = ", round(gini_total, 3)),
           size = 4, fontface = "bold") +
  labs(
    title = "Lorenz Curve: Distribution of Essential Services",
    subtitle = "Population-weighted; shaded area = inequality",
    x = "Cumulative share of population (ranked by accessibility)",
    y = "Cumulative share of services"
  ) +
  coord_equal() +
  theme_minimal() +
  theme(plot.title = element_text(size = 11, face = "bold"))

ggsave(file.path(output_dir, "10_lorenz_curve.pdf"),
       fig_10, width = 6, height = 6)

# 9.12 Figure 11: Gravity accessibility vs income scatter ---------------------

fig_11 <- ggplot(sf_analysis, aes(x = income_eur / 1000, y = gravity_access)) +
  geom_point(aes(size = population / 1000), alpha = 0.6, color = "#2c7bb6") +
  geom_smooth(method = "lm", se = TRUE, color = "firebrick",
              linewidth = 0.8) +
  scale_size_continuous(name = "Pop.\n(thousands)") +
  labs(
    title = "Gravity-Weighted Accessibility vs. Income",
    subtitle = paste0("Exponential decay (beta = ", beta_decay,
                      "); R-sq = ",
                      round(summary(ols_gravity)$r.squared, 2)),
    x = "Disposable income per capita (thousand EUR, 2022)",
    y = "Gravity-weighted accessibility score"
  ) +
  theme_minimal() +
  theme(plot.title = element_text(size = 11, face = "bold"))

ggsave(file.path(output_dir, "11_gravity_access_vs_income.pdf"),
       fig_11, width = 7, height = 5)

# 10. Save results for Rmd ---------------------------------------------------
# Export all key statistics so the Rmd can use inline R code instead of
# hardcoded numbers.

results <- list(
  # Data dimensions
  n_barris      = nrow(sf_analysis),
  n_pois_total  = nrow(sf_pois),
  poi_summary   = poi_summary,

  # Descriptive stats
  access_min  = min(sf_analysis$access_score),
  access_max  = max(sf_analysis$access_score),
  access_mean = mean(sf_analysis$access_score),
  income_min  = min(sf_analysis$income_eur),
  income_max  = max(sf_analysis$income_eur),
  rfd_min     = min(sf_analysis$rfd_index),
  rfd_max     = max(sf_analysis$rfd_index),
  popdens_min = min(sf_analysis$pop_density),
  popdens_max = max(sf_analysis$pop_density),
  avg_neighbors = mean(card(nb_queen)),

  # Moran's I
  moran_I     = moran_access$estimate[1],
  moran_p     = moran_access$p.value,
  moran_resid_I = moran_resid$statistic,
  moran_resid_p = moran_resid$p.value,

  # OLS
  ols_summary   = summary(ols_model),
  ols_coefs     = coef(summary(ols_model)),
  ols_r2        = summary(ols_model)$r.squared,
  ols_adjr2     = summary(ols_model)$adj.r.squared,
  ols_aic       = AIC(ols_model),
  ols_loglik    = as.numeric(logLik(ols_model)),

  # SAR
  sar_rho    = sar_model$rho,
  sar_rho_se = sar_model$rho.se,
  sar_aic    = AIC(sar_model),
  sar_loglik = as.numeric(logLik(sar_model)),

  # SEM
  sem_aic    = AIC(sem_model),
  sem_loglik = as.numeric(logLik(sem_model)),

  # SDM
  sdm_summary = summary(sdm_model),
  sdm_coefs   = summary(sdm_model)$Coef,
  sdm_rho     = sdm_model$rho,
  sdm_rho_se  = sdm_model$rho.se,
  sdm_rho_p   = summary(sdm_model)$Wald1$p.value,
  sdm_aic     = AIC(sdm_model),
  sdm_loglik  = as.numeric(logLik(sdm_model)),
  sdm_impacts_summary = summary(sdm_impacts, zstats = TRUE, short = TRUE),
  # Pre-extract impacts for easy inline access (1=income, 2=popdens, 3=distctr)
  sdm_direct   = summary(sdm_impacts, zstats = TRUE, short = TRUE)$res$direct,
  sdm_indirect = summary(sdm_impacts, zstats = TRUE, short = TRUE)$res$indirect,
  sdm_total    = summary(sdm_impacts, zstats = TRUE, short = TRUE)$res$total,
  sdm_pzmat    = summary(sdm_impacts, zstats = TRUE, short = TRUE)$pzmat,

  # SDEM
  sdem_lambda   = sdem_model$lambda,
  sdem_lambda_p = summary(sdem_model)$Wald1$p.value,
  sdem_aic      = AIC(sdem_model),
  sdem_loglik   = as.numeric(logLik(sdem_model)),

  # LR tests
  lr_sdm_sar   = lr_sdm_sar,
  lr_sdm_sar_p = lr_sdm_sar_p,
  lr_sdem_sem   = lr_sdem_sem,
  lr_sdem_sem_p = lr_sdem_sem_p,

  # Robustness: per-capita
  percap_ols_income_coef = coef(summary(ols_percap))["log_income", 1],
  percap_ols_income_p    = coef(summary(ols_percap))["log_income", 4],
  percap_ols_r2          = summary(ols_percap)$r.squared,

  # Robustness: non-linear
  nonlin_quad_coef = coef(summary(ols_nonlin))["log_income_sq", 1],
  nonlin_quad_p    = coef(summary(ols_nonlin))["log_income_sq", 4],

  # Robustness: category-specific
  cat_results = cat_results,

  # Robustness: 800m
  ols_800m_income_coef = coef(summary(ols_800m))["log_income", 1],
  ols_800m_income_p    = coef(summary(ols_800m))["log_income", 4],
  sdm_800m_rho         = sdm_800m$rho,
  sdm_800m_rho_p       = summary(sdm_800m)$Wald1$p.value,
  sdm_800m_coefs       = summary(sdm_800m)$Coef,

  # Extension: gravity-weighted accessibility
  gravity_ols_income_coef = coef(summary(ols_gravity))["log_income", 1],
  gravity_ols_income_p    = coef(summary(ols_gravity))["log_income", 4],
  gravity_ols_r2          = summary(ols_gravity)$r.squared,
  gravity_sdm_rho         = sdm_gravity$rho,
  gravity_sdm_rho_p       = summary(sdm_gravity)$Wald1$p.value,
  gravity_sdm_impacts     = summary(sdm_gravity_impacts, zstats = TRUE, short = TRUE),
  gravity_sdm_direct      = summary(sdm_gravity_impacts, zstats = TRUE, short = TRUE)$res$direct,
  gravity_sdm_indirect    = summary(sdm_gravity_impacts, zstats = TRUE, short = TRUE)$res$indirect,
  gravity_sdm_total       = summary(sdm_gravity_impacts, zstats = TRUE, short = TRUE)$res$total,
  gravity_sdm_pzmat       = summary(sdm_gravity_impacts, zstats = TRUE, short = TRUE)$pzmat,
  beta_decay              = beta_decay,

  # Extension: market access
  ma_ols_income_coef = coef(summary(ols_ma))["log_income", 1],
  ma_ols_income_p    = coef(summary(ols_ma))["log_income", 4],
  ma_ols_r2          = summary(ols_ma)$r.squared,
  ma_ols_ma_coef     = coef(summary(ols_ma))["log_market_access", 1],
  ma_ols_ma_p        = coef(summary(ols_ma))["log_market_access", 4],
  ma_sdm_rho         = sdm_ma$rho,
  ma_sdm_rho_p       = summary(sdm_ma)$Wald1$p.value,
  ma_sdm_impacts     = summary(sdm_ma_impacts, zstats = TRUE, short = TRUE),

  # Extension: Gini coefficients
  gini_total   = gini_total,
  gini_percap  = gini_percap,
  gini_gravity = gini_gravity,
  gini_by_cat  = gini_by_cat
)

saveRDS(results, file.path(output_dir, "results.rds"))
message("\nResults saved to: ", file.path(output_dir, "results.rds"))

message("\nAll figures saved to: ", output_dir)
message("Analysis complete.")
