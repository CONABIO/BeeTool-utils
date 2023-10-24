library(dplyr)
library(tibble)
library(httr)

options(scipen = 999)

# test <- '{
#   "source":[{
#     "biotic":true,
#     "level":"species",
#     "rank":"family",
#     "value":"Apidae",
#     "type":0,
#     "fGroupId":1,
#     "grp":0,
#     "isexternaldata":false
#   }],
#   "target":[{
#     "biotic":true,
#     "level":"species",
#     "rank":"class",
#     "value":"Magnoliopsida",
#     "type":0,
#     "fGroupId":2,
#     "grp":1,
#     "isexternaldata":false
#   }],
#   "min_occ":5,
#   "grid_res":"32",
#   "footprint_region":2,
#   "fosil":true,
#   "date":true,
#   "data_source":"gbif",
#   "loadexternaldatafuente":false,
#   "loadexternaldatadestino":false,
#   "iddatadestino":null,
#   "iddatafuente":null,
#   "niveltaxonomico":"species",
#   "genTokenAndSaveResults": true
# }'
# 
# data <- jsonlite::fromJSON(test)
# serialized <- dput(data)
# serialized
# 
# source = structure(list(biotic = TRUE, level = "species", 
#                         rank = "family", value = "Apidae", type = 0L, fGroupId = 1L, 
#                         grp = 0L, isexternaldata = FALSE), class = "data.frame", row.names = 1L), 
# target = structure(list(biotic = TRUE, level = "species", 
#                         rank = "class", value = "Magnoliopsida", type = 0L, fGroupId = 2L, 
#                         grp = 1L, isexternaldata = FALSE), class = "data.frame", row.names = 1L), 




interaction_data <- readr::read_csv("./data/XYLVAR_valido.csv")
colnames(interaction_data)
bee_sp <- unique(interaction_data[["source_taxon_name"]])[3]
bee_data <- tibble(
  biotic = TRUE,
  level = "species",
  rank = "species",
  value = bee_sp,
  type = 0,
  fGroupId = 1,
  grp = 1,
  isexternaldata = FALSE
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
    biotic = TRUE,
    level = "species",
    type = 0,
    fGroupId = 1,
    grp = 1,
    isexternaldata = FALSE
  ) |>
  filter(!is.na(rank)) |>
  select(-Rango.Taxonómico)

data <- list(source = as.data.frame(bee_data), target = as.data.frame(plant_data), min_occ = 5, grid_res = "32", footprint_region = 4, fosil = FALSE, 
     date = FALSE, data_source = "gbif", loadexternaldatafuente = FALSE, 
     loadexternaldatadestino = FALSE, iddatadestino = NULL, iddatafuente = NULL, 
     niveltaxonomico = "species", genTokenAndSaveResults = TRUE)
URL1 <- "http://species.conabio.gob.mx/api/dbdev/niche/getTaxonsGroupNodes"
r <- POST(URL1, body = data, encode = "json")
content(r)

