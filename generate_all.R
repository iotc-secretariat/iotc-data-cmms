# Libraries
pacman::p_load(
"rmarkdown", 
"knitr", 
"bookdown", 
"officer", 
"officedown", 
"DT")

# English Version ####

## html ####
render("rmd/00_DOCX_HTML.Rmd", 
       output_format = "html_document2",
       output_dir    = "outputs/html/", 
       output_file   = paste0("index.html")
)

## docx ####
render("rmd/00_DOCX_HTML.Rmd", 
               output_dir    = "outputs/docx", 
               output_file   = paste0("IOTC_Fisheries_Data_Framework_", Sys.Date(), ".docx")
       )

### FRENCH ####
# render("rmd/00_DOCX_HTML_FR.Rmd", 
#        output_format = "html_document2",
#        output_dir    = "outputs/html/", 
#        output_file   = paste0("index_fr.html")
# )

# Upload files on the server
source("./initialisation/99_UPLOAD.R")

# ## DOCX ####
# OUTPUT_TABLE_FORMAT = "FT"
# 
# ### FRENCH ####
# render("rmd/00_DOCX_HTML.Rmd", 
#        output_dir    = "outputs/docx", 
#        output_file   = paste0("IOTC_Data_Reporting_Guidelines_", Sys.Date(), ".docx")
# )
# 
# ### ENGLISH ####
# render("rmd/00_DOCX_HTML_FR.Rmd", 
#        output_dir    = "outputs/docx", 
#        output_file   = paste0("IOTC_Directions_Déclarations_Données_", Sys.Date(), ".docx")
# )
