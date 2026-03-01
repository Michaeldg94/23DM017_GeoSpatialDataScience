# =============================================================================
# 04_spatial.R — Spatial weights, Moran's I, LISA clusters, Figures 5-6
# =============================================================================

# Spatial weights matrix (queen contiguity) ----

nb_queen <- poly2nb(sf_analysis, queen = TRUE)
w_queen <- nb2listw(nb_queen, style = "W", zero.policy = TRUE)

# Global Moran's I ----

moran_access <- moran.test(sf_analysis$access_score, w_queen, zero.policy = TRUE)
print(moran_access)

# Local Moran's I (LISA) ----

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

lisa_colors <- c(
  "High-High" = "#d7191c",
  "Low-Low" = "#2c7bb6",
  "High-Low" = "#fdae61",
  "Low-High" = "#abd9e9",
  "Not significant" = "grey90"
)

# Figure 5: LISA cluster map ----

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

# Figure 6: Moran scatter plot ----

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
