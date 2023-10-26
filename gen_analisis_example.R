library(dplyr)
library(tibble)
library(httr)

options(scipen = 999)

BEE_SP_EXAMPLE <- "XYLVAR"

# Data loading and processing ----
# Bee sps
bee_sps_data <- readr::read_csv("./data/bee-sps.csv")

bee_sp <- bee_sps_data |>
  filter(ClaveSp == BEE_SP_EXAMPLE)
bee_name <- paste(bee_sp["Género"], bee_sp["Especie"])

# Interaction bee-plant
interaction_data <- readr::read_csv(
  paste0("./data/",bee_sp["ClaveSp"],"_valido.csv"))

bee_data <- tibble(
  biotic = TRUE,
  fGroupId = 1,
  grp = 1,
  isexternaldata = FALSE,
  level = "species",
  rank = "species",
  type = 0,
  value = bee_name
)

plant_data <- interaction_data |> 
  select(Nombre.Válido, Rango.Taxonómico) |>
  rename(value=Nombre.Válido) |>
  distinct() |>
  mutate(
    rank = case_when(
      Rango.Taxonómico == "Familia" ~ "family",
      Rango.Taxonómico == "Género" ~ "genus",
      Rango.Taxonómico == "Especie" ~ "species",
      .default = NA
    ),
    biotic = TRUE,
    level = "species",
    type = 0,
    fGroupId = 1,
    grp = 2,
    isexternaldata = FALSE
  ) |>
  filter(!is.na(rank)) |>
  select(-Rango.Taxonómico)

# Create data analysis request ----
URL1 <- "http://species.conabio.gob.mx/api/dbdev/niche/getTaxonsGroupNodes"

# Body object
data <- list(
  data_source = "gbif", 
  date = FALSE, 
  footprint_region = 4, 
  fosil = FALSE, 
  genTokenAndSaveResults = TRUE,
  grid_res = "32", 
  iddatadestino = NULL, 
  iddatafuente = NULL, 
  loadexternaldatadestino = FALSE, 
  loadexternaldatafuente = FALSE, 
  min_occ = 5, 
  niveltaxonomico = "species", 
  source = as.data.frame(bee_data), 
  target = as.data.frame(plant_data) 
)

# NOTE: To save the 'data' object to a file, you can use the following code
# data %>% 
# jsonlite::write_json(
#    pretty = TRUE, 
#    auto_unbox = TRUE, 
#    path = "testAnalysisCommunity.json"
#  )
# For debugging purposes

resp_dataset_creation <- POST(URL1, body = data, encode = "json")

# Save analysis in cache ----
URL2 <- "http://species.conabio.gob.mx/api/dbdev/niche/getTaxonsGroupEdges"

id_analysis <- content(resp_dataset_creation)$idanalisis 
token <- content(resp_dataset_creation)$token

# Body object
data2 <- list(
  min_occ = 5, 
  grid_res = "32", 
  footprint_region = 4, 
  idanalisis = id_analysis, 
  caso = 1, 
  data_source = "gbif", 
  niveltaxonomico = "species", 
  genTokenAndSaveResults = TRUE,
  token = token
  )

resp_cache_data <- POST(URL2, body = data2, encode = "json")

# NOTE: to explore the analysis results visit
# https://species.conabio.gob.mx/dbdev/comunidad_v0.1.html#link/?token=<token_value>
 