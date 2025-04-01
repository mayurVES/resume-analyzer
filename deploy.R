# Deployment script for Resume Analyzer
# This script builds the application for GitHub Pages deployment

# Load required packages
library(shiny)
library(rsconnect)

# Function to build the application
build_app <- function() {
  # Create docs directory if it doesn't exist
  if (!dir.exists("docs")) {
    dir.create("docs")
  }
  
  # Copy app files to docs directory
  file.copy("app/new.R", "docs/app.R", overwrite = TRUE)
  
  # Create a simple index.html
  index_html <- '
<!DOCTYPE html>
<html>
<head>
  <title>Resume Analyzer</title>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    body {
      font-family: Arial, sans-serif;
      margin: 0;
      padding: 20px;
      background-color: #f8f9fa;
    }
    .container {
      max-width: 800px;
      margin: 0 auto;
      text-align: center;
    }
    h1 {
      color: #2C3E50;
      margin-bottom: 20px;
    }
    p {
      color: #34495e;
      line-height: 1.6;
    }
    .button {
      display: inline-block;
      padding: 10px 20px;
      background-color: #3498db;
      color: white;
      text-decoration: none;
      border-radius: 5px;
      margin-top: 20px;
    }
    .button:hover {
      background-color: #2980b9;
    }
  </style>
</head>
<body>
  <div class="container">
    <h1>Resume Analyzer</h1>
    <p>A powerful tool for analyzing resumes and providing career recommendations.</p>
    <a href="app.R" class="button">Launch Application</a>
  </div>
</body>
</html>
'
  
  writeLines(index_html, "docs/index.html")
  
  # Create a simple app.R that redirects to the main application
  app_r <- '
# Simple redirect to the main application
shiny::runApp("app")
'
  
  writeLines(app_r, "docs/app.R")
  
  print("Application built successfully!")
}

# Build the application
build_app() 