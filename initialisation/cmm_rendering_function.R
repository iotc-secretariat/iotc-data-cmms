# Render IOTC data-related CMM descriptors from a semicolon-delimited CSV.
# The function returns Markdown through knitr::asis_output(), so headings,
# anchors, links and paragraphs are interpreted by Pandoc during knitting.

render_cmm_layout <- function(csv_file,
                              language = c("en", "fr"),
                              category_level = 2L,
                              cmm_level = 3L) {
  language <- match.arg(language)

  cmm <- data.table::fread(
    csv_file,
    sep = ";",
    quote = '"',
    encoding = "UTF-8",
    na.strings = c("", "NA"),
    strip.white = TRUE,
    check.names = FALSE
  )

  # Be tolerant of headers exported with escaped underscores.
  data.table::setnames(cmm, gsub("\\\\_", "_", names(cmm)))

  required <- c(
    "category", "resolution_number",
    paste0("resolution_title_", language),
    "resolution_url_en", "resolution_url_fr",
    "doi", "date_entry_into_force",
    "supersedes_resolution",
    paste0("superseded_resolution_url_", language),
    paste0("summary_", language), "not_applied_to"
  )

  missing_columns <- setdiff(required, names(cmm))
  if (length(missing_columns)) {
    stop(
      "Missing required column(s): ",
      paste(missing_columns, collapse = ", "),
      call. = FALSE
    )
  }

  # Preserve the order used in the CSV rather than sorting categories or CMMs.
  cmm[, row_id__ := .I]
  category_order <- unique(cmm$category)

  title_col <- paste0("resolution_title_", language)
  url_col <- paste0("resolution_url_", language)
  superseded_url_col <- paste0("superseded_resolution_url_", language)
  summary_col <- paste0("summary_", language)

  labels <- if (language == "en") {
    list(
      official = "Official text",
      english = "English",
      french = "French",
      doi = "DOI",
      force = "Entry into force",
      supersedes = "Supersedes",
      superseded_by = "Superseded by",
      not_applied = "Does not apply to"
    )
  } else {
    list(
      official = "Texte officiel",
      english = "anglais",
      french = "français",
      doi = "DOI",
      force = "Entrée en vigueur",
      supersedes = "Remplace",
      superseded_by = "Remplacée par",
      not_applied = "Ne s’applique pas à"
    )
  }

  is_present <- function(x) {
    length(x) == 1L && !is.na(x) && nzchar(trimws(as.character(x)))
  }

  split_values <- function(x) {
    if (!is_present(x)) return(character())
    y <- trimws(unlist(strsplit(as.character(x), "\\r?\\n")))
    y[nzchar(y)]
  }

  anchor_id <- function(x) {
    tolower(gsub("[^[:alnum:]]+", "", iconv(x, to = "ASCII//TRANSLIT")))
  }

  markdown_link <- function(label, url) {
    if (!is_present(url)) return(label)
    sprintf("[%s](%s)", label, trimws(url))
  }

  autolink <- function(url) {
    if (!is_present(url)) return(NA_character_)
    sprintf("<%s>", trimws(url))
  }

  paired_links <- function(numbers, urls) {
    numbers <- split_values(numbers)
    urls <- split_values(urls)
    if (!length(numbers)) return(character())
    vapply(seq_along(numbers), function(i) {
      url <- if (i <= length(urls)) urls[[i]] else NA_character_
      markdown_link(numbers[[i]], url)
    }, character(1))
  }

  # Identify an active CMM that supersedes another CMM also present in the CSV.
  reverse_supersession <- lapply(cmm$resolution_number, function(number) {
    which(vapply(cmm$supersedes_resolution, function(x) {
      number %in% split_values(x)
    }, logical(1)))
  })
  names(reverse_supersession) <- cmm$resolution_number

  output <- character()
  add <- function(...) output <<- c(output, ...)

  for (category in category_order) {
    add(
      paste0(strrep("#", category_level), " ", category),
      ""
    )

    rows <- cmm[category == ..category][order(row_id__)]

    for (i in seq_len(nrow(rows))) {
      row <- rows[i]
      number <- row$resolution_number[[1]]
      title <- trimws(row[[title_col]][[1]])
      id <- anchor_id(number)

      add(
        sprintf(
          "%s %s -- %s {#%s}",
          strrep("#", cmm_level), number, title, id
        ),
        ""
      )

      # Official texts: both language links are retained in either output language.
      official_links <- c(
        markdown_link(
          sprintf("%s (%s)", number, labels$english),
          row$resolution_url_en[[1]]
        ),
        markdown_link(
          sprintf("%s (%s)", number, labels$french),
          row$resolution_url_fr[[1]]
        )
      )
      official_links <- official_links[nzchar(official_links)]
      add(sprintf("- %s: %s", labels$official, paste(official_links, collapse = " | ")))

      doi <- autolink(row$doi[[1]])
      if (!is.na(doi)) add(sprintf("- %s: %s", labels$doi, doi))

      if (is_present(row$date_entry_into_force[[1]])) {
        add(sprintf("- %s: %s", labels$force, row$date_entry_into_force[[1]]))
      }

      supersedes <- paired_links(
        row$supersedes_resolution[[1]],
        row[[superseded_url_col]][[1]]
      )
      if (length(supersedes)) {
        add(sprintf("- %s: %s", labels$supersedes, paste(supersedes, collapse = " | ")))
      }

      superseding_rows <- reverse_supersession[[number]]
      if (length(superseding_rows)) {
        superseded_by <- vapply(superseding_rows, function(j) {
          other_number <- cmm$resolution_number[[j]]
          other_url <- cmm[[url_col]][[j]]
          markdown_link(other_number, paste0("#", anchor_id(other_number)))
        }, character(1))
        add(sprintf(
          "- %s: %s",
          labels$superseded_by,
          paste(superseded_by, collapse = " | ")
        ))
      }

      not_applied <- split_values(row$not_applied_to[[1]])
      if (length(not_applied)) {
        # Also supports comma-separated CPCs in the current source file.
        not_applied <- trimws(unlist(strsplit(not_applied, ",")))
        not_applied <- not_applied[nzchar(not_applied)]
        add(sprintf(
          "- %s: %s",
          labels$not_applied,
          paste(not_applied, collapse = ", ")
        ))
      }

      # Optional preformatted Markdown columns. If added later to the CSV, each
      # value is emitted as a normal metadata bullet without changing the function.
      optional_fields <- if (language == "en") {
        c(guidelines = "Guidelines", reporting_forms = "Reporting forms")
      } else {
        c(guidelines = "Directives", reporting_forms = "Formulaires de déclaration")
      }
      for (field in names(optional_fields)) {
        if (field %in% names(row) && is_present(row[[field]][[1]])) {
          add(sprintf("- %s: %s", optional_fields[[field]], row[[field]][[1]]))
        }
      }

      add("")

      summary <- row[[summary_col]][[1]]
      if (is_present(summary)) {
        # Blank lines embedded in the CSV remain paragraph breaks in Markdown.
        summary_paragraphs <- trimws(unlist(strsplit(summary, "\\r?\\n+")))
        summary_paragraphs <- summary_paragraphs[nzchar(summary_paragraphs)]
        add(summary_paragraphs, "")
      }
    }
  }

  knitr::asis_output(paste(output, collapse = "\n"))
}
