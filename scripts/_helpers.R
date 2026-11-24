# Shared path bootstrap when scripts are sourced or run via Rscript

investiq_root <- function() {
  if (exists("PROJECT_ROOT", envir = .GlobalEnv, inherits = FALSE)) {
    return(get("PROJECT_ROOT", envir = .GlobalEnv))
  }
  # Rscript --file=
  args <- commandArgs(trailingOnly = FALSE)
  file_arg <- grep("^--file=", args, value = TRUE)
  if (length(file_arg) > 0) {
    script_path <- normalizePath(sub("^--file=", "", file_arg[1]))
    return(normalizePath(file.path(dirname(script_path), "..")))
  }
  # sourced: try to find InvestIQ by walking up from getwd()
  wd <- normalizePath(getwd())
  if (basename(wd) == "InvestIQ") return(wd)
  if (basename(dirname(wd)) == "InvestIQ") return(dirname(wd))
  if (dir.exists(file.path(wd, "scripts")) && dir.exists(file.path(wd, "data"))) return(wd)
  normalizePath("..")
}
