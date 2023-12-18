library(dplyr)
library(tibble)
library(httr)

options(scipen = 999)
FOOTPRINT <- 4


args = commandArgs(trailingOnly = TRUE)
if (length(args) == 0) {
  stop("Please enter a single parameter (input file).\n", call. = FALSE)
} else if (length(args) == 1) {
  cat("Processing", args[1], "\n")
} else {
  stop("Single parameter is needed (input file).\n", call. = FALSE)
}
BEE_SP_EXAMPLE  <- args[1]
# BEE_SP_EXAMPLE <- "AGAOBL"

# Data loading and processing ----
# Bee sps
bee_sps_data <- readr::read_csv("./data/bee-sps.csv")

bee_sp <- bee_sps_data |>
  filter(ClaveSp == BEE_SP_EXAMPLE)
bee_name <- paste(bee_sp["Género"], bee_sp["Especie"])

# Interaction bee-plant
interaction_data <- readr::read_csv(
  paste0("./data/listados_plantas/",bee_sp["ClaveSp"],"_valido.csv"),
  locale = readr::locale(encoding = "latin1")
)

bee_data <- tibble(
  taxon_rank = "species",
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
    type = 0,
    level = "species"
  ) |>
  filter(!is.na(rank)) |>
  select(-Rango.Taxonómico)

covariables <- tibble(
  name = "plants",
  biotic = TRUE,
  group_item = 1,
  merge_vars = list(plant_data)
)
# Create data analysis request ----
URL1 <- "http://species.conabio.gob.mx/api/dbdev/niche/countsTaxonsGroup"

# Body object
data <- list(
  target_taxons = bee_data,
  covariables = covariables,
  apriori = FALSE,
  mapa_prob = FALSE,
  min_cells = 5,
  fosil = TRUE,
  date = TRUE,
  grid_resolution = "32",
  region = FOOTPRINT,
  data_source = "gbif",
  with_data_score_cell = TRUE,
  with_data_freq = TRUE,
  with_data_freq_cell = TRUE,
  with_data_score_decil = TRUE,
  iterations = 1,
  tipo_procedencia = "API",
  genTokenAndSaveResults = TRUE
)

# NOTE: To save the 'data' object to a file, you can use the following code
# data %>% 
#   jsonlite::write_json(
#      pretty = TRUE, 
#      auto_unbox = TRUE, 
#      path = "testAnalysisCommunity.json"
#    )
# For debugging purposes

resp_dataset_creation <- POST(URL1, body = data, encode = "json")

# resp_dataset_creation %>% 
#   content()

# NOTE: to explore the analysis results visit
# https://species.conabio.gob.mx/dbdev/geoportal_v0.1.html#link/?token=<token_value>
token <- content(resp_dataset_creation)$token
to_log <- c(BEE_SP_EXAMPLE, token, FOOTPRINT)

write(to_log, "niche_info.txt", append = TRUE, ncolumns = 3)
