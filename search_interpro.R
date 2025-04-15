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

build_local_interpro_cache <- function() {
  # This function builds a local cache of InterPro entries using the rutils package.
  # It fetches data from the InterPro API and stores it in a local directory for faster access.
  # The cache is built using multiple threads to speed up the process.

  # Create a cache manager object
  manager <- rutils::WebDetailsCacheManager$new(cache_dir = "cache", log_dir = "logs")

  # Fetch information about InterPro databases
  info_on_interpro_databases <- rutils::fetch_web_content_as_object(url = "https://www.ebi.ac.uk/interpro/api/entry/")

  # Get unique database names
  names_databases <- unique(c(names(info_on_interpro_databases$entries$member_databases), "interpro"))

  # Add caches for each database
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

  # Build the cache using multiple threads
  manager$build_cache_threaded()
}

# build_local_interpro_cache()

search_local_cache <- function(query) {
  # Use list.files() to get file names that end with '_details.rds'
  file_names <- list.files(
    path = "cache",
    pattern = "_details\\.rds$",
    ignore.case = TRUE
  )

  accession_list <- c()

  for (file_name in file_names) {
    data <- readRDS(file.path("cache", file_name))
    log_info("Processing file: {file_name}")
    for (name in names(data)) {
      entry <- data[[name]]
      match_found <- FALSE

      # ----- Check metadata$name fields -----
      if (!is.null(entry$metadata$name)) {
        if (!is.null(entry$metadata$name$name) &&
            grepl(query, entry$metadata$name$name, ignore.case = TRUE)) {
          match_found <- TRUE
        }
        if (!is.null(entry$metadata$name$short) &&
            grepl(query, entry$metadata$name$short, ignore.case = TRUE)) {
          match_found <- TRUE
        }
      }

      # ----- Check metadata$description field -----
      if (!is.null(entry$metadata$description)) {
        if (is.character(entry$metadata$description)) {
          if (grepl(query, entry$metadata$description, ignore.case = TRUE)) {
            match_found <- TRUE
          }
        } else if (is.list(entry$metadata$description)) {
          # Loop through each element in the list and check its 'text' field
          for (desc in entry$metadata$description) {
            if (is.list(desc) && !is.null(desc$text)) {
              if (grepl(query, desc$text, ignore.case = TRUE)) {
                match_found <- TRUE
                break
              }
            }
          }
        }
      }

      # If match found, add accession to list
      if (match_found) {
        accession_list <- c(accession_list, entry$metadata$accession)
        log_info("Found match in {file_name}: {entry$metadata$accession}")
      }
    }
  }

  # Return the list of accessions that matched
  accession_list
}

# Run the search for "nuclease" in metadata$name and metadata$description
result <- search_local_cache(query = "nuclease")
print(result)