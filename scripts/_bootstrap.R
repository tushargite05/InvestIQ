# Common bootstrap: set PROJECT_ROOT then source config
local({
  args <- commandArgs(trailingOnly = FALSE)
  file_arg <- grep("^--file=", args, value = TRUE)
  root <- NULL
  if (exists("PROJECT_ROOT", envir = .GlobalEnv, inherits = FALSE)) {
    root <- get("PROJECT_ROOT", envir = .GlobalEnv)
  } else if (length(file_arg) > 0) {
    script_path <- normalizePath(sub("^--file=", "", file_arg[1]))
    root <- normalizePath(file.path(dirname(script_path), ".."))
  } else {
    wd <- normalizePath(getwd())
    if (dir.exists(file.path(wd, "scripts")) && dir.exists(file.path(wd, "data"))) {
      root <- wd
    } else if (dir.exists(file.path(dirname(wd), "scripts"))) {
      root <- normalizePath(dirname(wd))
    } else {
      root <- wd
    }
  }
  assign("PROJECT_ROOT", root, envir = .GlobalEnv)
})
source(file.path(PROJECT_ROOT, "scripts", "00_config.R"))
