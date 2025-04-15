# install.packages("devtools")
# library(devtools)
# devtools::install_github("rdev-create/rutils")
rutils::library_install("jsonlite")
rutils::library_install("logger")
rutils::library_install("httr")
rutils::library_install("glue")
rutils::library_install("parallel")
rutils::library_install("R6")
rutils::library_install("rutils")

library(jsonlite)
library(logger)
library(httr)
library(glue)
library(parallel)
library(R6)
library(rutils)

manager <- rutils::WebDetailsCacheManager$new(cache_dir = "cache", log_dir = "logs")

info_on_interpro_databases <- rutils::fetch_web_content_as_object(url = "https://www.ebi.ac.uk/interpro/api/entry/")
names_databases <- unique(c(names(info_on_interpro_databases$entries$member_databases), "interpro"))
for (database in names_databases) {
  manager$add_cache(
    cache_name = database,
    list_all_entries_url = paste0("https://www.ebi.ac.uk/interpro/api/entry/", database, "/"),
    key_field_extraction_func = function(entry) entry$metadata$accession,
    single_entry_details_url = paste0("https://www.ebi.ac.uk/interpro/api/entry/", database, "/{entry_key}/"),
    flush_threshold = 100,
    list_all_entries_page_size = 1000
  )
}

manager$build_cache_threaded()
