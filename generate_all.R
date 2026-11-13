# Libraries
pacman::p_load(
  "rmarkdown", 
  "knitr", 
  "bookdown", 
  "officer", 
  "officedown", 
  "DT", 
  "RCurl")

# Functions ####

# Display official texts
resolution_text <- function(ResolutionNumber = "15/01"){
  return(paste0("[", ResolutionNumber, " (English)](./pdf/eng/IOTC_Resolution_", gsub("/", "-", ResolutionNumber), ".pdf) | [", ResolutionNumber, " (French)](./pdf/fra/CTOI_Resolution_", gsub("/", "-", ResolutionNumber), ".pdf)"))
            }

## Define target url ####
ftp_url <- function(path = NA) {
  return(
    paste0(
      "sftp://",
      paste0(Sys.getenv("DATA_IOTC_USERNAME"), ":", Sys.getenv("DATA_IOTC_PASSWORD")),
      "@", Sys.getenv("DATA_IOTC_SERVER_IP"),
      ifelse(is.na(path), "", paste0("/", path))
    )
  )
}
# English Version ####

## html ####
render("rmd/00_DOCX_HTML.Rmd", 
       output_format = "html_document2",
       output_dir    = "outputs/",      #"outputs/html/", 
       output_file   = paste0("index.html")
)

# Upload html file on the server
ftpUpload(
  what = "./outputs/index.html", 
  to = ftp_url("reference/cmms/index.html"), 
  asText = FALSE,
  .opts = list(ftp.create.missing.dirs = TRUE) 
)

## docx ####
render("rmd/00_DOCX_HTML.Rmd", 
       output_dir    = "outputs/docx", 
       output_file   = "IOTC_Fisheries_Data_Framework.docx"
       )

# Upload docx file on the server
ftpUpload(
  what = "./outputs/docx/IOTC_Fisheries_Data_Framework.docx", 
  to = ftp_url("reference/cmms/docx/IOTC_Fisheries_Data_Framework.docx"), 
  asText = FALSE,
  .opts = list(ftp.create.missing.dirs = TRUE) 
)

### FRENCH ####
# render("rmd/00_DOCX_HTML_FR.Rmd", 
#        output_format = "html_document2",
#        output_dir    = "outputs/html/", 
#        output_file   = paste0("index_fr.html")
# )
