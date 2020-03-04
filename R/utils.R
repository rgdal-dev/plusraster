.numeric_extent <- function(x, ...) {
  ex <- x@extent
  unlist(attributes(ex)[c("xmin", "xmax", "ymin", "ymax")])
}

.xlim <- function(x, ...) {
  if (is.numeric(x)) {
    return(x[1L:2L])
  }
  .numeric_extent(x)[1L:2L]
}

.ylim <- function(x, ...) {
  if (is.numeric(x)) {
      return(x[3L:4L])
  }
  .numeric_extent(x)[3L:4L]
}



