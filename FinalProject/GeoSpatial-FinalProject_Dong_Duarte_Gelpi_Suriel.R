# =============================================================================
# DEPRECATED — This monolithic script is superseded by the modular pipeline.
# Use run_all.R instead, which sources the scripts in R/ sequentially.
# =============================================================================
# Course: Geospatial Data Sciences and Economic Spatial Models (BSE)
# Final Project - March 2026
# =============================================================================

# 0. Setup ----

if (!require("pacman")) install.packages("pacman")

pacman::p_load(
  sf, dplyr, tidyr, readr, stringr, ggplot2,
  osmdata,
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

# 1. Data Acquisition ----

# 1.1 Barcelona neighbourhood boundaries ----

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

sf_nbhoods <- read_csv(barris_file, show_col_types = FALSE) |>
  st_as_sf(wkt = "geometria_wgs84", crs = 4326) |>
  st_transform(crs_proj) |>
  select(codi_districte, nom_districte, codi_barri, nom_barri) |>
  rename(neighbourhood = nom_barri)

# Standardise geometry column name
st_geometry(sf_nbhoods) <- "geometry"

# 1.2 Household income data ----

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

bcn_avg_income <- mean(df_income$income_eur, na.rm = TRUE)

df_income <- df_income |>
  mutate(rfd_index = (income_eur / bcn_avg_income) * 100)

# 1.3 Population data ----

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

# 1.4 Download POIs from OpenStreetMap ----

bbox_bcn <- c(2.0528, 41.3200, 2.2282, 41.4680)

get_osm_pois <- function(key, value, bbox = bbox_bcn, max_retries = 5) {
  result <- NULL

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
          message("  Retry ", attempt, "/", max_retries, " in ", wait, "s...")
          Sys.sleep(wait)
        }
        NULL
      }
    )
    if (!is.null(result)) break
  }

  if (is.null(result)) {
    warning("Failed: ", key, "=", value, " after ", max_retries, " attempts.")
    return(st_sf(geometry = st_sfc(crs = crs_proj)))
  }

  pts <- result$osm_points
  polys <- result$osm_polygons

  if (!is.null(polys) && nrow(polys) > 0) {
    poly_centroids <- st_centroid(polys) |> select(geometry)
    pts <- if (!is.null(pts) && nrow(pts) > 0) {
      bind_rows(pts |> select(geometry), poly_centroids)
    } else {
      poly_centroids
    }
  } else if (!is.null(pts) && nrow(pts) > 0) {
    pts <- pts |> select(geometry)
  } else {
    pts <- st_sf(geometry = st_sfc(crs = 4326))
  }

  Sys.sleep(3)
  pts |> st_transform(crs_proj)
}

poi_file <- file.path(data_dir, "pois_all.rds")

if (!file.exists(poi_file)) {
  message("Downloading POIs from OpenStreetMap...")

  sf_grocery <- bind_rows(
    get_osm_pois("shop", "supermarket"),
    get_osm_pois("shop", "grocery"),
    get_osm_pois("shop", "convenience")
  ) |> mutate(category = "Grocery")

  sf_pharmacy <- get_osm_pois("amenity", "pharmacy") |>
    mutate(category = "Pharmacy")

  sf_school <- get_osm_pois("amenity", "school") |>
    mutate(category = "School")

  sf_health <- bind_rows(
    get_osm_pois("amenity", "clinic"),
    get_osm_pois("amenity", "hospital"),
    get_osm_pois("amenity", "doctors"),
    get_osm_pois("healthcare", "centre")
  ) |> mutate(category = "Healthcare")

  sf_park <- get_osm_pois("leisure", "park") |>
    mutate(category = "Park")

  sf_transit <- bind_rows(
    get_osm_pois("railway", "station"),
    get_osm_pois("railway", "halt"),
    get_osm_pois("highway", "bus_stop"),
    get_osm_pois("public_transport", "stop_position"),
    get_osm_pois("amenity", "bus_station")
  ) |> mutate(category = "Transit")

  sf_pois <- bind_rows(
    sf_grocery, sf_pharmacy, sf_school,
    sf_health, sf_park, sf_transit
  )

  # Clip to Barcelona boundary
  sf_bcn_boundary <- sf_nbhoods |> st_union()
  sf_pois <- sf_pois[st_intersects(sf_pois, sf_bcn_boundary, sparse = FALSE)[, 1], ]

  saveRDS(sf_pois, poi_file)
} else {
  sf_pois <- readRDS(poi_file)
}

message("POIs loaded: ", nrow(sf_pois))

# 2. Data Wrangling ----

# 2.1 Area and centroids
sf_nbhoods$area_km2 <- as.numeric(st_area(sf_nbhoods)) / 1e6
centroid_sfc <- st_centroid(st_geometry(sf_nbhoods))

# 2.2 Distance to city centre
sf_nbhoods$dist_center_km <- as.numeric(
  st_distance(centroid_sfc, pt_center, by_element = FALSE)[, 1]
) / 1000

# 2.3 Accessibility score ----
# Count POIs of each category within a 1,200 m buffer around each centroid.

categories <- c("Grocery", "Pharmacy", "School", "Healthcare", "Park", "Transit")

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

# 2.4 Join socioeconomic data ----

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

# 3. Descriptive Analysis & Maps ----

# 3.1 Summary statistics
df_summary <- sf_analysis |>
  st_drop_geometry() |>
  summarise(
    across(
      c(access_score, rfd_index, income_eur, population, pop_density,
        dist_center_km),
      list(
        mean = \(x) mean(x, na.rm = TRUE),
        sd = \(x) sd(x, na.rm = TRUE),
        min = \(x) min(x, na.rm = TRUE),
        max = \(x) max(x, na.rm = TRUE)
      ),
      .names = "{.col}__{.fn}"
    )
  ) |>
  pivot_longer(everything(), names_to = c("variable", "stat"), names_sep = "__") |>
  pivot_wider(names_from = stat, values_from = value) |>
  mutate(across(where(is.numeric), \(x) round(x, 2)))

print(df_summary)

# POI counts by category
poi_summary <- sf_pois |>
  st_drop_geometry() |>
  count(category, name = "n_pois")
print(poi_summary)

# 3.2 Figure 1: POI locations ----

fig_01 <- ggplot() +
  geom_sf(data = sf_analysis, fill = "grey95", color = "grey70", linewidth = 0.15) +
  geom_sf(data = sf_pois, aes(color = category), size = 0.3, alpha = 0.5) +
  scale_color_viridis_d(name = "Service\ncategory", option = "turbo") +
  labs(
    title = "Essential Services in Barcelona",
    subtitle = "Points of interest from OpenStreetMap"
  ) +
  theme_map()

ggsave(file.path(output_dir, "01_poi_locations.pdf"), fig_01, width = 8, height = 7)

# 3.3 Figure 2: Accessibility choropleth ----

fig_02 <- ggplot() +
  geom_sf(data = sf_analysis, aes(fill = access_score),
          color = "white", linewidth = 0.2) +
  scale_fill_viridis_c(name = "Total\nPOIs", option = "mako", direction = -1) +
  labs(
    title = "15-Minute City Accessibility Score",
    subtitle = "Total essential service POIs within a 15-minute walk (1,200 m buffer)"
  ) +
  theme_map()

ggsave(file.path(output_dir, "02_accessibility_score_map.pdf"),
       fig_02, width = 8, height = 7)

# 3.4 Figure 3: Income choropleth ----

fig_03 <- ggplot() +
  geom_sf(data = sf_analysis, aes(fill = income_eur / 1000),
          color = "white", linewidth = 0.2) +
  scale_fill_viridis_c(
    name = "Income\n(thousand\nEUR/person)", option = "magma", direction = -1
  ) +
  labs(
    title = "Disposable Household Income per Capita by Neighbourhood",
    subtitle = "Renda disponible de les llars, 2022 (Ajuntament de Barcelona)"
  ) +
  theme_map()

ggsave(file.path(output_dir, "03_income_map.pdf"), fig_03, width = 8, height = 7)

# 3.5 Figure 4: Scatter of accessibility vs income ----

fig_04 <- ggplot(sf_analysis, aes(x = income_eur / 1000, y = access_score)) +
  geom_point(aes(size = population / 1000), alpha = 0.6, color = "#2c7bb6") +
  geom_smooth(method = "lm", se = TRUE, color = "firebrick", linewidth = 0.8) +
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

# 4. Spatial Weights Matrix ----

nb_queen <- poly2nb(sf_analysis, queen = TRUE)
w_queen <- nb2listw(nb_queen, style = "W", zero.policy = TRUE)

# 5. Spatial Autocorrelation ----

# 5.1 Global Moran's I ----

moran_access <- moran.test(sf_analysis$access_score, w_queen, zero.policy = TRUE)
print(moran_access)

# 5.2 Local Moran's I (LISA) ----

lisa <- localmoran(sf_analysis$access_score, w_queen, zero.policy = TRUE)

sf_analysis <- sf_analysis |>
  mutate(
    lisa_i = lisa[, 1],
    lisa_p = lisa[, 5],
    score_std = as.numeric(scale(access_score)),
    lag_std = lag.listw(w_queen, score_std, zero.policy = TRUE),
    lisa_cluster = case_when(
      lisa_p > 0.05 ~ "Not significant",
      score_std > 0 & lag_std > 0 ~ "High-High",
      score_std < 0 & lag_std < 0 ~ "Low-Low",
      score_std > 0 & lag_std < 0 ~ "High-Low",
      score_std < 0 & lag_std > 0 ~ "Low-High",
      TRUE ~ "Not significant"
    ),
    lisa_cluster = factor(
      lisa_cluster,
      levels = c("High-High", "Low-Low", "High-Low", "Low-High", "Not significant")
    )
  )

# 5.3 Figure 5: LISA cluster map ----

lisa_colors <- c(
  "High-High" = "#d7191c",
  "Low-Low" = "#2c7bb6",
  "High-Low" = "#fdae61",
  "Low-High" = "#abd9e9",
  "Not significant" = "grey90"
)

fig_05 <- ggplot() +
  geom_sf(data = sf_analysis, aes(fill = lisa_cluster),
          color = "white", linewidth = 0.2) +
  scale_fill_manual(values = lisa_colors, name = "LISA cluster", drop = FALSE) +
  labs(
    title = "Local Spatial Autocorrelation of Accessibility",
    subtitle = paste0(
      "Global Moran's I = ", round(moran_access$estimate[1], 3),
      ", p = ", format.pval(moran_access$p.value, digits = 3)
    )
  ) +
  theme_map()

ggsave(file.path(output_dir, "05_lisa_clusters_map.pdf"),
       fig_05, width = 8, height = 7)

# 5.4 Figure 6: Moran scatter plot ----

fig_06 <- ggplot(sf_analysis, aes(x = score_std, y = lag_std)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey60") +
  geom_vline(xintercept = 0, linetype = "dashed", color = "grey60") +
  geom_point(aes(color = lisa_cluster), size = 2, alpha = 0.7) +
  geom_smooth(method = "lm", se = FALSE, color = "black", linewidth = 0.7) +
  scale_color_manual(values = lisa_colors, name = "LISA cluster", drop = FALSE) +
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

# 6. OLS Baseline Regression ----

reg_formula <- log_access ~ log_income + log_pop_density + log_dist_center

ols_model <- lm(reg_formula, data = sf_analysis)
summary(ols_model)

# Moran's I on OLS residuals
moran_resid <- lm.morantest(ols_model, w_queen, zero.policy = TRUE)
print(moran_resid)

# Lagrange Multiplier tests
lm_tests <- lm.RStests(
  ols_model, w_queen,
  test = c("RSlag", "RSerr", "adjRSlag", "adjRSerr"),
  zero.policy = TRUE
)
summary(lm_tests)

# 7. Spatial Models: SAR, SEM, SDM, SDEM ----

# 7.1 Spatial Lag Model (SAR) ----
sar_model <- lagsarlm(
  reg_formula, data = sf_analysis, listw = w_queen, zero.policy = TRUE
)
summary(sar_model)

# 7.2 Spatial Error Model (SEM) ----
sem_model <- errorsarlm(
  reg_formula, data = sf_analysis, listw = w_queen, zero.policy = TRUE
)
summary(sem_model)

# 7.3 Spatial Durbin Model (SDM) ----
# Includes both W*Y and W*X; nests SAR and SEM as special cases.
sdm_model <- lagsarlm(
  reg_formula, data = sf_analysis, listw = w_queen,
  Durbin = TRUE, zero.policy = TRUE
)
summary(sdm_model)

# 7.4 Spatial Durbin Error Model (SDEM) ----
# W*X with spatial error process (local spillovers only).
sdem_model <- errorsarlm(
  reg_formula, data = sf_analysis, listw = w_queen,
  Durbin = TRUE, zero.policy = TRUE
)
summary(sdem_model)

# 8. Model Comparison & Selection ----

# 8.1 AIC / Log-likelihood comparison ----

aic_table <- data.frame(
  Model = c("OLS", "SAR", "SEM", "SDM", "SDEM"),
  AIC = c(AIC(ols_model), AIC(sar_model), AIC(sem_model),
          AIC(sdm_model), AIC(sdem_model)),
  logLik = c(logLik(ols_model), logLik(sar_model), logLik(sem_model),
             logLik(sdm_model), logLik(sdem_model))
) |>
  arrange(AIC)

print(aic_table)

# 8.2 Likelihood ratio tests (nested models) ----

lr_sdm_sar <- as.numeric(2 * (logLik(sdm_model) - logLik(sar_model)))
lr_sdm_sar_df <- length(coef(sdm_model)) - length(coef(sar_model))
lr_sdm_sar_p <- pchisq(lr_sdm_sar, df = lr_sdm_sar_df, lower.tail = FALSE)

lr_sdem_sem <- as.numeric(2 * (logLik(sdem_model) - logLik(sem_model)))
lr_sdem_sem_df <- length(coef(sdem_model)) - length(coef(sem_model))
lr_sdem_sem_p <- pchisq(lr_sdem_sem, df = lr_sdem_sem_df, lower.tail = FALSE)

message("LR test SDM vs SAR: ", round(lr_sdm_sar, 3),
        " (p = ", round(lr_sdm_sar_p, 4), ")")
message("LR test SDEM vs SEM: ", round(lr_sdem_sem, 3),
        " (p = ", round(lr_sdem_sem_p, 4), ")")

# 8.3 SDM impact decomposition ----

sdm_impacts <- impacts(sdm_model, listw = w_queen, R = 500)
sdm_impacts_smry <- summary(sdm_impacts, zstats = TRUE, short = TRUE)
print(sdm_impacts_smry)

sar_impacts <- impacts(sar_model, listw = w_queen, R = 500)
print(summary(sar_impacts, zstats = TRUE, short = TRUE))

# 8.4 Figure 7: Side-by-side maps ----

p_access <- ggplot() +
  geom_sf(data = sf_analysis, aes(fill = access_score),
          color = "white", linewidth = 0.15) +
  scale_fill_viridis_c(name = "Total\nPOIs", option = "mako", direction = -1) +
  labs(title = "Accessibility") +
  theme_map(legend.key.height = unit(0.8, "cm"))

p_income <- ggplot() +
  geom_sf(data = sf_analysis, aes(fill = income_eur / 1000),
          color = "white", linewidth = 0.15) +
  scale_fill_viridis_c(name = "Income\n(k EUR)", option = "magma", direction = -1) +
  labs(title = "Household Income") +
  theme_map(legend.key.height = unit(0.8, "cm"))

fig_07 <- p_access + p_income +
  plot_annotation(
    title = "Accessibility and Income Across Barcelona Neighbourhoods",
    theme = theme(plot.title = element_text(size = 12, face = "bold"))
  )

ggsave(file.path(output_dir, "07_access_income_sidebyside.pdf"),
       fig_07, width = 14, height = 6)

# 9. Robustness & Extensions ----

# 9.1 Per-capita accessibility ----

sf_analysis <- sf_analysis |>
  mutate(
    access_per_capita = access_score / (population / 1000),
    log_access_pc = log(access_per_capita + 1)
  )

ols_percap <- lm(
  log_access_pc ~ log_income + log_pop_density + log_dist_center,
  data = sf_analysis
)
summary(ols_percap)

sdm_percap <- lagsarlm(
  log_access_pc ~ log_income + log_pop_density + log_dist_center,
  data = sf_analysis, listw = w_queen,
  Durbin = TRUE, zero.policy = TRUE
)
summary(sdm_percap)

sdm_percap_impacts <- impacts(sdm_percap, listw = w_queen, R = 500)
print(summary(sdm_percap_impacts, zstats = TRUE, short = TRUE))

# 9.2 Non-linear income effects ----

sf_analysis <- sf_analysis |>
  mutate(log_income_sq = log_income^2)

ols_nonlin <- lm(
  log_access ~ log_income + log_income_sq + log_pop_density + log_dist_center,
  data = sf_analysis
)
summary(ols_nonlin)

# 9.3 Category-specific income regressions ----

cat_results <- list()

for (cat in categories) {
  col <- paste0("n_", tolower(cat))
  sf_analysis[[paste0("log_", tolower(cat))]] <- log(sf_analysis[[col]] + 1)

  cat_mod <- lm(
    as.formula(paste0(
      "log_", tolower(cat),
      " ~ log_income + log_pop_density + log_dist_center"
    )),
    data = sf_analysis
  )
  cat_results[[cat]] <- coef(summary(cat_mod))["log_income", ]
}

# Print category elasticities
cat_elast_df <- tibble(
  category = names(cat_results),
  elasticity = sapply(cat_results, `[`, 1),
  se = sapply(cat_results, `[`, 2),
  p_value = sapply(cat_results, `[`, 4)
) |>
  arrange(desc(elasticity))

print(cat_elast_df)

# 9.4 Figure 8: Category-specific income elasticities ----

df_cat_elast <- cat_elast_df |>
  mutate(
    significant = p_value < 0.05,
    category = factor(category, levels = category[order(elasticity)])
  )

fig_08 <- ggplot(df_cat_elast, aes(x = category, y = elasticity)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey60") +
  geom_pointrange(
    aes(
      ymin = elasticity - 1.96 * se,
      ymax = elasticity + 1.96 * se,
      color = significant
    ),
    linewidth = 0.8, size = 0.8
  ) +
  scale_color_manual(
    values = c("TRUE" = "#d7191c", "FALSE" = "grey50"),
    labels = c("TRUE" = "p < 0.05", "FALSE" = "p >= 0.05"),
    name = ""
  ) +
  coord_flip() +
  labs(
    title = "Income Elasticity of Accessibility by Service Category",
    subtitle = "OLS coefficient on log(income), with 95% confidence intervals",
    x = NULL,
    y = "Income elasticity"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 11, face = "bold"),
    legend.position = "bottom"
  )

ggsave(file.path(output_dir, "08_category_income_elasticities.pdf"),
       fig_08, width = 7, height = 5)

# 9.5 Alternative buffer distance (800 m ~ 10-minute walk) ----

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

sf_analysis$access_800m <- sf_nbhoods$access_800m[
  match(sf_analysis$codi_barri, sf_nbhoods$codi_barri)
]
sf_analysis <- sf_analysis |>
  mutate(log_access_800m = log(access_800m + 1))

ols_800m <- lm(
  log_access_800m ~ log_income + log_pop_density + log_dist_center,
  data = sf_analysis
)
summary(ols_800m)

sdm_800m <- lagsarlm(
  log_access_800m ~ log_income + log_pop_density + log_dist_center,
  data = sf_analysis, listw = w_queen,
  Durbin = TRUE, zero.policy = TRUE
)
summary(sdm_800m)

sdm_800m_impacts <- impacts(sdm_800m, listw = w_queen, R = 500)
print(summary(sdm_800m_impacts, zstats = TRUE, short = TRUE))

# 9.6 Figure 9: Per-capita accessibility map ----

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

# 9.7 Robustness summary ----

rob_income <- data.frame(
  Specification = c(
    "Baseline (1200m, total POIs)",
    "Per-capita (POIs/1000 pop)",
    "800m buffer (10-min walk)",
    "Non-linear (quadratic income)"
  ),
  Income_coef = round(c(
    coef(ols_model)["log_income"],
    coef(ols_percap)["log_income"],
    coef(ols_800m)["log_income"],
    coef(ols_nonlin)["log_income"]
  ), 3),
  p_value = round(c(
    coef(summary(ols_model))["log_income", 4],
    coef(summary(ols_percap))["log_income", 4],
    coef(summary(ols_800m))["log_income", 4],
    coef(summary(ols_nonlin))["log_income", 4]
  ), 4)
)

print(rob_income)

# 9.8 Gravity-weighted accessibility ----
# GravAccess_n = sum_j exp(-beta * d_{nj})
# Penalises distant POIs instead of using a sharp buffer cutoff.

analysis_centroids <- st_centroid(st_geometry(sf_analysis))

dist_to_pois <- st_distance(analysis_centroids, sf_pois)
dist_num <- matrix(as.numeric(dist_to_pois), nrow = nrow(sf_analysis))

beta_decay <- 0.001  # half-life ~ 693 m
gravity_scores <- rowSums(exp(-beta_decay * dist_num))

sf_analysis$gravity_access <- gravity_scores
sf_analysis$log_gravity_access <- log(gravity_scores)

ols_gravity <- lm(
  log_gravity_access ~ log_income + log_pop_density + log_dist_center,
  data = sf_analysis
)
summary(ols_gravity)

sdm_gravity <- lagsarlm(
  log_gravity_access ~ log_income + log_pop_density + log_dist_center,
  data = sf_analysis, listw = w_queen,
  Durbin = TRUE, zero.policy = TRUE
)
summary(sdm_gravity)

sdm_gravity_impacts <- impacts(sdm_gravity, listw = w_queen, R = 500)
sdm_gravity_impacts_smry <- summary(sdm_gravity_impacts, zstats = TRUE, short = TRUE)
print(sdm_gravity_impacts_smry)

# 9.9 Market access control (Harris potential) ----
# MA_n = sum_{i != n} Pop_i / d_{ni}

dist_nn <- st_distance(analysis_centroids)
dist_nn_num <- matrix(as.numeric(dist_nn), nrow = nrow(sf_analysis))
diag(dist_nn_num) <- Inf

pop_vec <- sf_analysis$population
market_access <- vapply(
  seq_len(nrow(sf_analysis)),
  \(i) sum(pop_vec / dist_nn_num[i, ]),
  numeric(1)
)

sf_analysis$market_access <- market_access
sf_analysis$log_market_access <- log(market_access)

ols_ma <- lm(
  log_access ~ log_income + log_pop_density + log_market_access,
  data = sf_analysis
)
summary(ols_ma)

sdm_ma <- lagsarlm(
  log_access ~ log_income + log_pop_density + log_market_access,
  data = sf_analysis, listw = w_queen,
  Durbin = TRUE, zero.policy = TRUE
)
summary(sdm_ma)

sdm_ma_impacts <- impacts(sdm_ma, listw = w_queen, R = 500)
print(summary(sdm_ma_impacts, zstats = TRUE, short = TRUE))

# 9.10 Accessibility inequality: Gini & Lorenz curve ----

gini <- function(x) {
  x <- sort(x[x > 0])
  n <- length(x)
  2 * sum(seq_len(n) * x) / (n * sum(x)) - (n + 1) / n
}

gini_total <- gini(sf_analysis$access_score)
gini_percap <- gini(sf_analysis$access_per_capita)
gini_gravity <- gini(sf_analysis$gravity_access)

gini_by_cat <- sapply(categories, function(cat) {
  gini(sf_analysis[[paste0("n_", tolower(cat))]])
})

message("Gini (total): ", round(gini_total, 3),
        " | per-capita: ", round(gini_percap, 3),
        " | gravity: ", round(gini_gravity, 3))
print(gini_by_cat)

# Lorenz curve data (population-weighted)
lorenz_data <- sf_analysis |>
  st_drop_geometry() |>
  arrange(access_score) |>
  mutate(
    cum_pop = cumsum(population) / sum(population),
    cum_access = cumsum(access_score * population) /
      sum(access_score * population)
  )

# Interpolate Lorenz curve at 40% cumulative population
lorenz_at_40pct <- approx(lorenz_data$cum_pop, lorenz_data$cum_access, xout = 0.4)$y

# 9.11 Figure 10: Lorenz curve ----

fig_10 <- ggplot(lorenz_data, aes(x = cum_pop, y = cum_access)) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "grey50") +
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

ggsave(file.path(output_dir, "10_lorenz_curve.pdf"), fig_10, width = 6, height = 6)

# 9.12 Figure 11: Gravity accessibility vs income ----

fig_11 <- ggplot(sf_analysis, aes(x = income_eur / 1000, y = gravity_access)) +
  geom_point(aes(size = population / 1000), alpha = 0.6, color = "#2c7bb6") +
  geom_smooth(method = "lm", se = TRUE, color = "firebrick", linewidth = 0.8) +
  scale_size_continuous(name = "Pop.\n(thousands)") +
  labs(
    title = "Gravity-Weighted Accessibility vs. Income",
    subtitle = paste0(
      "Exponential decay (beta = ", beta_decay,
      "); R-sq = ", round(summary(ols_gravity)$r.squared, 2)
    ),
    x = "Disposable income per capita (thousand EUR, 2022)",
    y = "Gravity-weighted accessibility score"
  ) +
  theme_minimal() +
  theme(plot.title = element_text(size = 11, face = "bold"))

ggsave(file.path(output_dir, "11_gravity_access_vs_income.pdf"),
       fig_11, width = 7, height = 5)

# 10. Save results for Rmd ----

results <- list(
  # Data dimensions
  n_barris = nrow(sf_analysis),
  n_pois_total = nrow(sf_pois),
  poi_summary = poi_summary,

  # Descriptive stats
  access_min = min(sf_analysis$access_score),
  access_max = max(sf_analysis$access_score),
  access_mean = mean(sf_analysis$access_score),
  income_min = min(sf_analysis$income_eur),
  income_max = max(sf_analysis$income_eur),
  rfd_min = min(sf_analysis$rfd_index),
  rfd_max = max(sf_analysis$rfd_index),
  popdens_min = min(sf_analysis$pop_density),
  popdens_max = max(sf_analysis$pop_density),
  avg_neighbors = mean(card(nb_queen)),

  # Moran's I
  moran_I = moran_access$estimate[1],
  moran_p = moran_access$p.value,
  moran_resid_I = moran_resid$statistic,
  moran_resid_p = moran_resid$p.value,

  # OLS
  ols_summary = summary(ols_model),
  ols_coefs = coef(summary(ols_model)),
  ols_r2 = summary(ols_model)$r.squared,
  ols_adjr2 = summary(ols_model)$adj.r.squared,
  ols_aic = AIC(ols_model),
  ols_loglik = as.numeric(logLik(ols_model)),

  # SAR
  sar_rho = sar_model$rho,
  sar_rho_se = sar_model$rho.se,
  sar_aic = AIC(sar_model),
  sar_loglik = as.numeric(logLik(sar_model)),

  # SEM
  sem_aic = AIC(sem_model),
  sem_loglik = as.numeric(logLik(sem_model)),

  # SDM
  sdm_summary = summary(sdm_model),
  sdm_coefs = summary(sdm_model)$Coef,
  sdm_rho = sdm_model$rho,
  sdm_rho_se = sdm_model$rho.se,
  sdm_rho_p = summary(sdm_model)$Wald1$p.value,
  sdm_aic = AIC(sdm_model),
  sdm_loglik = as.numeric(logLik(sdm_model)),
  sdm_impacts_summary = sdm_impacts_smry,
  sdm_direct = sdm_impacts_smry$res$direct,
  sdm_indirect = sdm_impacts_smry$res$indirect,
  sdm_total = sdm_impacts_smry$res$total,
  sdm_pzmat = sdm_impacts_smry$pzmat,

  # SDEM
  sdem_lambda = sdem_model$lambda,
  sdem_lambda_p = summary(sdem_model)$Wald1$p.value,
  sdem_aic = AIC(sdem_model),
  sdem_loglik = as.numeric(logLik(sdem_model)),

  # LR tests
  lr_sdm_sar = lr_sdm_sar,
  lr_sdm_sar_p = lr_sdm_sar_p,
  lr_sdem_sem = lr_sdem_sem,
  lr_sdem_sem_p = lr_sdem_sem_p,

  # Robustness: per-capita
  percap_ols_income_coef = coef(summary(ols_percap))["log_income", 1],
  percap_ols_income_p = coef(summary(ols_percap))["log_income", 4],
  percap_ols_r2 = summary(ols_percap)$r.squared,

  # Robustness: non-linear
  nonlin_quad_coef = coef(summary(ols_nonlin))["log_income_sq", 1],
  nonlin_quad_p = coef(summary(ols_nonlin))["log_income_sq", 4],

  # Robustness: category-specific
  cat_results = cat_results,

  # Robustness: 800m
  ols_800m_income_coef = coef(summary(ols_800m))["log_income", 1],
  ols_800m_income_p = coef(summary(ols_800m))["log_income", 4],
  sdm_800m_rho = sdm_800m$rho,
  sdm_800m_rho_p = summary(sdm_800m)$Wald1$p.value,
  sdm_800m_coefs = summary(sdm_800m)$Coef,

  # Extension: gravity-weighted accessibility
  gravity_ols_income_coef = coef(summary(ols_gravity))["log_income", 1],
  gravity_ols_income_p = coef(summary(ols_gravity))["log_income", 4],
  gravity_ols_r2 = summary(ols_gravity)$r.squared,
  gravity_sdm_rho = sdm_gravity$rho,
  gravity_sdm_rho_p = summary(sdm_gravity)$Wald1$p.value,
  gravity_sdm_impacts = sdm_gravity_impacts_smry,
  gravity_sdm_direct = sdm_gravity_impacts_smry$res$direct,
  gravity_sdm_indirect = sdm_gravity_impacts_smry$res$indirect,
  gravity_sdm_total = sdm_gravity_impacts_smry$res$total,
  gravity_sdm_pzmat = sdm_gravity_impacts_smry$pzmat,
  beta_decay = beta_decay,

  # Extension: market access
  ma_ols_income_coef = coef(summary(ols_ma))["log_income", 1],
  ma_ols_income_p = coef(summary(ols_ma))["log_income", 4],
  ma_ols_r2 = summary(ols_ma)$r.squared,
  ma_ols_ma_coef = coef(summary(ols_ma))["log_market_access", 1],
  ma_ols_ma_p = coef(summary(ols_ma))["log_market_access", 4],
  ma_sdm_rho = sdm_ma$rho,
  ma_sdm_rho_p = summary(sdm_ma)$Wald1$p.value,
  ma_sdm_impacts = summary(sdm_ma_impacts, zstats = TRUE, short = TRUE),

  # Extension: Gini coefficients
  gini_total = gini_total,
  gini_percap = gini_percap,
  gini_gravity = gini_gravity,
  gini_by_cat = gini_by_cat,

  # Additional stats for inline R code in Rmd
  area_min_km2 = min(sf_analysis$area_km2),
  area_max_km2 = max(sf_analysis$area_km2),
  pop_min = min(sf_analysis$population),
  pop_max = max(sf_analysis$population),
  lorenz_at_40pct = lorenz_at_40pct,
  n_sdm_params = length(coef(sdm_model)) + 1  # +1 for rho
)

saveRDS(results, file.path(output_dir, "results.rds"))
message("Results saved. All figures in: ", output_dir)
