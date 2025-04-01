# Resume Analyzer

A Shiny web application for analyzing resumes and providing career recommendations.

## Features

- Resume parsing from PDF, DOCX, and TXT files
- Career recommendations using Google's Gemini API
- Interactive visualizations of skills, experience, and achievements
- Database export functionality
- Modern and responsive UI

## Live Demo

Visit the live application at: [Resume Analyzer](https://yourusername.shinyapps.io/resume-analyzer/)

## Local Development

To run the application locally for development:

1. Clone the repository:
```bash
git clone https://github.com/yourusername/resume-analyzer.git
cd resume-analyzer
```

2. Install required R packages:
```R
install.packages(c(
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
  "thematic",
  "writexl"
))
```

3. Run the application:
```R
shiny::runApp("app")
```

## Deployment

This application is deployed using Shinyapps.io. To deploy your own instance:

1. Sign up for a free account at [Shinyapps.io](https://www.shinyapps.io/)
2. Install the rsconnect package:
```R
install.packages('rsconnect')
```
3. Deploy the application:
```R
rsconnect::deployApp("app")
```

## Usage

1. Upload your resume (PDF, DOCX, or TXT format)
2. Enter your Gemini API key
3. Parse the resume to extract content
4. Generate career recommendations
5. View interactive visualizations
6. Export data to Excel database

## License

MIT License - feel free to use this project for your own purposes. 