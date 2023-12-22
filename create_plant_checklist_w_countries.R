#Script para generar el listado de plantas con paises#
library(tidyverse)

config <- config::get()
DATA_FOLDER <- config$data_folder

# Load downloaded data files
files <- fs::dir_ls(path = DATA_FOLDER, glob="*_list.csv")

lista <- files %>% 
  map(read_csv)

names(lista) <- names(lista) %>%
  str_extract("([:upper:]+)_list.csv$", group = 1)

# Select working columns
variables <- c("target_taxon_name", "NAME_ES")

result <- lista %>% 
  map(\(df) select(df, any_of(variables))) %>%
  map(distinct)

# 
LISTA <- result %>% 
  list_rbind() %>%
  distinct()

LISTA2 <- LISTA %>% 
  group_by(target_taxon_name) %>% 
  summarise(country_name = paste(NAME_ES, collapse = " | "))


# Write data
LISTA2 %>%
  write_csv(fs::path_join(c(DATA_FOLDER, "plant_checklist_w_countries.csv")))
