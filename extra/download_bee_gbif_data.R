library(dplyr)
library(readr)
library(rgbif)

config <- config::get()

# Countries of interest
countries <- c('CA', 'MX', 'US')

#Lista de especies a descargar#
lista <- read_csv(config$bee_sp_codes_file)

lista <- lista %>%
  mutate(scientificName = paste(Género, Especie))

# match the names
gbif_taxon_keys <- lista %>%
  pull(scientificName) %>%
  # head(1000) %>% # only first 1000 names
  name_backbone_checklist() %>% # match to backbone
  filter(!matchType == "NONE") %>% # get matched names
  pull(usageKey)

# gbif_taxon_keys should be a long vector like this c(2977832,2977901,2977966,2977835,2977863)

# download the data
download_info <- occ_download(
  pred_in("country", countries),
  pred_in("taxonKey", gbif_taxon_keys), # important to use pred_in
  pred("hasCoordinate", TRUE),
  pred("hasGeospatialIssue", FALSE),
  format = "DWCA"
)

# Check if download is already available
# occ_download_wait(download_info)
