#!/usr/bin/env Rscript
# Command-Line Interface (CLI) for submitting bee network analyses through the 
# utilization of plant interaction data on the 
# [SPECIES platform](https://chilam.c3.unam.mx/en/projects/about-species). 
# The script requires pre-existing bee files containing valid plant information 
# in the designated data folder to function effectively.

library(argparse)
library(cli)
library(dplyr, warn.conflicts=FALSE)
library(tibble)
library(stringr)
library(httr)

options(scipen = 999)
config <- config::get()

parser <- ArgumentParser(description="Script to register bee-plant network 
                         analysis in SPECIES platform")
parser$add_argument('bee_sp_code', type="character", 
                    help=str_glue("Bee code based on {config$bee_sp_codes_file} list"))

args <- parser$parse_args()
 
sp_code  <- args$bee_sp_code

cli_alert_info("Processing bee: {sp_code}")

# Data loading and processing ----
# Bee sps
bee_sps_data <- readr::read_csv(config$bee_sp_codes_file,
                                show_col_types=FALSE)

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
    biotic = TRUE,
    level = "species",
    type = 0,
    fGroupId = 1,
    grp = 2,
    isexternaldata = FALSE
  ) |>
  filter(!is.na(rank)) |>
  select(-`Rango Taxonómico`)

# Create data analysis request ----
URL1 <- "http://species.conabio.gob.mx/api/dbdev/niche/getTaxonsGroupNodes"

# Body object
data <- list(
  data_source = "gbif", 
  date = FALSE, 
  footprint_region = 3, 
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

if (resp_dataset_creation$status_code != 200) {
  cli_abort('Analysis for bee code {sp_code} could not be registered')
}

# Save analysis in cache ----
URL2 <- "http://species.conabio.gob.mx/api/dbdev/niche/getTaxonsGroupEdges"

id_analysis <- content(resp_dataset_creation)$idanalisis 
token <- content(resp_dataset_creation)$token

# Body object
data2 <- list(
  min_occ = 5, 
  grid_res = "32", 
  footprint_region = 3, 
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
# to_log <- c(BEE_SP_EXAMPLE, id_analysis, token)
# write(to_log, "inter_info.txt", append = TRUE, ncolumns = 3)
URL_RESULT <- "https://species.conabio.gob.mx/dbdev/comunidad_v0.1.html#link/?token="
url <- str_glue("{URL_RESULT}{token}")
result_data <- list(
  "sp_code" = sp_code,
  "id_analysis" = id_analysis,
  "token" = token
) %>% jsonlite::toJSON(auto_unbox = TRUE)

cli_alert_success(c("Analysis registered with information:\n", 
                    "{result_data}\n", 
                    "To view analysis visit:\n",
                    "{.url {url}}"))