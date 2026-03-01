# =============================================================================
# 01_data.R — Load neighbourhood boundaries, income, population, and POIs
#
# All source files live under data/:
#   01_boundaries/bcn_barris.csv        — Neighbourhood polygons
#   02_socioeconomic/renda_2022.csv     — Household income per capita, 2022
#   02_socioeconomic/poblacio_2025.csv  — Population by neighbourhood, 2025
#   03_pois/poi_all_combined.gpkg       — Pre-processed POIs (EPSG:25831)
# =============================================================================

# 1.1 Barcelona neighbourhood boundaries ----

barris_file <- file.path(data_dir, "01_boundaries", "bcn_barris.csv")

if (!file.exists(barris_file)) {
  dir.create(dirname(barris_file), recursive = TRUE, showWarnings = FALSE)
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

st_geometry(sf_nbhoods) <- "geometry"

# 1.2 Household income data ----

income_file <- file.path(data_dir, "02_socioeconomic", "renda_2022.csv")

if (!file.exists(income_file)) {
  dir.create(dirname(income_file), recursive = TRUE, showWarnings = FALSE)
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

pop_file <- file.path(data_dir, "02_socioeconomic", "poblacio_2025.csv")

if (!file.exists(pop_file)) {
  dir.create(dirname(pop_file), recursive = TRUE, showWarnings = FALSE)
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

# 1.4 Points of Interest ----
# Pre-processed GeoPackage, already clipped to Barcelona and projected to
# EPSG:25831. Categories are remapped to the display names used in the report.

poi_file <- file.path(data_dir, "03_pois", "poi_all_combined.gpkg")
stopifnot("POI file not found — expected data/03_pois/poi_all_combined.gpkg" = file.exists(poi_file))

sf_pois <- st_read(poi_file, quiet = TRUE) |>
  mutate(category = category_map[category]) |>
  filter(!is.na(category))

# Supplement Grocery with convenience stores and greengrocers (separate gpkg files)
poi_dir <- file.path(data_dir, "03_pois")
for (extra in c("poi_convenience.gpkg", "poi_greengrocer.gpkg")) {
  extra_path <- file.path(poi_dir, extra)
  if (file.exists(extra_path)) {
    sf_extra <- st_read(extra_path, quiet = TRUE) |>
      mutate(category = "Grocery") |>
      select(osm_id, name, category)
    sf_pois <- bind_rows(sf_pois, sf_extra)
  }
}

# Deduplicate by osm_id (safety measure for overlapping OSM tags)
sf_pois <- distinct(sf_pois, osm_id, .keep_all = TRUE)

# Ensure CRS matches the project standard
if (st_crs(sf_pois) != st_crs(crs_proj)) {
  sf_pois <- st_transform(sf_pois, crs_proj)
}

message("POIs loaded: ", nrow(sf_pois))
