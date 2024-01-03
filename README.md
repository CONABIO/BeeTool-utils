# BeeTool Data Processing Scripts Repository

This repository aims to store scripts used for information processing.

## Objective

The primary purpose of this repository is to provide a centralized location for 
storing and managing scripts used in data and information processing. These 
scripts can address a variety of tasks, such as data analysis, format 
transformation, data cleaning, report generation, among others.

## Usage

You can explore the scripts available in this repository to find those relevant 
to your information processing needs. If you wish to use any of the scripts, 
make sure to review the documentation and comments within the script to 
understand its functionality and requirements.

## Data flow description and script dependency

Bee species and their `sp_codes` are listed in the `data/sp-sps.csv` file. The 
first objective is to create a plant checklist, which can be reviewed by a plant 
taxonomy specialist. To achieve this, follow the script execution steps outlined 
below.

```mermaid
flowchart TD
    A("file: data/bee-sps.csv") --> B("download_interaction_data_from_globi.R")
    B --> C("create_plant_checklist_by_bee.R")
    D("Download country border from Natural Earth Data")
    C --> E("add_country_to_checklist.R")
    D --> |edit config.yml file with path|E
    E --> F("create_plant_checklist_w_countries.R")
    F --> G("output file: data/plant_checklist_w_countries.csv")
```

As a result of this workflow, a new file is expected in the `data/` folder, 
named `plant_checklist_w_countries.csv`. This file serves as a working document 
for reviewing plant scientific names and assigning valid names if necessary. 

> [!IMPORTANT]
> When reviewed the plant scientific names do not modify the `target_taxon_name`
> column

It is necessary to integrate the reviewed information with the bee-plant 
interaction files. To achieve this, execute the 
`join_bee_plant_list_with_valid_names.R` script.

Finally, we should register the processed information on the SPECIES platform. The
scripts `submit_network_analysis.R` and `submit_niche_analysis.R` provide a CLI
to submit the analyses for each bee and print the link information where the 
analysis could be explored. The link information should be later registered on 
The Bee Tool. The scripts could be executed on a terminal as follows:

```shell
$  ./submit_network_analysis.R {sp_code}
```

where `sp_code` is a species code as in `data/bee-sps.csv`.

> [!IMPORTANT]
> Submit scripts assumed that the plant reviewed file include the following 
> columns: `Nombre Válido`, `Rango Taxonómico`, and `Nombre Válido`.

## Contact

If you have questions or need further information about this repository, you 
can contact Juan M Barrios <juan.barrios@conabio.gob.mx>.
