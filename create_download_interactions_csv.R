library(tidyverse)

URL1 = "https://api.globalbioticinteractions.org/interaction?type=csv&interactionType=interactsWith&limit=4096&offset=0&refutes=false&includeObservations=true&sourceTaxon="
URL2 = "&targetTaxon=Plantae&field=source_taxon_id,source_taxon_name,source_taxon_path,source_taxon_path_ids,source_specimen_occurrence_id,source_specimen_institution_code,source_specimen_collection_code,source_specimen_catalog_number,source_specimen_life_stage_id,source_specimen_life_stage,source_specimen_physiological_state_id,source_specimen_physiological_state,source_specimen_body_part_id,source_specimen_body_part,source_specimen_sex_id,source_specimen_sex,source_specimen_basis_of_record,interaction_type,target_taxon_id,target_taxon_name,target_taxon_path,target_taxon_path_ids,target_specimen_occurrence_id,target_specimen_institution_code,target_specimen_collection_code,target_specimen_catalog_number,target_specimen_life_stage_id,target_specimen_life_stage,target_specimen_physiological_state_id,target_specimen_physiological_state,target_specimen_body_part_id,target_specimen_body_part,target_specimen_sex_id,target_specimen_sex,target_specimen_basis_of_record,latitude,longitude,collection_time_in_unix_epoch,study_citation,study_url,study_source_citation,study_source_archive_uri"
bee_data <- read_csv("./data/bee-sps.csv")

bee_data %>%
  mutate(scientificName = paste(Género, Especie),
         encodedName = URLencode(scientificName),
         downloadUrl = paste0(URL1, encodedName, URL2)) %>%
  write_csv("bee_interaction_downloads.csv")
