# This script join bee plant interaction list with the valid names for each 
# plant.

library(tidyverse)

config <- config::get()
DATA_FOLDER <- config$data_folder
PLANT_CHECKLIST <- config$reviewed_plant_checklist

#Cargar listado de plantas#

Plantas <- readxl::read_xlsx(PLANT_CHECKLIST)

#Extraemos columnas de interés#
Plantas2 <- Plantas %>% 
  select(
    searched_taxon_name, 
    target_taxon_name,	
    country_name,	
    `Estatus Taxonómico`,	
    `Nombre Válido`,	
    Autoridad,	
    `Rango Taxonómico`,	
    Familia,	
    `Forma biológica`
  )

#Cargamos plantas por abeja en un data frame#
files <- fs::dir_ls(path = DATA_FOLDER, glob="*_list.csv")
lista <- files %>% 
  map(read_csv)

lista_w_valid_names <- lista %>%
  map(\(df) left_join(df, Plantas2, by="target_taxon_name"))

variables <- c(
  "source_taxon_name",
  "latitude",
  "longitude",
  "ISO_A2",
  "NAME_ES",
  "searched_taxon_name",
  "target_taxon_name", 
  "country_name",
  "Estatus Taxonómico",
  "Nombre Válido",
  "Autoridad",
  "Rango Taxonómico", 
  "Familia",
  "Forma biológica"
  )

lista_w_valid_names <- lista_w_valid_names %>%
  map(\(df) select(df, any_of(variables)))

# Add bee code as name in list
names(lista_w_valid_names) <- names(lista_w_valid_names) %>%
  str_extract("([:upper:]+)_list.csv$", group = 1)

lista_w_valid_names %>%
  imap(\(df, sp_code) write_csv(df, 
                                fs::path_join(c(DATA_FOLDER, paste0(sp_code, "_valid.csv")))))
