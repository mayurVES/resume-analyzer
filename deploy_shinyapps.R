# Load required packages
library(rsconnect)

# Configure deployment settings
appName <- "resume-analyzer-app"  # Valid name with hyphens
appTitle <- "Resume Analyzer"
appDir <- "app"  # Directory containing your app.R file

# Configure Shinyapps.io account
rsconnect::setAccountInfo(
  name = "your-account-name",  # Replace with your Shinyapps.io account name
  token = "your-token",        # Replace with your Shinyapps.io token
  secret = "your-secret"       # Replace with your Shinyapps.io secret
)

# Deploy the application
rsconnect::deployApp(
  appDir = appDir,
  appName = appName,
  appTitle = appTitle,
  server = "shinyapps.io",     # Specify Shinyapps.io server
  account = "your-account-name",  # Replace with your Shinyapps.io account name
  forceUpdate = TRUE,          # Force update if app exists
  launch.browser = TRUE        # Open browser after deployment
) 