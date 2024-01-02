library(dplyr)
library(purrr)
library(readr)
library(rgbif)

config <- config::get()

# Countries of interest
countries <- c('CA', 'MX', 'US')

#Lista de especies a descargar#
lista <- readxl::read_xlsx(config$reviewed_plant_checklist)

plant_checklist <- lista %>% 
  select(`Nombre Válido`) %>%
  rename(scientificName = `Nombre Válido`) %>%
  distinct()

chunk_size <- 800
no_of_chunks <- ceiling(nrow(plant_checklist)/800)

plant_checklist <- plant_checklist %>% 
  mutate(chunk = row_number() %% no_of_chunks)

plant_checklist_chunks <- plant_checklist %>%
  group_by(chunk) %>%
  group_split()

# match the names
get_gbif_backbone_checklist <- function(checklist_df) {
  checklist_df %>%
    pull(scientificName) %>%
    name_backbone_checklist() %>%
    filter(!matchType == "NONE") %>%
    pull(usageKey)
}

matched_keys <- plant_checklist_chunks %>% 
  map(get_gbif_backbone_checklist)
  
chunked_matched_keys <- matched_keys %>%
  list_c() %>%
  unique() %>%
  split(., ceiling(seq_along(.)/chunk_size))

# download the data
create_download_file <- function(taxon_keys) {
  download_info <- occ_download(
    pred_in("country", countries),
    pred_in("taxonKey", taxon_keys), # important to use pred_in
    pred("hasCoordinate", TRUE),
    pred("hasGeospatialIssue", FALSE),
    format = "DWCA"
  )
  
  return(download_info)
}

# GBIF has a limit of 3 concurrent download jobs
dowload_jobs <- chunked_matched_keys[1:3] %>% 
  map(create_download_file, .progress = TRUE)

# Check if download is already available
# occ_download_wait(download_info)
