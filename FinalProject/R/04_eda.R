# =============================================================================
# 03_eda.R — Summary statistics and descriptive figures (1-4, 7)
# =============================================================================

# Summary statistics ----

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

poi_summary <- sf_pois |>
  st_drop_geometry() |>
  count(category, name = "n_pois")
print(poi_summary)

# Figure 1: POI locations ----

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

# Figure 2: Accessibility choropleth ----

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

# Figure 3: Income choropleth ----

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

# Figure 4: Scatter of accessibility vs income ----

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

# Figure 7: Side-by-side maps ----

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
