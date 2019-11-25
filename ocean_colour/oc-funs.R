#' Read Level-3 ocean colour.
#'
#' Read the compound types (a.k.a. "tables") from ocean colour L3 NetCDF files.
#'
#' `read_binlist` for just the 'BinList'
#' `read_compound` for just the compound data
#' `read_L3_file` for everything at once
#' @param file
#'
#' @return
#' @export
#' @name read_L3_file
#' @examples
read_binlist <- function(file) {
  tibble::as_tibble(rhdf5::h5read(file, name = file.path("/level-3_binned_data", "BinList")))
}
#' @export
#' @name read_L3_file
read_compound <- function(file, compound_vars = NULL) {
  info <- rhdf5::h5ls(file)
  tab <- table(info$dim); wm <- which.max(tab); test <- names(tab[wm])
  ## get all vars, or just the ones the users wants
  if (is.null(compound_vars))  {
    compound <- setdiff(info$name[info$dim == test], "BinList")
  } else {
    compound <- compound_vars
  }
  compoundpath <- file.path("/level-3_binned_data", compound)
  l <- lapply(compoundpath, function(aname) tibble::as_tibble(rhdf5::h5read(file, name = aname)))
  dplyr::bind_cols(lapply(seq_along(compound), function(i) setNames(l[[i]], sprintf("%s_%s", compound[i], names(l[[i]])))))
}

