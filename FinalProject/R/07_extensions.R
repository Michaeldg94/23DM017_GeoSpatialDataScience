# =============================================================================
# 06_extensions.R — Robustness checks, gravity model, market access,
#                   Gini/Lorenz, Figures 8-11
# =============================================================================

# Per-capita accessibility ----

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

# Non-linear income effects ----

sf_analysis <- sf_analysis |>
  mutate(log_income_sq = log_income^2)

ols_nonlin <- lm(
  log_access ~ log_income + log_income_sq + log_pop_density + log_dist_center,
  data = sf_analysis
)
summary(ols_nonlin)

# Category-specific income regressions ----

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

cat_elast_df <- tibble(
  category = names(cat_results),
  elasticity = sapply(cat_results, `[`, 1),
  se = sapply(cat_results, `[`, 2),
  p_value = sapply(cat_results, `[`, 4)
) |>
  arrange(desc(elasticity))

print(cat_elast_df)

# Figure 8: Category-specific income elasticities ----

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

# Alternative threshold (10-minute walk) ----

if (use_network) {
  # Network-based: count POIs reachable within 10 minutes
  access_10min <- rowSums(walk_time_mat <= 10, na.rm = TRUE)
  sf_analysis$access_alt <- access_10min[
    match(sf_analysis$codi_barri, sf_nbhoods$codi_barri)
  ]
} else {
  # Euclidean fallback: 800 m buffer
  walk_buffer_alt <- 800
  sf_buffers_alt <- st_sf(
    neighbourhood = sf_nbhoods$neighbourhood,
    geometry = st_buffer(centroid_sfc, dist = walk_buffer_alt)
  )
  for (cat in categories) {
    col <- paste0("n_", tolower(cat), "_alt")
    cat_pois <- sf_pois |> filter(category == cat)
    sf_nbhoods[[col]] <- lengths(st_intersects(sf_buffers_alt, cat_pois))
  }
  alt_cols <- paste0("n_", tolower(categories), "_alt")
  sf_nbhoods$access_alt <- rowSums(sf_nbhoods[, alt_cols] |> st_drop_geometry())
  sf_analysis$access_alt <- sf_nbhoods$access_alt[
    match(sf_analysis$codi_barri, sf_nbhoods$codi_barri)
  ]
}

sf_analysis <- sf_analysis |>
  mutate(log_access_alt = log(access_alt + 1))

ols_alt <- lm(
  log_access_alt ~ log_income + log_pop_density + log_dist_center,
  data = sf_analysis
)
summary(ols_alt)

sdm_alt <- lagsarlm(
  log_access_alt ~ log_income + log_pop_density + log_dist_center,
  data = sf_analysis, listw = w_queen,
  Durbin = TRUE, zero.policy = TRUE
)
summary(sdm_alt)

sdm_alt_impacts <- impacts(sdm_alt, listw = w_queen, R = 500)
print(summary(sdm_alt_impacts, zstats = TRUE, short = TRUE))

# Figure 9: Per-capita accessibility map ----

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

# Robustness summary ----

rob_specs <- c(
  "Baseline (15-min walk, total POIs)",
  "Per-capita (POIs/1000 pop)",
  "10-min walk threshold",
  "Non-linear (quadratic income)"
)
rob_coefs <- c(
  coef(ols_model)["log_income"],
  coef(ols_percap)["log_income"],
  coef(ols_alt)["log_income"],
  coef(ols_nonlin)["log_income"]
)
rob_pvals <- c(
  coef(summary(ols_model))["log_income", 4],
  coef(summary(ols_percap))["log_income", 4],
  coef(summary(ols_alt))["log_income", 4],
  coef(summary(ols_nonlin))["log_income", 4]
)

# Add Euclidean comparison if network distances were used
if (use_network && "access_score_eucl" %in% names(sf_analysis)) {
  sf_analysis <- sf_analysis |>
    mutate(log_access_eucl = log(access_score_eucl + 1))
  ols_eucl <- lm(
    log_access_eucl ~ log_income + log_pop_density + log_dist_center,
    data = sf_analysis
  )
  eucl_network_cor <- cor(sf_analysis$access_score, sf_analysis$access_score_eucl)
  message("Euclidean vs network correlation: ", round(eucl_network_cor, 3))

  rob_specs <- c(rob_specs, "Euclidean 1,200m buffer")
  rob_coefs <- c(rob_coefs, coef(ols_eucl)["log_income"])
  rob_pvals <- c(rob_pvals, coef(summary(ols_eucl))["log_income", 4])
}

rob_income <- data.frame(
  Specification = rob_specs,
  Income_coef = round(rob_coefs, 3),
  p_value = round(rob_pvals, 4)
)

print(rob_income)

# Gravity-weighted accessibility ----

analysis_centroids <- st_centroid(st_geometry(sf_analysis))

if (use_network) {
  # Walking-time-based gravity: exp(-beta_time * minutes)
  # beta_time = 0.083/min gives half-life ~ 8.4 min (equivalent to ~693 m)
  beta_decay <- 0.083  # per minute
  walk_sub <- walk_time_mat[
    match(sf_analysis$codi_barri, sf_nbhoods$codi_barri), ,
    drop = FALSE
  ]
  walk_sub[is.na(walk_sub)] <- Inf  # unreachable POIs get zero weight
  gravity_scores <- rowSums(exp(-beta_decay * walk_sub))
} else {
  # Euclidean distance-based gravity (fallback)
  beta_decay <- 0.001  # per metre; half-life ~ 693 m
  dist_to_pois <- st_distance(analysis_centroids, sf_pois)
  dist_num <- matrix(as.numeric(dist_to_pois), nrow = nrow(sf_analysis))
  gravity_scores <- rowSums(exp(-beta_decay * dist_num))
}

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

# Market access control (Harris potential) ----

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

# Accessibility inequality: Gini & Lorenz curve ----

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

lorenz_data <- sf_analysis |>
  st_drop_geometry() |>
  arrange(access_score) |>
  mutate(
    cum_pop = cumsum(population) / sum(population),
    cum_access = cumsum(access_score * population) /
      sum(access_score * population)
  )

lorenz_at_40pct <- approx(lorenz_data$cum_pop, lorenz_data$cum_access, xout = 0.4)$y

# Figure 10: Lorenz curve ----

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

# Figure 11: Gravity accessibility vs income ----

fig_11 <- ggplot(sf_analysis, aes(x = income_eur / 1000, y = gravity_access)) +
  geom_point(aes(size = population / 1000), alpha = 0.6, color = "#2c7bb6") +
  geom_smooth(method = "lm", se = TRUE, color = "firebrick", linewidth = 0.8) +
  scale_size_continuous(name = "Pop.\n(thousands)") +
  labs(
    title = "Gravity-Weighted Accessibility vs. Income",
    subtitle = paste0(
      "Exponential decay (beta = ", beta_decay,
      if (use_network) "/min" else "/m",
      "); R-sq = ", round(summary(ols_gravity)$r.squared, 2)
    ),
    x = "Disposable income per capita (thousand EUR, 2022)",
    y = "Gravity-weighted accessibility score"
  ) +
  theme_minimal() +
  theme(plot.title = element_text(size = 11, face = "bold"))

ggsave(file.path(output_dir, "11_gravity_access_vs_income.pdf"),
       fig_11, width = 7, height = 5)
