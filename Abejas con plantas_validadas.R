#Unir nombres de plantas validados a archivos de plantas#

#librerias
# library(data.table)
# library(dplyr)
# library(readr)
library(tidyverse)
# library(stringr)

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

archivos <- list.files(path = "D:/OneDrive/Abejas/Scripts/con_pais/Abejas", pattern = "*.csv")
Bigdf <- readr::read_csv(archivos, id = "file_name")

#Modificamos la primer columna
Bigdf$file_name <- str_replace (Bigdf$file_name, ".csv", "")


#Unimos las columnas de interés#
Bigdf2<-merge(x = Bigdf, y = Plantas2, by = c("target_taxon_name"), all.x = T)

#Dividimos por especie (Clave)

Lista <- split(Bigdf2, f = Bigdf2$file_name)

variables <- c("source_taxon_name","latitude","longitude","ISO_A2","NAME_ES",
 "searched_taxon_name","target_taxon_name", "country_name","Estatus.Taxonómico","Nombre.Válido","Autoridad","Rango.Taxonómico",   "Familia","Forma.biológica")
Lista2 = lapply(Lista, "[", , variables)

#Generamos archivo .csv#
for(i in names(Lista2)){
  write.csv(Lista2[[i]], paste0(i,"_valido.csv"))
}
