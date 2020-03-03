#' Create a raster annotation from raster input
#'
#' Input is a single layer or a 3-or-4 layer raster. With single
#' the function works like [image()] mapping values to colours, with 3 (or 4)
#' these are intepreted directly as RGB by scaling into `[0,1]`.
#'
#' The `alpha` defines a constant value, but can be set in the input
#' raster of 4-layers or as a vector for every cell of the data.
#' @param x a BasicRaster
#' @param col optional colours for image-like mapping
#' @param ... ignored
#' @param breaks optional manual breaks for mapping to `col`
#' @param alpha defaults to 1, set from 0-1 for constant transparancy
#' @param rgb defaults to `TRUE`, set to `FALSE` to allow manual colour mapping on first layer only
#' @param dim optional dimensions for lazyraster input case
#'
#' @return ggplot2 annotation object
#' @export
#'
#' @examples
#' library(raster)
#' library(ggplot2)
#' ggplot() + plus_raster(raster(volcano))  ## only works because we in [0,1,0,1]
#'
#' ## general case we need xlim/ylim
#' r <- raster(volcano, xmn = 0, xmx = 10, ymn = -2, ymx = 50)
#' ggplot() + plus_raster(r, col = rainbow(10), breaks = seq(90, 190, by = 10))  +
#'   xlim(0, 10) + ylim(0, 50) + coord_equal()
plus_raster <- function(x, col, ..., breaks = NULL, alpha = 1, rgb = TRUE, dim = c(256, 256)) {
  if (inherits(x, "lazyraster")) {
    x <- lazyraster::as_raster(x, dim = dim)
  }
  # don't want RGB interp so drop layers, also drop if 2, 5, 6, .. layers because
  # that's not RGB or RGBA
  if (!rgb || raster::nlayers(x) == 2 || raster::nlayers(x) > 4) {
    x <- x[[1]]
  }
  ## raster has only one layer so do colour mapping
  if (raster::nlayers(x) == 1) {
    x <- palr::image_raster(x, col = col, breaks = breaks)
  }
  ## by now we must have 3 or 4 layers
  m <- scales::rescale(raster::as.array(x))
  ## but if 3, then add alpha
  if (raster::nlayers(x) == 3) {
    m <- array(c(m, rep_len(alpha, prod(dim(m)[1:2]))), c(dim(m)[1:2], 4))
  }
  ggplot2::annotation_raster(m,
                             raster::xmin(x), raster::xmax(x),
                             raster::ymin(x), raster::ymax(x))
}
