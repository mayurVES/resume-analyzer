# Install required packages if not already installed
required_packages <- c(
  "shiny",
  "shinydashboard",
  "shinycssloaders",
  "shinyjs",
  "shinyWidgets",
  "DT",
  "pdftools",
  "readtext",
  "tidyverse",
  "plotly",
  "httr",
  "jsonlite",
  "glue",
  "waiter",
  "thematic"
)

# Function to install missing packages
install_if_missing <- function(packages) {
  new_packages <- packages[!(packages %in% installed.packages()[,"Package"])]
  if(length(new_packages)) {
    install.packages(new_packages)
  }
}

# Install missing packages
install_if_missing(required_packages) 