# This script utilizes data downloaded from GLOBI (refer to
# `download_interaction_data_from_globi.R`) to generate a checklist of plants
# for each bee species. Additionally, it assigns the countries where each plant
# species is present based on the downloaded data.

library(tidyverse)

config <- config::get()
DATA_FOLDER <- config$data_folder

# Load downloaded data files
files <- fs::dir_ls(path = DATA_FOLDER, glob="*_globi.csv")

lista <- files %>% 
  map(read_csv)

names(lista) <- names(lista) %>%
  str_extract("([:upper:]+)_globi.csv$", group = 1)

# View(lista)

# Discard empty datasets
lista <- lista %>%
  discard(\(df) nrow(df) == 0)

# Select working columns
variables <- c("source_taxon_name", "target_taxon_name", "latitude", "longitude")

result <- lista %>% 
  map(\(df) select(df, all_of(variables)))


# Remove duplicates
result2 <- result %>%
  map(distinct)


# Write list for each species
result2 %>%
  imap(\(df, sp_code) write_csv(df, 
                                fs::path_join(c(DATA_FOLDER, paste0(sp_code, "_list.csv")))))


# All plants list
Listado <- result2 %>%
  list_rbind() %>%
  select("target_taxon_name") %>%
  distinct()

Listado %>%
  write_csv(fs::path_join(c(DATA_FOLDER, "plants_checklist.csv")))
