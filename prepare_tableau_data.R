# Load required packages
library(tidyverse)
library(writexl)

# Read the resume database
resume_data <- readxl::read_excel("resume_database.xlsx")

# Create separate data frames for different aspects

# 1. Skills Analysis
skills_data <- resume_data %>%
  select(Name, Skills) %>%
  separate_rows(Skills, sep = ";") %>%
  mutate(Skills = trimws(Skills))

# 2. Education Analysis
education_data <- resume_data %>%
  select(Name, Education) %>%
  separate_rows(Education, sep = "\n") %>%
  separate(Education, into = c("Degree", "Institution", "Year"), sep = "\\|") %>%
  mutate(across(everything(), trimws))

# 3. Experience Analysis
experience_data <- resume_data %>%
  select(Name, Experience) %>%
  separate_rows(Experience, sep = "\n") %>%
  separate(Experience, into = c("Title", "Company", "Duration", "Description"), sep = "\\|") %>%
  mutate(across(everything(), trimws))

# 4. Projects Analysis
projects_data <- resume_data %>%
  select(Name, Projects) %>%
  separate_rows(Projects, sep = "\n") %>%
  separate(Projects, into = c("Project_Name", "Project_Description"), sep = "\\|") %>%
  mutate(across(everything(), trimws))

# 5. Achievements Analysis
achievements_data <- resume_data %>%
  select(Name, Achievements) %>%
  separate_rows(Achievements, sep = ";") %>%
  mutate(Achievements = trimws(Achievements))

# 6. Recommendations Analysis
recommendations_data <- resume_data %>%
  select(Name, Recommendations) %>%
  separate_rows(Recommendations, sep = "\n") %>%
  separate(Recommendations, into = c("Category", "Description"), sep = ":") %>%
  mutate(across(everything(), trimws))

# Write each dataset to separate Excel files for Tableau
write_xlsx(skills_data, "tableau_data/skills.xlsx")
write_xlsx(education_data, "tableau_data/education.xlsx")
write_xlsx(experience_data, "tableau_data/experience.xlsx")
write_xlsx(projects_data, "tableau_data/projects.xlsx")
write_xlsx(achievements_data, "tableau_data/achievements.xlsx")
write_xlsx(recommendations_data, "tableau_data/recommendations.xlsx")

# Create a summary dataset
summary_data <- resume_data %>%
  mutate(
    Skill_Count = str_count(Skills, ";") + 1,
    Experience_Count = str_count(Experience, "\n") + 1,
    Project_Count = str_count(Projects, "\n") + 1,
    Achievement_Count = str_count(Achievements, ";") + 1
  )

write_xlsx(summary_data, "tableau_data/summary.xlsx")

print("Data prepared successfully for Tableau analysis!") 