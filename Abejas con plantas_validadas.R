#Unir nombres de plantas validados a archivos de plantas#

#librerias
library(data.table)
library(dplyr)
library(readr)
library(tidyverse)
library(stringr)

#Cargar listado de plantas#

Plantas <- read.csv("2da_lista_de_spp.csv", header =TRUE)

#Extraemos columnas de interés#
Plantas2 <- subset(Plantas, select=c(searched_taxon_name, target_taxon_name,	country_name,	Estatus.Taxonómico,	Nombre.Válido,	Autoridad,	Rango.Taxonómico,	Familia,	Forma.biológica
))

#Cargamos plantas por abeja en un data frame#


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
