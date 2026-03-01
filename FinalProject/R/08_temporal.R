# =============================================================================
# 08_temporal.R — Income evolution across Barcelona neighbourhoods (2015–2022)
#
# Downloads yearly household income data from Barcelona Open Data, builds a
# panel dataset, computes inequality (Gini) over time, tests for convergence,
# and produces Figures 12–14.
# =============================================================================

# 8.1 Download income CSVs for 2015–2021 (2022 already present) ----

resource_ids <- c(
  "2015" = "9a69cefe-dcc5-400c-8647-4e438f7ae12b",
  "2016" = "bc48d45b-1046-4496-93c1-fbdac1fd47d0",
  "2017" = "dc0c1ad4-8b5e-4762-b999-2d4ffc95a718",
  "2018" = "9f5a6152-0075-4111-abec-7b5d62655dd3",
  "2019" = "0e205580-6d55-4599-bd13-086de83130b8",
  "2020" = "afe5b67d-7948-4e79-a88c-d51e55fe3ac6",
  "2021" = "e14509ca-9cba-43ec-b925-3beb5c69c2c7",
  "2022" = "3df0c5b9-de69-4c94-b924-57540e52932f"
)

base_url <- paste0(
  "https://opendata-ajuntament.barcelona.cat/data/dataset/",
  "78db0c75-fa56-4604-9510-8b92834a7fd2/resource/%s/download/",
  "%s_renda_disponible_llars_per_persona.csv"
)

socio_dir <- file.path(data_dir, "02_socioeconomic")

for (yr in names(resource_ids)) {
  dest <- file.path(socio_dir, paste0("renda_", yr, ".csv"))
  if (!file.exists(dest)) {
    message("Downloading income data for ", yr, "...")
    download.file(
      url = sprintf(base_url, resource_ids[yr], yr),
      destfile = dest,
      mode = "wb"
    )
  }
}

# 8.2 Build panel dataset ----

df_panel <- bind_rows(lapply(names(resource_ids), \(yr) {
  path <- file.path(socio_dir, paste0("renda_", yr, ".csv"))
  read_csv(path, show_col_types = FALSE) |>
    group_by(Codi_Barri, Nom_Barri) |>
    summarise(income_eur = mean(Import_Euros, na.rm = TRUE), .groups = "drop") |>
    mutate(year = as.integer(yr))
}))

# Compute RFD index per year (relative to that year's city average)
df_panel <- df_panel |>
  group_by(year) |>
  mutate(
    city_avg = mean(income_eur, na.rm = TRUE),
    rfd_index = (income_eur / city_avg) * 100
  ) |>
  ungroup()

# Attach district info from sf_nbhoods
district_lookup <- sf_nbhoods |>
  st_drop_geometry() |>
  select(codi_barri, nom_districte) |>
  mutate(codi_barri = as.integer(codi_barri))

df_panel <- df_panel |>
  left_join(district_lookup, by = c("Codi_Barri" = "codi_barri"))

# District-level averages per year
df_district <- df_panel |>
  group_by(nom_districte, year) |>
  summarise(income_eur = mean(income_eur, na.rm = TRUE), .groups = "drop")

# 8.3 Gini coefficient per year (sigma-convergence) ----

gini_by_year <- df_panel |>
  group_by(year) |>
  summarise(gini = gini(income_eur), .groups = "drop")

gini_income_2015 <- gini_by_year$gini[gini_by_year$year == 2015]
gini_income_2022 <- gini_by_year$gini[gini_by_year$year == 2022]
gini_income_change <- gini_income_2022 - gini_income_2015

# 8.4 Beta-convergence ----
# Regress annualised growth rate (2015→2022) on log initial income (2015)

df_convergence <- df_panel |>
  filter(year %in% c(2015, 2022)) |>
  select(Codi_Barri, Nom_Barri, year, income_eur) |>
  pivot_wider(names_from = year, values_from = income_eur, names_prefix = "y") |>
  mutate(
    growth_rate = (y2022 / y2015)^(1 / 7) - 1,   # annualised
    log_initial = log(y2015)
  )

beta_conv_model <- lm(growth_rate ~ log_initial, data = df_convergence)
beta_convergence_coef <- coef(beta_conv_model)["log_initial"]
beta_convergence_p <- coef(summary(beta_conv_model))["log_initial", 4]
beta_convergence_r2 <- summary(beta_conv_model)$r.squared

# Growth rate summary stats (percentage)
income_growth_rates <- df_convergence$growth_rate * 100
income_growth_mean <- mean(income_growth_rates)
income_growth_min <- min(income_growth_rates)
income_growth_max <- max(income_growth_rates)

# 8.5 Figure 12: Income trajectories by district ----

fig_12 <- ggplot() +
  geom_line(
    data = df_panel,
    aes(x = year, y = income_eur, group = Nom_Barri),
    color = "grey80", linewidth = 0.3, alpha = 0.6
  ) +
  geom_line(
    data = df_district,
    aes(x = year, y = income_eur, color = nom_districte),
    linewidth = 0.9
  ) +
  scale_color_viridis_d(name = "District", option = "turbo") +
  scale_x_continuous(breaks = 2015:2022) +
  scale_y_continuous(labels = scales::comma) +
  labs(
    title = "Household income per capita by district, 2015-2022",
    subtitle = "Grey lines = individual neighbourhoods; coloured lines = district averages",
    x = NULL, y = "Income per capita (EUR)"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 11, face = "bold"),
    plot.subtitle = element_text(size = 9, color = "grey40"),
    legend.position = "right",
    legend.text = element_text(size = 7),
    legend.key.height = unit(0.4, "cm")
  )

ggsave(
  file.path(output_dir, "12_income_trajectories.pdf"),
  fig_12, width = 8, height = 5
)

# 8.6 Figure 13: Gini over time ----

fig_13 <- ggplot(gini_by_year, aes(x = year, y = gini)) +
  geom_line(color = "#2c7bb6", linewidth = 1) +
  geom_point(color = "#2c7bb6", size = 2.5) +
  scale_x_continuous(breaks = 2015:2022) +
  scale_y_continuous(labels = scales::number_format(accuracy = 0.001)) +
  labs(
    title = "Income inequality across neighbourhoods, 2015-2022",
    subtitle = "Gini coefficient of household income per capita (73 barris)",
    x = NULL, y = "Gini coefficient"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 11, face = "bold"),
    plot.subtitle = element_text(size = 9, color = "grey40")
  )

ggsave(
  file.path(output_dir, "13_income_gini_over_time.pdf"),
  fig_13, width = 6, height = 4
)

# 8.7 Figure 14: Small-multiples choropleth (2015, 2018, 2022) ----

panel_years <- c(2015, 2018, 2022)

sf_panel_map <- df_panel |>
  filter(year %in% panel_years) |>
  left_join(
    sf_nbhoods |> select(codi_barri) |> mutate(codi_barri = as.integer(codi_barri)),
    by = c("Codi_Barri" = "codi_barri")
  ) |>
  st_as_sf()

# Shared colour scale across all three panels
income_range <- range(sf_panel_map$income_eur, na.rm = TRUE)

panel_plots <- lapply(panel_years, \(yr) {
  ggplot() +
    geom_sf(
      data = sf_panel_map |> filter(year == yr),
      aes(fill = income_eur),
      color = "white", linewidth = 0.15
    ) +
    scale_fill_viridis_c(
      name = "Income\n(EUR/capita)",
      option = "mako", direction = -1,
      limits = income_range,
      labels = scales::comma
    ) +
    labs(title = as.character(yr)) +
    theme_map() +
    theme(
      plot.title = element_text(size = 12, face = "bold", hjust = 0.5),
      legend.position = if (yr == max(panel_years)) "right" else "none"
    )
})

fig_14 <- panel_plots[[1]] + panel_plots[[2]] + panel_plots[[3]] +
  plot_annotation(
    title = "Household income per capita across Barcelona, 2015-2022",
    subtitle = "Darker shading = higher income. The spatial pattern is persistent.",
    theme = theme(
      plot.title = element_text(size = 11, face = "bold"),
      plot.subtitle = element_text(size = 9, color = "grey40")
    )
  ) +
  plot_layout(ncol = 3)

ggsave(
  file.path(output_dir, "14_income_choropleth_panel.pdf"),
  fig_14, width = 12, height = 5
)
