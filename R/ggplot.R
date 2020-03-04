#' ggplot for raster, fast and easy
#'
#' A [ggplot()] method for raster objects, it plots them as-is, like [image()]
#' for a single layer, and like [raster::plotRGB()] for three or four layers (assuming type byte
#' effectively. Data is automatically scaled from what it is to '[0,1]' internally.
#'
#' @param data BasicRaster (raster, stack, or brick)
#' @param mapping don't use this, use aes() down stream for adding layers
#' @param ... pass arguments to [plus_raster()]
#' @param environment don't use this either
#'
#' @return a [ggplot()] object
#' @export
#'
#' @examples
#' library(ggplot2)
#' sfx <- sf::st_as_sf(data.frame(x = rnorm(100), y = rnorm(100)), coords = c("x", "y"))
#' gp <- geom_point(data = data.frame(x = runif(5), y = runif(5)), aes(x, y), col = "hotpink", pch = "+", cex = 20)
#' ggplot(raster::raster(volcano)) +  gp + geom_sf(data = sfx)
#' pts <- c(147.3, 147.35, -42.89, -42.87)
#' cc <- ceramic::cc_location(raster::extent(pts), zoom = 15)
#' sfx <- sf::st_transform(sf::st_sfc(sf::st_multipoint(matrix(pts, ncol = 2)), crs = 4326), raster::projection(cc))
#' ggplot(cc) + coord_equal() + geom_sf(data = sfx)  ## it's WROKING
ggplot.BasicRaster <- function (data = NULL, mapping = aes(), ..., environment = parent.frame()) {
  if (!missing(mapping) && !inherits(mapping, "uneval")) {
    abort("Mapping should be created with `aes()` or `aes_()`.")
  }
  ex <- .numeric_extent(data)
  dummy <- expand.grid(x = ex[1:2], y = ex[3:4])
  p <- structure(list(
    data = data,
    layers = list(),
    scales = ggplot2:::scales_list(),
    mapping = mapping,
    theme = list(),
    coordinates = ggplot2::coord_cartesian(default = TRUE),
    facet = facet_null(),
    plot_env = environment
  ), class = c("gg", "ggplot"))
  p$labels <- ggplot2:::make_labels(mapping)
  ggplot2::set_last_plot(p)
  p + ggplot2::geom_point(data = dummy, aes(x, y), pch = "") + plus_raster(data)
}



