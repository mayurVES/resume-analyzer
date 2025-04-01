# app.R - Main application file for Resume Analyzer

# Required packages
library(shiny)
library(shinydashboard)
library(shinycssloaders)
library(shinyjs)
library(shinyWidgets)
library(DT)
library(pdftools)
library(readtext)
library(tidyverse)
library(plotly)
library(httr)
library(jsonlite)
library(glue)
library(waiter)
library(thematic)
library(writexl)

# Set theme for consistent visual style
thematic::thematic_shiny(font = "auto")

# Custom CSS for styling
css <- "
.skin-blue .main-header .logo {
  background-color: #2C3E50;
  font-weight: bold;
  font-size: 24px;
}
.skin-blue .main-header .navbar {
  background-color: #2C3E50;
}
.skin-blue .main-header .logo:hover {
  background-color: #1a252f;
}
.content-wrapper, .right-side {
  background-color: #f8f9fa;
}
.box {
  border-radius: 10px;
  box-shadow: 0 1px 3px rgba(0,0,0,0.12), 0 1px 2px rgba(0,0,0,0.24);
}
.nav-tabs-custom {
  box-shadow: 0 1px 3px rgba(0,0,0,0.12), 0 1px 2px rgba(0,0,0,0.24);
}
.resume-box {
  height: 600px;
  overflow-y: auto;
  padding: 15px;
  background-color: #ffffff;
  border-radius: 5px;
  border: 1px solid #ddd;
}
.recommendation-card {
  background: white;
  border-radius: 8px;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
  margin-bottom: 20px;
  padding: 20px;
  transition: transform 0.2s, box-shadow 0.2s;
}
.recommendation-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 8px rgba(0,0,0,0.15);
}
.recommendation-title {
  color: #2C3E50;
  font-size: 1.2em;
  font-weight: bold;
  margin-bottom: 10px;
  padding-bottom: 10px;
  border-bottom: 2px solid #3498db;
}
.recommendation-description {
  color: #34495e;
  line-height: 1.6;
  font-size: 1em;
}
.recommendations-container {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
  gap: 20px;
  padding: 20px;
}
.recommendation-icon {
  font-size: 1.5em;
  margin-right: 10px;
  color: #3498db;
}
.recommendation-header {
  display: flex;
  align-items: center;
  margin-bottom: 15px;
}
.recommendation-number {
  background: #3498db;
  color: white;
  width: 30px;
  height: 30px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: bold;
  margin-right: 10px;
}
.recommendation-stats {
  display: flex;
  justify-content: space-between;
  margin-top: 15px;
  padding-top: 15px;
  border-top: 1px solid #eee;
  font-size: 0.9em;
  color: #7f8c8d;
}
.recommendation-category {
  background: #e8f4f8;
  color: #2980b9;
  padding: 3px 8px;
  border-radius: 12px;
  font-size: 0.8em;
  margin-left: 10px;
}
.skill-badge {
  display: inline-block;
  padding: 5px 10px;
  margin: 3px;
  background-color: #3498db;
  color: white;
  border-radius: 15px;
  font-size: 0.9em;
}
.callout {
  padding: 15px;
  margin: 20px 0;
  border-left: 5px solid #eee;
  background-color: #f8f9fa;
}
.callout-info {
  border-left-color: #5bc0de;
}
.callout-warning {
  border-left-color: #f0ad4e;
}
.btn-primary {
  background-color: #3498db;
  border-color: #2980b9;
}
.btn-primary:hover {
  background-color: #2980b9;
  border-color: #2471a3;
}
"

# Add error handling wrapper function
safe_call <- function(expr, error_message = "An error occurred") {
  tryCatch({
    expr
  }, error = function(e) {
    print(paste("Error:", e$message))
    showNotification(error_message, type = "error")
    return(NULL)
  }, warning = function(w) {
    print(paste("Warning:", w$message))
    showNotification(w$message, type = "warning")
  })
}

# Function to parse resume text from PDF or DOCX
parse_resume <- function(file_path) {
  print("=== DEBUG: Starting parse_resume function ===")
  
  if (is.null(file_path)) {
    return(list(success = FALSE, message = "No file path provided"))
  }
  
  tryCatch({
    # If the file path is actually a JSON string, use it directly
    if (is.character(file_path) && grepl("^\\{.*\\}$", file_path, perl = TRUE)) {
      print("DEBUG: Using direct JSON text input")
      text <- file_path
    } else {
      file_ext <- tools::file_ext(file_path)
      print(paste("File extension:", file_ext))
      
      if (!file.exists(file_path)) {
        return(list(success = FALSE, message = "File does not exist"))
      }
      
      if (file.size(file_path) > 10 * 1024 * 1024) {  # 10MB limit
        return(list(success = FALSE, message = "File size exceeds 10MB limit"))
      }
      
      if (file_ext == "pdf") {
        print("DEBUG: Parsing PDF file")
        text <- pdftools::pdf_text(file_path)
        if (length(text) == 0) {
          return(list(success = FALSE, message = "PDF file is empty or corrupted"))
        }
        text <- paste(text, collapse = " ")
      } else if (file_ext %in% c("docx", "doc")) {
        print("DEBUG: Parsing DOCX/DOC file")
        text <- readtext::readtext(file_path)$text
        if (is.null(text) || nchar(text) == 0) {
          return(list(success = FALSE, message = "Document file is empty or corrupted"))
        }
      } else if (file_ext == "txt") {
        print("DEBUG: Parsing TXT file")
        text <- readLines(file_path)
        if (length(text) == 0) {
          return(list(success = FALSE, message = "Text file is empty"))
        }
        text <- paste(text, collapse = " ")
      } else {
        return(list(success = FALSE, message = "Unsupported file format. Please upload a PDF, DOCX, or TXT file."))
      }
    }
    
    # Basic cleaning
    print("DEBUG: Cleaning parsed text")
    text <- gsub("\\s+", " ", text)  # Replace multiple spaces with a single space
    text <- trimws(text)  # Trim whitespace
    
    if (nchar(text) == 0) {
      return(list(success = FALSE, message = "No text content found in the file"))
    }
    
    print(paste("DEBUG: Parsed text length:", nchar(text)))
    return(list(success = TRUE, text = text))
    
  }, error = function(e) {
    print(paste("DEBUG: Error in parse_resume:", e$message))
    return(list(success = FALSE, message = paste("Error parsing resume:", e$message)))
  })
}

# Function to validate Gemini API key
validate_api_key <- function(api_key) {
  print("=== DEBUG: Starting validate_api_key function ===")
  print(paste("API key length:", nchar(api_key)))
  
  tryCatch({
    print("DEBUG: Making test request to Gemini API")
    # Simple test request to Gemini API
    url <- "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent"
    
    body <- list(
      contents = list(
        list(
          parts = list(
            list(text = "Test message")
          )
        )
      ),
      generationConfig = list(
        temperature = 0.7,
        maxOutputTokens = 100
      )
    )
    
    response <- httr::POST(
      url = paste0(url, "?key=", api_key),
      body = body,
      encode = "json",
      httr::content_type_json()
    )
    
    if (httr::status_code(response) == 200) {
      print("DEBUG: API key validation successful")
      return(list(success = TRUE, message = "API key is valid"))
    } else {
      print(paste("DEBUG: API key validation failed with status code:", httr::status_code(response)))
      error_content <- httr::content(response, "parsed", encoding = "UTF-8")
      return(list(success = FALSE, message = paste("API Error:", error_content$error$message)))
    }
  }, error = function(e) {
    print(paste("DEBUG: Error in validate_api_key:", e$message))
    return(list(success = FALSE, message = paste("Error validating API key:", e$message)))
  })
}

# Function to call LLM API for recommendations
get_recommendations <- function(resume_text, api_key) {
  print("=== DEBUG: Starting get_recommendations function ===")
  print(paste("Resume text length:", nchar(resume_text)))
  
  tryCatch({
    print("DEBUG: Preparing API request")
    # Prepare the API request to Gemini
    prompt_text <- paste0(
      "Based on the following resume, provide 5 specific career development recommendations. ",
      "Focus on skill gaps, career path suggestions, and potential growth opportunities. ",
      "Format the response as a JSON array of objects, each with 'title' and 'description' keys.\n\n",
      "Resume text:\n", resume_text
    )
    
    url <- "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent"
    
    body <- list(
      contents = list(
        list(
          parts = list(
            list(text = prompt_text)
          )
        )
      ),
      generationConfig = list(
        temperature = 0.7,
        maxOutputTokens = 2048
      )
    )
    
    print("DEBUG: Sending API request")
    response <- httr::POST(
      url = paste0(url, "?key=", api_key),
      body = body,
      encode = "json",
      httr::content_type_json()
    )
    
    print(paste("DEBUG: API response status code:", httr::status_code(response)))
    
    if (httr::status_code(response) != 200) {
      print("DEBUG: API request failed")
      error_content <- httr::content(response, "parsed", encoding = "UTF-8")
      return(list(success = FALSE, message = paste("API Error:", error_content$error$message)))
    }
    
    content <- httr::content(response, "parsed", encoding = "UTF-8")
    print("DEBUG: Successfully parsed API response")
    
    # Extract text from the response
    response_text <- content$candidates[[1]]$content$parts[[1]]$text
    print(paste("DEBUG: Response text length:", nchar(response_text)))
    
    # Print raw response for debugging
    print("=== RAW API RESPONSE ===")
    print(response_text)
    print("=== END RAW RESPONSE ===")
    
    # Parse JSON from the response
    print("DEBUG: Attempting to parse recommendations JSON")
    recommendations <- tryCatch({
      # First try direct JSON parsing
      parsed_json <- fromJSON(response_text)
      print("DEBUG: Direct JSON parsing successful")
      print("=== PARSED RECOMMENDATIONS ===")
      print(parsed_json)
      print("=== END PARSED RECOMMENDATIONS ===")
      parsed_json
    }, error = function(e) {
      print(paste("DEBUG: Direct JSON parsing failed:", e$message))
      # If direct parsing fails, try to clean and extract JSON
      tryCatch({
        # Clean up the text by removing backticks and extra whitespace
        cleaned_text <- gsub("```json|```", "", response_text)
        cleaned_text <- trimws(cleaned_text)
        
        # Try to parse the cleaned JSON
        parsed_json <- fromJSON(cleaned_text)
        print("DEBUG: Cleaned JSON parsing successful")
        print("=== PARSED RECOMMENDATIONS ===")
        print(parsed_json)
        print("=== END PARSED RECOMMENDATIONS ===")
        parsed_json
      }, error = function(e2) {
        print(paste("DEBUG: Cleaned JSON parsing failed:", e2$message))
        # If still fails, try to extract JSON array pattern
        json_match <- regexpr("\\[\\s*\\{.*\\}\\s*\\]", response_text, perl = TRUE)
        if (json_match > 0) {
          json_text <- regmatches(response_text, json_match)
          parsed_json <- fromJSON(json_text)
          print("DEBUG: Regex JSON extraction successful")
          print("=== PARSED RECOMMENDATIONS ===")
          print(parsed_json)
          print("=== END PARSED RECOMMENDATIONS ===")
          parsed_json
        } else {
          print("DEBUG: No valid JSON found, creating structured format from text")
          # If no valid JSON found, create structured format from text
          # Split text into sections based on numbered items or titles
          sections <- strsplit(response_text, "\\d+\\.|\\n\\n")[[1]]
          sections <- sections[sections != ""]
          sections <- trimws(sections)
          
          recommendations_list <- lapply(seq_along(sections), function(i) {
            section <- sections[i]
            # Try to split into title and description
            parts <- strsplit(section, ":")[[1]]
            if (length(parts) >= 2) {
              list(
                title = trimws(parts[1]),
                description = trimws(paste(parts[-1], collapse = ":"))
              )
            } else {
              list(
                title = paste("Recommendation", i),
                description = trimws(section)
              )
            }
          })
          
          print("=== PARSED RECOMMENDATIONS ===")
          print(recommendations_list)
          print("=== END PARSED RECOMMENDATIONS ===")
          recommendations_list
        }
      })
    })
    
    print(paste("DEBUG: Number of recommendations:", nrow(recommendations)))
    
    # Convert data frame to list of lists if needed
    if (is.data.frame(recommendations)) {
      recommendations <- lapply(1:nrow(recommendations), function(i) {
        list(
          title = as.character(recommendations$title[i]),
          description = as.character(recommendations$description[i])
        )
      })
    }
    
    return(list(success = TRUE, recommendations = recommendations))
  }, error = function(e) {
    print(paste("DEBUG: Error in get_recommendations:", e$message))
    return(list(success = FALSE, message = paste("Error getting recommendations:", e$message)))
  })
}

# Function to extract structured data from resume
extract_structured_data <- function(resume_text, api_key) {
  print("=== DEBUG: Starting extract_structured_data function ===")
  print(paste("Resume text length:", nchar(resume_text)))
  
  tryCatch({
    print("DEBUG: Preparing API request")
    # Prepare the API request
    prompt_text <- paste0(
      "Extract structured data from the following resume and format it as a valid JSON object. ",
      "Use exactly this structure:\n",
      "{\n",
      "  'skills': ['skill1', 'skill2', ...],\n",
      "  'education': [{'degree': 'degree1', 'institution': 'inst1', 'year': 'year1'}, ...],\n",
      "  'experience': [{'title': 'title1', 'company': 'company1', 'duration': 'duration1', 'description': 'desc1'}, ...],\n",
      "  'projects': [{'name': 'project1', 'description': 'desc1'}, ...],\n",
      "  'achievements': ['achievement1', 'achievement2', ...]\n",
      "}\n\n",
      "Resume text:\n", resume_text
    )
    
    url <- "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent"
    
    body <- list(
      contents = list(
        list(
          parts = list(
            list(text = prompt_text)
          )
        )
      ),
      generationConfig = list(
        temperature = 0.2,
        maxOutputTokens = 2048
      )
    )
    
    print("DEBUG: Sending API request")
    response <- httr::POST(
      url = paste0(url, "?key=", api_key),
      body = body,
      encode = "json",
      httr::content_type_json()
    )
    
    print(paste("DEBUG: API response status code:", httr::status_code(response)))
    
    if (httr::status_code(response) != 200) {
      print("DEBUG: API request failed")
      error_content <- httr::content(response, "parsed", encoding = "UTF-8")
      return(list(success = FALSE, message = paste("API Error:", error_content$error$message)))
    }
    
    content <- httr::content(response, "parsed", encoding = "UTF-8")
    print("DEBUG: Successfully parsed API response")
    
    # Extract text from the response
    response_text <- content$candidates[[1]]$content$parts[[1]]$text
    print(paste("DEBUG: Response text length:", nchar(response_text)))
    print("=== RAW API RESPONSE ===")
    print(response_text)
    print("=== END RAW RESPONSE ===")
    
    # Parse JSON from the response
    print("DEBUG: Attempting to parse structured data JSON")
    structured_data <- tryCatch({
      # First try direct JSON parsing
      fromJSON(response_text)
    }, error = function(e) {
      # If direct parsing fails, try to clean and extract JSON
      tryCatch({
        # Clean up the text by removing backticks and extra whitespace
        cleaned_text <- gsub("```json|```", "", response_text)
        cleaned_text <- trimws(cleaned_text)
        
        # Try to parse the cleaned JSON
        fromJSON(cleaned_text)
      }, error = function(e2) {
        # If still fails, try to extract JSON object pattern
        json_match <- regexpr("\\{[^\\{\\}]*\\}", response_text, perl = TRUE)
        if (json_match > 0) {
          json_text <- regmatches(response_text, json_match)
          return(fromJSON(json_text))
        } else {
          # Create empty structure if no valid JSON found
          return(list(
            skills = character(0),
            education = data.frame(degree=character(0), institution=character(0), year=character(0)),
            experience = data.frame(title=character(0), company=character(0), duration=character(0), description=character(0)),
            projects = data.frame(name=character(0), description=character(0)),
            achievements = character(0)
          ))
        }
      })
    })
    
    # Print detailed structured data
    print("\n=== STRUCTURED DATA DETAILS ===")
    
    # Print Skills
    print("\nSKILLS:")
    print("----------------------------------------")
    if (length(structured_data$skills) > 0) {
      print(paste("Total skills:", length(structured_data$skills)))
      print(structured_data$skills)
    } else {
      print("No skills found")
    }
    
    # Print Education
    print("\nEDUCATION:")
    print("----------------------------------------")
    if (nrow(structured_data$education) > 0) {
      print(paste("Total education entries:", nrow(structured_data$education)))
      print(structured_data$education)
    } else {
      print("No education entries found")
    }
    
    # Print Experience
    print("\nEXPERIENCE:")
    print("----------------------------------------")
    if (nrow(structured_data$experience) > 0) {
      print(paste("Total experience entries:", nrow(structured_data$experience)))
      print(structured_data$experience)
    } else {
      print("No experience entries found")
    }
    
    # Print Projects
    print("\nPROJECTS:")
    print("----------------------------------------")
    if (nrow(structured_data$projects) > 0) {
      print(paste("Total projects:", nrow(structured_data$projects)))
      print(structured_data$projects)
    } else {
      print("No projects found")
    }
    
    # Print Achievements
    print("\nACHIEVEMENTS:")
    print("----------------------------------------")
    if (length(structured_data$achievements) > 0) {
      print(paste("Total achievements:", length(structured_data$achievements)))
      print(structured_data$achievements)
    } else {
      print("No achievements found")
    }
    
    print("\n=== END STRUCTURED DATA DETAILS ===\n")
    
    return(list(success = TRUE, data = structured_data))
  }, error = function(e) {
    print(paste("DEBUG: Error in extract_structured_data:", e$message))
    return(list(success = FALSE, message = paste("Error extracting structured data:", e$message)))
  })
}

# UI definition
ui <- dashboardPage(
  skin = "blue",
  
  # Dashboard header
  dashboardHeader(
    title = "Resume Analyzer",
    titleWidth = 300
  ),
  
  # Dashboard sidebar
  dashboardSidebar(
    width = 300,
    sidebarMenu(
      menuItem("Resume Input", tabName = "input", icon = icon("file-upload")),
      menuItem("Recommendations", tabName = "recommendations", icon = icon("lightbulb")),
      menuItem("Visualization", tabName = "visualization", icon = icon("chart-bar")),
      menuItem("Add to Database", tabName = "database", icon = icon("database")),
      menuItem("About", tabName = "about", icon = icon("info-circle"))
    ),
    tags$div(
      class = "sidebar-form",
      style = "padding: 10px;",
      passwordInput(
        "api_key", 
        "Gemini API Key", 
        placeholder = "Enter your API key",
        width = "100%"
      ),
      p("Your API key is needed for LLM-powered features.", style = "font-size: 0.8em; color: #999;"),
      actionButton(
        "save_api_key", 
        "Save API Key", 
        icon = icon("key"),
        style = "margin-top: 5px; width: 100%;"
      )
    )
  ),
  
  # Dashboard body
  dashboardBody(
    useWaiter(),  # Initialize waiter for loading screens
    useShinyjs(),  # Initialize shinyjs
    tags$head(
      tags$style(css)
    ),
    
    tabItems(
      # Resume Input tab
      tabItem(
        tabName = "input",
        fluidRow(
          box(
            title = "Upload Resume", 
            width = 12,
            status = "primary", 
            solidHeader = TRUE,
            fileInput("resume_file", "Choose a file",
              accept = c(
                "application/pdf",
                "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
                "application/msword",
                "text/plain"
              )
            ),
            actionButton("parse_btn", "Parse Resume", icon = icon("cogs"), class = "btn-primary"),
            div(
              class = "callout callout-info",
              style = "margin-top: 20px;",
              h4("Supported File Formats"),
              p("PDF, DOCX, DOC, and TXT files are supported.")
            )
          )
        ),
        fluidRow(
          box(
            title = "Parsed Resume Content",
            width = 12,
            status = "info",
            solidHeader = TRUE,
            uiOutput("resume_content") %>% withSpinner(color="#3498db")
          )
        )
      ),
      
      # Recommendations tab
      tabItem(
        tabName = "recommendations",
        fluidRow(
          box(
            title = "Career and Skill Development Recommendations",
            width = 12,
            status = "primary",
            solidHeader = TRUE,
            actionButton("get_recommendations_btn", "Generate Recommendations", icon = icon("magic"), class = "btn-primary"),
            div(
              style = "margin-top: 20px;",
              uiOutput("recommendations_ui") %>% withSpinner(color="#3498db")
            )
          )
        )
      ),
      
      # Visualization tab
      tabItem(
        tabName = "visualization",
        fluidRow(
          column(
            width = 12,
            box(
              title = "Resume Visualization",
              width = 12,
              status = "primary",
              solidHeader = TRUE,
              actionButton("visualize_btn", "Generate Visualizations", icon = icon("chart-line"), class = "btn-primary"),
              div(
                style = "margin-top: 20px;",
                tabsetPanel(
                  id = "viz_tabs",
                  tabPanel(
                    "Skills",
                    div(style = "height: 15px;"), # Spacer
                    plotlyOutput("skills_chart") %>% withSpinner(color="#3498db"),
                    div(style = "height: 15px;") # Spacer
                  ),
                  tabPanel(
                    "Experience",
                    div(style = "height: 15px;"), # Spacer
                    plotlyOutput("experience_chart") %>% withSpinner(color="#3498db"),
                    div(style = "height: 15px;"), # Spacer
                    DTOutput("experience_table") %>% withSpinner(color="#3498db")
                  ),
                  tabPanel(
                    "Education & Projects",
                    div(style = "height: 15px;"), # Spacer
                    fluidRow(
                      column(
                        width = 6,
                        plotlyOutput("education_chart") %>% withSpinner(color="#3498db")
                      ),
                      column(
                        width = 6,
                        plotlyOutput("projects_chart") %>% withSpinner(color="#3498db")
                      )
                    ),
                    div(style = "height: 15px;"), # Spacer
                    DTOutput("projects_table") %>% withSpinner(color="#3498db")
                  ),
                  tabPanel(
                    "Achievements",
                    div(style = "height: 15px;"), # Spacer
                    plotlyOutput("achievements_chart") %>% withSpinner(color="#3498db"),
                    div(style = "height: 15px;"), # Spacer
                    uiOutput("achievements_list") %>% withSpinner(color="#3498db")
                  )
                )
              )
            )
          )
        )
      ),
      
      # Add Database tab
      tabItem(
        tabName = "database",
        fluidRow(
          column(
            width = 12,
            box(
              title = "Export Resume Data to Excel",
              width = 12,
              status = "primary",
              solidHeader = TRUE,
              div(
                style = "margin-bottom: 20px;",
                p("Export all parsed resume data to an Excel file with multiple sheets for different categories.")
              ),
              actionButton("export_btn", "Export to Excel", icon = icon("file-excel"), class = "btn-primary"),
              div(
                style = "margin-top: 20px;",
                uiOutput("export_status") %>% withSpinner(color="#3498db")
              )
            )
          )
        ),
        fluidRow(
          column(
            width = 12,
            box(
              title = "Database Contents",
              width = 12,
              status = "info",
              solidHeader = TRUE,
              div(
                style = "margin-bottom: 20px;",
                p("View all resumes in the database. Click on column headers to sort.")
              ),
              DTOutput("database_table") %>% withSpinner(color="#3498db")
            )
          )
        )
      ),
      
      # About tab
      tabItem(
        tabName = "about",
        fluidRow(
          box(
            title = "About Resume Analyzer",
            width = 12,
            status = "info",
            solidHeader = TRUE,
            h3("Welcome to Resume Analyzer!"),
            p("This application helps you analyze your resume and receive personalized career recommendations."),
            h4("How to Use:"),
            tags$ol(
              tags$li("Upload your resume (PDF, DOCX, or TXT format) in the 'Resume Input' tab."),
              tags$li("Parse your resume to extract its content."),
              tags$li("Navigate to the 'Recommendations' tab to receive career advice based on your resume."),
              tags$li("Explore the 'Visualization' tab to see your skills, experience, and achievements visualized.")
            ),
            h4("Privacy Note:"),
            p("Your resume data is processed locally and only sent to the LLM API for generating recommendations and visualizations. Your API key is required for these features to work."),
            h4("Technical Requirements:"),
            p("To run this application locally, you need R with the packages listed in the installation documentation."),
            h4("Developer Information:"),
            p("This application was created using R Shiny, with visualization libraries including ggplot2 and plotly, and integrates with the Google Gemini API for intelligent resume analysis.")
          )
        )
      )
    )
  )
)

# Server logic
server <- function(input, output, session) {
  # Add error handling for reactive values
  values <- reactiveValues(
    resume_text = NULL,
    resume_parsed = FALSE,
    recommendations = NULL,
    structured_data = NULL,
    api_key = NULL,
    api_key_valid = FALSE,
    export_status = NULL,
    export_file = NULL,
    database_file = "resume_database.xlsx",
    current_user_name = NULL,
    database_contents = NULL,
    error_message = NULL  # New reactive value for error messages
  )
  
  # Add error handling observer
  observe({
    if (!is.null(values$error_message)) {
      showNotification(values$error_message, type = "error")
      values$error_message <- NULL
    }
  })
  
  # Initialize with the provided resume text
  observe({
    initial_resume_text <- 'Upload Resume and Parsed Content will be displayed here'
    
    # Parse the initial resume text
    result <- parse_resume(initial_resume_text)
    
    if (result$success) {
      values$resume_text <- result$text
      values$resume_parsed <- TRUE
    }
  })
  
  # Update resume content rendering with error handling
  output$resume_content <- renderUI({
    safe_call({
      if (is.null(values$resume_text)) {
        return(
          div(
            class = "resume-box",
            p("Upload and parse a resume to see its content here.", class = "text-muted")
          )
        )
      }
      
      div(
        class = "resume-box",
        style = "background-color: white; padding: 20px; border: 1px solid #ddd; border-radius: 5px; margin: 10px 0;",
        div(
          style = "white-space: pre-wrap; font-family: monospace; line-height: 1.5; max-height: 600px; overflow-y: auto;",
          tags$div(
            style = "margin: 0; background-color: transparent; border: none; font-size: 14px; color: black;",
            values$resume_text
          )
        )
      )
    }, "Error displaying resume content")
  })
  
  # Update API key validation with error handling
  observeEvent(input$save_api_key, {
    safe_call({
      if (is.null(input$api_key) || input$api_key == "") {
        values$error_message <- "Please enter a valid API key"
        return()
      }
      
      showNotification("Validating API key...", type = "message")
      result <- validate_api_key(input$api_key)
      
      if (result$success) {
        values$api_key <- input$api_key
        values$api_key_valid <- TRUE
        showNotification("API key validated and saved successfully", type = "message")
      } else {
        values$api_key_valid <- FALSE
        values$error_message <- result$message
      }
    }, "Error validating API key")
  })
  
  # Update parse resume button with error handling
  observeEvent(input$parse_btn, {
    safe_call({
      req(input$resume_file)
      
      waiter <- Waiter$new(
        html = tagList(
          spin_circle(),
          h4("Parsing resume...", style = "color: white;")
        ),
        color = "rgba(0, 0, 0, 0.7)"
      )
      waiter$show()
      
      result <- parse_resume(input$resume_file$datapath)
      waiter$hide()
      
      if (result$success) {
        values$resume_text <- result$text
        values$resume_parsed <- TRUE
        showNotification("Resume parsed successfully", type = "message")
      } else {
        values$error_message <- result$message
      }
    }, "Error parsing resume")
  })
  
  # Generate recommendations
  observeEvent(input$get_recommendations_btn, {
    print("=== DEBUG: Generate recommendations button clicked ===")
    req(values$resume_parsed)
    print("DEBUG: Resume parsed status:", values$resume_parsed)
    print("DEBUG: API key valid status:", values$api_key_valid)
    
    if (!values$api_key_valid) {
      showNotification("Please enter and validate a valid API key first", type = "error")
      return()
    }
    
    # Create a loading screen
    waiter <- Waiter$new(
      html = tagList(
        spin_circle(),
        h4("Generating recommendations...", style = "color: white;")
      ),
      color = "rgba(0, 0, 0, 0.7)"
    )
    waiter$show()
    
    # Get recommendations from LLM API
    result <- get_recommendations(values$resume_text, values$api_key)
    
    waiter$hide()
    
    if (result$success) {
      values$recommendations <- result$recommendations
      
      output$recommendations_ui <- renderUI({
        if (is.null(values$recommendations) || length(values$recommendations) == 0) {
          return(
            div(
              class = "callout callout-warning",
              h4("No Recommendations"),
              p("No recommendations were generated. Try again with a different resume.")
            )
          )
        }
        
        # Create recommendation items with improved styling
        recommendations_list <- lapply(seq_along(values$recommendations), function(i) {
          rec <- values$recommendations[[i]]
          
          # Ensure we have valid title and description
          title <- if (is.null(rec$title)) paste("Recommendation", i) else rec$title
          description <- if (is.null(rec$description)) "No description available" else rec$description
          
          # Determine category based on title keywords
          category <- ifelse(
            grepl("skill|technical|programming|software|cloud|data|ml|ai", tolower(title)),
            "Technical",
            ifelse(
              grepl("communication|presentation|writing|speaking", tolower(title)),
              "Soft Skills",
              "Career Development"
            )
          )
          
          # Determine icon based on category
          icon_name <- switch(
            category,
            "Technical" = "code",
            "Soft Skills" = "comments",
            "Career Development" = "briefcase"
          )
          
          div(
            class = "recommendation-card",
            div(
              class = "recommendation-header",
              div(class = "recommendation-number", i),
              div(
                class = "recommendation-title",
                icon(icon_name, class = "recommendation-icon"),
                title,
                span(class = "recommendation-category", category)
              )
            ),
            div(
              class = "recommendation-description",
              description
            ),
            div(
              class = "recommendation-stats",
              span(icon("clock"), " Estimated Impact: High"),
              span(icon("chart-line"), " Priority: ", ifelse(i <= 2, "High", "Medium"))
            )
          )
        })
        
        # Wrap recommendations in a container
        div(
          class = "recommendations-container",
          recommendations_list
        )
      })
      
      showNotification("Recommendations generated successfully", type = "message")
    } else {
      output$recommendations_ui <- renderUI({
        div(
          class = "callout callout-warning",
          h4("Error"),
          p(result$message)
        )
      })
      
      showNotification(result$message, type = "error")
    }
  })
  
  # Generate visualizations
  observeEvent(input$visualize_btn, {
    print("=== DEBUG: Visualize button clicked ===")
    req(values$resume_parsed)
    print("DEBUG: Resume parsed status:", values$resume_parsed)
    print("DEBUG: API key valid status:", values$api_key_valid)
    
    if (!values$api_key_valid) {
      showNotification("Please enter and validate a valid API key first", type = "error")
      return()
    }
    
    # Create a loading screen
    waiter <- Waiter$new(
      html = tagList(
        spin_circle(),
        h4("Analyzing resume and generating visualizations...", style = "color: white;")
      ),
      color = "rgba(0, 0, 0, 0.7)"
    )
    waiter$show()
    
    # Extract structured data from resume
    result <- extract_structured_data(values$resume_text, values$api_key)
    
    waiter$hide()
    
    if (result$success) {
      values$structured_data <- result$data
      
      # Debug output
      print("Structured data extracted successfully")
      print("Data structure:")
      print(str(values$structured_data))
      
      # Check if we have the required data
      if (is.null(values$structured_data)) {
        showNotification("No structured data was extracted from the resume", type = "error")
        return()
      }
      
      # Check each data section
      sections <- c("skills", "education", "experience", "projects", "achievements")
      for (section in sections) {
        if (is.null(values$structured_data[[section]]) || length(values$structured_data[[section]]) == 0) {
          print(paste("Warning: No", section, "data available"))
        } else {
          print(paste(section, "count:", length(values$structured_data[[section]])))
        }
      }
      
      # Generate visualizations based on the structured data
      tryCatch({
        generate_visualizations()
        showNotification("Visualizations generated successfully", type = "message")
      }, error = function(e) {
        print("Error generating visualizations:", e$message)
        showNotification(paste("Error generating visualizations:", e$message), type = "error")
      })
    } else {
      print("Error extracting structured data:", result$message)
      showNotification(result$message, type = "error")
    }
  })
  
  # Function to generate all visualizations
  generate_visualizations <- function() {
    print("=== DEBUG: Starting generate_visualizations function ===")
    req(values$structured_data)
    
    print("DEBUG: Generating visualizations with data:")
    print(str(values$structured_data))
    
    # Skills visualization
    output$skills_chart <- renderPlotly({
      print("DEBUG: Rendering skills chart")
      req(values$structured_data$skills)
      print(paste("DEBUG: Number of skills:", length(values$structured_data$skills)))
      
      if (length(values$structured_data$skills) == 0) {
        return(plotly_empty() %>% layout(title = "No skills data available"))
      }
      
      # Prepare data
      skills_df <- data.frame(
        skill = values$structured_data$skills,
        count = 1
      )
      
      skills_summary <- skills_df %>%
        group_by(skill) %>%
        summarize(count = sum(count)) %>%
        arrange(desc(count))
      
      # Create bar chart
      p <- plot_ly(
        skills_summary,
        x = ~reorder(skill, count),
        y = ~count,
        type = "bar",
        marker = list(color = "#3498db")
      ) %>%
        layout(
          title = "Skills Overview",
          xaxis = list(title = ""),
          yaxis = list(title = ""),
          margin = list(b = 100),
          showlegend = FALSE
        )
      
      return(p)
    })
    
    # Experience visualization
    output$experience_chart <- renderPlotly({
      req(values$structured_data$experience)
      
      if (nrow(values$structured_data$experience) == 0) {
        return(plotly_empty() %>% layout(title = "No experience data available"))
      }
      
      # Clean and prepare experience data
      experience_df <- values$structured_data$experience
      experience_df$duration <- ifelse(is.na(experience_df$duration), "Not specified", experience_df$duration)
      experience_df$description <- ifelse(is.na(experience_df$description), "No description available", experience_df$description)
      
      # Create a horizontal bar chart
      p <- plot_ly(
        experience_df,
        y = ~reorder(paste(title, " - ", company), seq_along(title)),
        x = ~rep(1, nrow(experience_df)),
        type = "bar",
        orientation = "h",
        marker = list(color = "#2ecc71"),
        text = ~paste("Duration:", duration, "<br>Description:", description),
        hoverinfo = "text"
      ) %>%
        layout(
          title = "Work Experience",
          xaxis = list(
            showgrid = FALSE,
            zeroline = FALSE,
            showticklabels = FALSE,
            range = c(0, 1)
          ),
          yaxis = list(title = ""),
          margin = list(l = 150),
          showlegend = FALSE
        )
      
      return(p)
    })
    
    # Experience table
    output$experience_table <- renderDT({
      req(values$structured_data$experience)
      
      if (length(values$structured_data$experience) == 0) {
        return(datatable(data.frame(Message = "No experience data available")))
      }
      
      experience_df <- do.call(rbind, lapply(values$structured_data$experience, function(exp) {
        data.frame(
          Title = exp$title,
          Company = exp$company,
          Duration = exp$duration,
          Description = exp$description,
          stringsAsFactors = FALSE
        )
      }))
      
      datatable(
        experience_df,
        options = list(
          pageLength = 5,
          autoWidth = TRUE,
          scrollX = TRUE,
          dom = 'tip'
        ),
        rownames = FALSE,
        class = "compact stripe"
      )
    })
    
    # Education visualization
    output$education_chart <- renderPlotly({
      req(values$structured_data$education)
      
      if (nrow(values$structured_data$education) == 0) {
        return(plotly_empty() %>% layout(title = "No education data available"))
      }
      
      # Clean and prepare education data
      education_df <- values$structured_data$education
      education_df$year <- ifelse(is.na(education_df$year), "Not specified", education_df$year)
      
      # Create a horizontal bar chart
      p <- plot_ly(
        education_df,
        y = ~reorder(paste(degree, " - ", institution), seq_along(degree)),
        x = ~rep(1, nrow(education_df)),
        type = "bar",
        orientation = "h",
        marker = list(color = "#9b59b6"),
        text = ~paste("Year:", year),
        hoverinfo = "text"
      ) %>%
        layout(
          title = "Education Timeline",
          xaxis = list(
            showgrid = FALSE,
            zeroline = FALSE,
            showticklabels = FALSE,
            range = c(0, 1)
          ),
          yaxis = list(title = ""),
          margin = list(l = 150),
          showlegend = FALSE
        )
      
      return(p)
    })
    
    # Projects visualization
    output$projects_chart <- renderPlotly({
      req(values$structured_data$projects)
      
      if (nrow(values$structured_data$projects) == 0) {
        return(plotly_empty() %>% layout(title = "No projects data available"))
      }
      
      # Clean and prepare projects data
      projects_df <- values$structured_data$projects
      projects_df$description <- ifelse(is.na(projects_df$description), "No description available", projects_df$description)
      
      # Create a horizontal bar chart
      p <- plot_ly(
        projects_df,
        y = ~reorder(name, seq_along(name)),
        x = ~rep(1, nrow(projects_df)),
        type = "bar",
        orientation = "h",
        marker = list(color = "#e74c3c"),
        text = ~description,
        hoverinfo = "text"
      ) %>%
        layout(
          title = "Projects Overview",
          xaxis = list(
            showgrid = FALSE,
            zeroline = FALSE,
            showticklabels = FALSE,
            range = c(0, 1)
          ),
          yaxis = list(title = ""),
          margin = list(l = 150),
          showlegend = FALSE
        )
      
      return(p)
    })
    
    # Projects table
    output$projects_table <- renderDT({
      req(values$structured_data$projects)
      
      if (length(values$structured_data$projects) == 0) {
        return(datatable(data.frame(Message = "No projects data available")))
      }
      
      projects_df <- do.call(rbind, lapply(values$structured_data$projects, function(proj) {
        data.frame(
          Name = proj$name,
          Description = proj$description,
          stringsAsFactors = FALSE
        )
      }))
      
      datatable(
        projects_df,
        options = list(
          pageLength = 5,
          autoWidth = TRUE,
          scrollX = TRUE,
          dom = 'tip'
        ),
        rownames = FALSE,
        class = "compact stripe"
      )
    })
    
    # Achievements visualization
    output$achievements_chart <- renderPlotly({
      req(values$structured_data$achievements)
      
      if (length(values$structured_data$achievements) == 0) {
        return(plotly_empty() %>% layout(title = "No achievements data available"))
      }
      
      achievement_count <- length(values$structured_data$achievements)
      set.seed(123)
      
      achievements_df <- data.frame(
        id = 1:achievement_count,
        achievement = values$structured_data$achievements,
        x = runif(achievement_count, 0, 100),
        y = runif(achievement_count, 0, 100),
        size = sample(10:20, achievement_count, replace = TRUE)
      )
      
      p <- plot_ly(
        achievements_df,
        x = ~x,
        y = ~y,
        type = "scatter",
        mode = "markers+text",
        text = ~achievement,
        textposition = "middle center",
        marker = list(
          size = ~size,
          color = sample(
            c("#3498db", "#2ecc71", "#9b59b6", "#e74c3c", "#f39c12"),
            achievement_count,
            replace = TRUE
          ),
          opacity = 0.7
        ),
        hoverinfo = "text"
      ) %>%
        layout(
          title = "Achievements Highlight",
          xaxis = list(
            showgrid = FALSE,
            zeroline = FALSE,
            showticklabels = FALSE
          ),
          yaxis = list(
            showgrid = FALSE,
            zeroline = FALSE,
            showticklabels = FALSE
          )
        )
      
      return(p)
    })
    
    # Achievements list
    output$achievements_list <- renderUI({
      req(values$structured_data$achievements)
      
      if (length(values$structured_data$achievements) == 0) {
        return(div(class = "callout callout-warning", "No achievements data available"))
      }
      
      achievements_list <- lapply(values$structured_data$achievements, function(achievement) {
        div(
          class = "callout callout-info",
          style = "margin-bottom: 10px;",
          p(achievement)
        )
      })
      
      do.call(tagList, achievements_list)
    })
  }
  
  # Add new reactive value for database contents
  values$database_contents <- NULL
  
  # Function to load database contents
  load_database <- function() {
    safe_call({
      if (file.exists(values$database_file)) {
        tryCatch({
          values$database_contents <- readxl::read_excel(values$database_file)
        }, error = function(e) {
          print(paste("Error loading database:", e$message))
          values$database_contents <- NULL
          values$error_message <- "Error loading database file"
        })
      } else {
        values$database_contents <- NULL
      }
    }, "Error loading database")
  }
  
  # Load database contents when the app starts
  observe({
    safe_call({
      load_database()
    }, "Error initializing database")
  })
  
  # Update database table output
  output$database_table <- renderDT({
    safe_call({
      req(values$database_contents)
      
      if (is.null(values$database_contents) || nrow(values$database_contents) == 0) {
        return(datatable(data.frame(Message = "No data available in database")))
      }
      
      datatable(
        values$database_contents,
        options = list(
          pageLength = 10,
          scrollX = TRUE,
          dom = 'Bfrtip',
          buttons = c('copy', 'csv', 'excel'),
          initComplete = JS("
            function(settings, json) {
              $(this.api().table().container()).addClass('table-striped');
              $(this.api().table().container()).addClass('table-bordered');
              $(this.api().table().container()).addClass('table-hover');
              $(this.api().table().container()).css('width', '100%');
              $(this.api().table().container()).css('margin-bottom', '3em');
            }
          ")
        ),
        rownames = FALSE,
        class = "table table-striped table-bordered table-hover"
      )
    }, "Error displaying database table")
  })
  
  # Update the export functionality to refresh the table
  observeEvent(input$export_btn, {
    safe_call({
      req(values$structured_data)
      
      if (is.null(values$structured_data)) {
        values$error_message <- "No structured data available to export"
        return()
      }
      
      waiter <- Waiter$new(
        html = tagList(
          spin_circle(),
          h4("Preparing Excel file...", style = "color: white;")
        ),
        color = "rgba(0, 0, 0, 0.7)"
      )
      waiter$show()
      
      tryCatch({
        # Extract user name from resume text
        name_match <- regexpr("^[A-Za-z\\s]+", values$resume_text)
        if (name_match > 0) {
          values$current_user_name <- regmatches(values$resume_text, name_match)
        } else {
          values$current_user_name <- "Unknown User"
        }
        
        # Prepare data for the current user
        current_user_data <- data.frame(
          Name = values$current_user_name,
          Skills = paste(values$structured_data$skills, collapse = "; "),
          Education = paste(apply(values$structured_data$education, 1, function(x) {
            paste(x, collapse = " | ")
          }), collapse = "\n"),
          Experience = paste(apply(values$structured_data$experience, 1, function(x) {
            paste(x, collapse = " | ")
          }), collapse = "\n"),
          Projects = paste(apply(values$structured_data$projects, 1, function(x) {
            paste(x, collapse = " | ")
          }), collapse = "\n"),
          Achievements = paste(values$structured_data$achievements, collapse = "; "),
          Recommendations = if (!is.null(values$recommendations)) {
            paste(sapply(values$recommendations, function(x) {
              paste(x$title, x$description, sep = ": ")
            }), collapse = "\n")
          } else {
            "No recommendations available"
          },
          Timestamp = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
          stringsAsFactors = FALSE
        )
        
        # Check if database file exists
        if (file.exists(values$database_file)) {
          existing_data <- readxl::read_excel(values$database_file)
          
          if (values$current_user_name %in% existing_data$Name) {
            existing_data[existing_data$Name == values$current_user_name, ] <- current_user_data
          } else {
            existing_data <- rbind(existing_data, current_user_data)
          }
        } else {
          existing_data <- current_user_data
        }
        
        # Write updated database to Excel
        writexl::write_xlsx(existing_data, values$database_file)
        
        values$export_file <- values$database_file
        values$export_status <- "success"
        load_database()
        
        waiter$hide()
        showNotification("Resume data added to database successfully", type = "message")
        
        output$export_status <- renderUI({
          div(
            class = "callout callout-success",
            h4("Export Successful"),
            p("Your resume data has been added to the database."),
            downloadButton(
              "download_excel",
              "Download Complete Database",
              icon = icon("download"),
              class = "btn-primary"
            )
          )
        })
        
      }, error = function(e) {
        waiter$hide()
        values$export_status <- "error"
        values$error_message <- paste("Error updating database:", e$message)
        
        output$export_status <- renderUI({
          div(
            class = "callout callout-danger",
            h4("Export Failed"),
            p(paste("Error updating database:", e$message))
          )
        })
      })
    }, "Error during export process")
  })
  
  # Update download handler
  output$download_excel <- downloadHandler(
    filename = function() {
      safe_call({
        paste("resume_database_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".xlsx", sep = "")
      }, "Error generating filename")
    },
    content = function(file) {
      safe_call({
        if (!file.exists(values$database_file)) {
          values$error_message <- "Database file not found"
          return()
        }
        file.copy(values$database_file, file)
      }, "Error downloading database file")
    }
  )
  
  # Redirect to input tab when the app starts
  updateTabItems(session, "sidebarMenu", "input")
}

# Run the application
shinyApp(ui = ui, server = server)