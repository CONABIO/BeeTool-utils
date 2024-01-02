#!/usr/bin/env Rscript

library(argparse)
library(cli)
library(dplyr, warn.conflicts = FALSE)
library(tibble)
library(httr)
library(stringr)

options(scipen = 999)
FOOTPRINT <- 4 # Analysis over North America Region

config <- config::get()

parser <- ArgumentParser(description="Script to register bee-plant niche interaction 
                         analysis in SPECIES platform")
parser$add_argument('bee_sp_code', type="character", 
                    help=str_glue("Bee code based on {config$bee_sp_codes_file} list"))

args <- parser$parse_args()

sp_code  <- args$bee_sp_code

cli_alert_info("Processing bee: {sp_code}")

BEE_SP_EXAMPLE  <- args[1]
# BEE_SP_EXAMPLE <- "AGAOBL"

# Data loading and processing ----
# Bee sps
bee_sps_data <- readr::read_csv(config$bee_sp_codes_file,
                                show_col_types = FALSE)

bee_sp <- bee_sps_data |>
  filter(ClaveSp == sp_code)

if (nrow(bee_sp) == 0) {
  cli_abort("Could not find bee with code: {sp_code}")
}
bee_name <- paste(bee_sp["Género"], bee_sp["Especie"])

# Interaction bee-plant
interaction_data <- readr::read_csv(
  fs::path_join(c(config$data_folder, str_glue("{sp_code}_valid.csv")))
)

bee_data <- tibble(
  taxon_rank = "species",
  value = bee_name
)

plant_data <- interaction_data |> 
  select(`Nombre Válido`, `Rango Taxonómico`) |>
  rename(value=`Nombre Válido`) |>
  distinct() |>
  mutate(
    rank = case_when(
      `Rango Taxonómico` == "Familia" ~ "family",
      `Rango Taxonómico` == "Género" ~ "genus",
      `Rango Taxonómico` == "Especie" ~ "species",
      .default = NA
    ),
    type = 0,
    level = "species"
  ) |>
  filter(!is.na(rank)) |>
  select(-`Rango Taxonómico`)

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

# NOTE: to explore the analysis results visit
# https://species.conabio.gob.mx/dbdev/geoportal_v0.1.html#link/?token=<token_value>
token <- content(resp_dataset_creation)$token
URL_RESULT <- "https://species.conabio.gob.mx/dbdev/geoportal_v0.1.html#link/?token="
url <- str_glue("{URL_RESULT}{token}")
result_data <- list(
  "sp_code" = sp_code,
  "token" = token
) %>% jsonlite::toJSON(auto_unbox = TRUE)

cli_alert_success(c("Analysis registered with information:\n",
                    "{result_data}\n",
                    "To view analysis visit:\n",
                    "{.url {url}}"))