# Load required packages
library(writexl)
library(tidyverse)

# Create sample data
sample_data <- data.frame(
  Name = c(
    "John Smith", "Sarah Johnson", "Michael Chen", "Emily Rodriguez", "David Kim",
    "Lisa Wang", "James Wilson", "Maria Garcia", "Robert Taylor", "Jennifer Lee",
    "Thomas Anderson", "Patricia Martinez", "William Brown", "Elizabeth Davis",
    "Richard Miller", "Michelle Wong", "Joseph White", "Amanda Thompson",
    "Christopher Lee", "Rachel Green"
  ),
  
  Skills = c(
    "Python; Data Analysis; Machine Learning; SQL; Tableau",
    "Project Management; Agile; Scrum; Risk Management; Leadership",
    "JavaScript; React; Node.js; MongoDB; AWS",
    "Digital Marketing; SEO; Content Strategy; Social Media; Analytics",
    "Java; Spring Boot; Microservices; Docker; Kubernetes",
    "UI/UX Design; Figma; Adobe XD; Prototyping; User Research",
    "Sales; Business Development; Client Relations; Negotiation; CRM",
    "HR Management; Recruitment; Employee Relations; Training; Compliance",
    "Financial Analysis; Excel; Forecasting; Budgeting; Reporting",
    "Content Writing; Copywriting; SEO; Social Media; Blogging",
    "DevOps; CI/CD; Jenkins; Git; Linux",
    "Healthcare Administration; Patient Care; Medical Records; HIPAA; Scheduling",
    "Supply Chain; Logistics; Inventory Management; SAP; Forecasting",
    "Teaching; Curriculum Development; Educational Technology; Assessment; Mentoring",
    "Architecture; AutoCAD; Revit; Building Codes; Project Planning",
    "Research; Data Collection; Statistical Analysis; SPSS; Report Writing",
    "Customer Service; Call Center; CRM; Problem Solving; Team Leadership",
    "Event Planning; Vendor Management; Budgeting; Marketing; Logistics",
    "Quality Assurance; Testing; Selenium; JIRA; Test Automation",
    "Public Relations; Media Relations; Crisis Management; Brand Strategy; Writing"
  ),
  
  Education = c(
    "MS Computer Science | Stanford University | 2020\nBS Computer Science | UC Berkeley | 2018",
    "MBA | Harvard Business School | 2019\nBS Business Administration | NYU | 2017",
    "BS Software Engineering | MIT | 2021",
    "MS Digital Marketing | Northwestern University | 2020\nBA Communications | UCLA | 2018",
    "MS Computer Engineering | Georgia Tech | 2021\nBS Computer Science | University of Texas | 2019",
    "MFA Design | Rhode Island School of Design | 2020\nBFA Graphic Design | Parsons | 2018",
    "BS Business Administration | University of Michigan | 2019",
    "MS Human Resources | Cornell University | 2021\nBA Psychology | Boston University | 2019",
    "MS Finance | University of Chicago | 2020\nBS Economics | University of Wisconsin | 2018",
    "MA Journalism | Columbia University | 2021\nBA English | University of Virginia | 2019",
    "MS Computer Science | Carnegie Mellon | 2020\nBS Computer Engineering | Purdue | 2018",
    "MHA Healthcare Administration | Johns Hopkins | 2021\nBS Health Sciences | University of Florida | 2019",
    "MS Supply Chain Management | Michigan State | 2020\nBS Operations Management | Penn State | 2018",
    "MEd Education | Teachers College Columbia | 2021\nBA History | University of Maryland | 2019",
    "MArch Architecture | Yale | 2020\nBS Architecture | University of Illinois | 2018",
    "PhD Psychology | University of California | 2021\nMS Psychology | University of Washington | 2019",
    "BS Business Management | Arizona State | 2020",
    "BS Hospitality Management | Cornell | 2019",
    "MS Software Engineering | University of Southern California | 2021\nBS Computer Science | University of Arizona | 2019",
    "MA Public Relations | Boston University | 2020\nBA Communications | Syracuse | 2018"
  ),
  
  Experience = c(
    "Data Scientist | Google | 2020-Present | Developed ML models for user behavior prediction\nData Analyst | Microsoft | 2018-2020 | Analyzed user engagement metrics",
    "Project Manager | Amazon | 2021-Present | Led cross-functional teams in product development\nProgram Manager | Microsoft | 2019-2021 | Managed software development projects",
    "Senior Developer | Facebook | 2021-Present | Built scalable web applications\nSoftware Engineer | LinkedIn | 2019-2021 | Developed frontend features",
    "Digital Marketing Manager | Nike | 2020-Present | Led social media campaigns\nMarketing Specialist | Adidas | 2018-2020 | Created content strategy",
    "Backend Developer | Netflix | 2021-Present | Developed microservices architecture\nSoftware Engineer | Spotify | 2019-2021 | Built API endpoints",
    "UI/UX Designer | Apple | 2020-Present | Designed iOS app interfaces\nDesigner | Samsung | 2018-2020 | Created mobile app designs",
    "Sales Director | Salesforce | 2021-Present | Led enterprise sales team\nAccount Executive | Oracle | 2019-2021 | Managed client relationships",
    "HR Manager | IBM | 2020-Present | Oversaw recruitment and training\nHR Specialist | Dell | 2018-2020 | Handled employee relations",
    "Financial Analyst | Goldman Sachs | 2021-Present | Analyzed market trends\nInvestment Analyst | Morgan Stanley | 2019-2021 | Managed portfolios",
    "Content Manager | BuzzFeed | 2020-Present | Created viral content\nContent Writer | Vox | 2018-2020 | Wrote articles",
    "DevOps Engineer | Amazon | 2021-Present | Managed cloud infrastructure\nSystems Engineer | Google | 2019-2021 | Automated deployments",
    "Healthcare Administrator | Mayo Clinic | 2020-Present | Managed hospital operations\nAdministrator | Cleveland Clinic | 2018-2020 | Handled patient records",
    "Supply Chain Manager | Walmart | 2021-Present | Optimized inventory management\nLogistics Manager | Target | 2019-2021 | Managed distribution",
    "High School Teacher | Public School | 2020-Present | Taught mathematics\nTeacher | Private School | 2018-2020 | Taught science",
    "Architect | Gensler | 2021-Present | Designed commercial buildings\nJunior Architect | HOK | 2019-2021 | Created building plans",
    "Research Scientist | NIH | 2020-Present | Conducted clinical trials\nResearch Assistant | CDC | 2018-2020 | Analyzed health data",
    "Customer Service Manager | Apple | 2021-Present | Led support team\nTeam Lead | Amazon | 2019-2021 | Managed customer relations",
    "Event Director | Marriott | 2020-Present | Organized corporate events\nEvent Planner | Hilton | 2018-2020 | Planned weddings",
    "QA Manager | Microsoft | 2021-Present | Led testing team\nQA Engineer | Adobe | 2019-2021 | Automated testing",
    "PR Director | Edelman | 2020-Present | Managed brand reputation\nPR Manager | Weber Shandwick | 2018-2020 | Handled media relations"
  ),
  
  Projects = c(
    "AI Image Recognition | Developed deep learning model for object detection\nData Pipeline | Built ETL pipeline for real-time data processing",
    "Agile Transformation | Led organization-wide agile adoption\nProject Management Tool | Developed custom PM software",
    "E-commerce Platform | Built full-stack online store\nMobile App | Developed cross-platform app",
    "Brand Campaign | Created viral marketing campaign\nSocial Media Strategy | Developed content calendar",
    "Cloud Migration | Led AWS migration project\nAPI Gateway | Built microservices gateway",
    "Design System | Created component library\nMobile UI Kit | Developed design system",
    "Sales Dashboard | Built analytics dashboard\nCRM Integration | Implemented Salesforce integration",
    "HR Portal | Developed employee self-service portal\nTraining Platform | Created learning management system",
    "Financial Model | Built predictive analytics model\nPortfolio Tracker | Developed investment tracking tool",
    "Content Platform | Created content management system\nNewsletter System | Built email marketing platform",
    "CI/CD Pipeline | Implemented automated deployment\nInfrastructure as Code | Developed Terraform modules",
    "Patient Portal | Built healthcare management system\nMedical Records | Developed EMR system",
    "Inventory System | Created warehouse management system\nSupply Chain Dashboard | Built analytics platform",
    "Online Course | Developed e-learning platform\nAssessment Tool | Created testing system",
    "Building Design | Created sustainable building plan\nUrban Planning | Developed city master plan",
    "Research Study | Conducted longitudinal study\nData Analysis | Developed statistical models",
    "Support System | Built customer service platform\nKnowledge Base | Created help center",
    "Conference App | Developed event management system\nRegistration System | Built ticketing platform",
    "Test Framework | Created automated testing system\nPerformance Testing | Developed load testing tool",
    "Crisis Plan | Developed emergency response plan\nMedia Campaign | Created PR strategy"
  ),
  
  Achievements = c(
    "Increased model accuracy by 25%; Reduced processing time by 40%; Published 3 research papers",
    "Led team of 50+ members; Increased project efficiency by 35%; Received PM of the Year award",
    "Developed award-winning application; Reduced load time by 60%; Patented 2 technologies",
    "Grew social media following by 200%; Increased engagement by 150%; Won industry award",
    "Optimized system performance by 45%; Reduced costs by 30%; Received innovation award",
    "Created design system used by 100+ designers; Won design award; Increased user satisfaction",
    "Exceeded sales targets by 50%; Built team of 20+ salespeople; Won top performer award",
    "Reduced turnover by 25%; Implemented new HR system; Received HR excellence award",
    "Generated $10M+ in savings; Developed new financial model; Won analyst of the year",
    "Grew blog traffic by 300%; Published 100+ articles; Won content marketing award",
    "Reduced deployment time by 70%; Automated 90% of processes; Received DevOps award",
    "Improved patient satisfaction by 40%; Reduced wait times by 50%; Won healthcare award",
    "Optimized inventory by 35%; Reduced costs by 25%; Received supply chain award",
    "Improved student performance by 30%; Developed new curriculum; Won teaching award",
    "Designed award-winning building; Reduced energy usage by 40%; Won architecture award",
    "Published 5 research papers; Secured $1M+ in grants; Won research excellence award",
    "Improved customer satisfaction by 45%; Reduced response time by 60%; Won service award",
    "Organized 50+ successful events; Increased attendance by 100%; Won event award",
    "Reduced bugs by 80%; Automated 95% of testing; Received QA excellence award",
    "Managed crisis successfully; Increased brand trust by 40%; Won PR award"
  ),
  
  Recommendations = c(
    "Advanced ML Skills: Pursue PhD in Machine Learning\nCloud Certification: Obtain AWS Solutions Architect certification\nLeadership Development: Take management training program",
    "Agile Certification: Get PMP and Scrum Master certifications\nTechnical Skills: Learn data analytics tools\nGlobal Experience: Seek international project opportunities",
    "Full Stack Development: Master additional frameworks\nCloud Architecture: Learn cloud platforms\nSecurity: Obtain security certifications",
    "Data Analytics: Learn advanced analytics tools\nContent Creation: Master video marketing\nStrategy: Develop business strategy skills",
    "System Architecture: Learn distributed systems\nSecurity: Obtain security certifications\nLeadership: Develop team management skills",
    "Interaction Design: Learn advanced prototyping\nUser Research: Master research methodologies\nBusiness: Understand product strategy",
    "Sales Strategy: Learn advanced sales techniques\nNegotiation: Take negotiation training\nAnalytics: Master sales analytics",
    "HR Analytics: Learn data-driven HR\nTalent Management: Master recruitment strategies\nCompliance: Stay updated with HR laws",
    "Financial Modeling: Learn advanced Excel\nInvestment Analysis: Master portfolio management\nRisk Management: Develop risk assessment skills",
    "Content Strategy: Learn SEO optimization\nVideo Production: Master video editing\nAnalytics: Understand content metrics",
    "Container Orchestration: Learn Kubernetes\nSecurity: Obtain security certifications\nAutomation: Master CI/CD tools",
    "Healthcare IT: Learn EMR systems\nPatient Care: Master healthcare management\nCompliance: Understand HIPAA requirements",
    "Supply Chain Analytics: Learn advanced analytics\nGlobal Logistics: Master international trade\nRisk Management: Develop risk assessment",
    "Educational Technology: Learn online teaching tools\nCurriculum Design: Master instructional design\nAssessment: Develop evaluation skills",
    "Sustainable Design: Learn green building\nUrban Planning: Master city planning\nProject Management: Develop PM skills",
    "Research Methods: Learn advanced statistics\nGrant Writing: Master proposal writing\nPublication: Develop writing skills",
    "Customer Experience: Learn CX design\nService Design: Master service blueprinting\nAnalytics: Understand customer metrics",
    "Event Technology: Learn event software\nBudget Management: Master financial planning\nMarketing: Develop promotion skills",
    "Test Automation: Learn advanced frameworks\nPerformance Testing: Master load testing\nSecurity Testing: Develop security testing",
    "Crisis Management: Learn crisis communication\nMedia Relations: Master press relations\nStrategy: Develop communication plans"
  ),
  
  Timestamp = format(Sys.time(), "%Y-%m-%d %H:%M:%S")
)

# Write to Excel file
write_xlsx(sample_data, "resume_database.xlsx")

# Print confirmation
print("Sample resume database created successfully!") 