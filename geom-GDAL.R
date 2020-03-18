create_tiles <- function(path, ...) {
  ri <- purrr::map(path, ~vapour::vapour_raster_info(.x))

  nx <- purrr::map_int(ri, ~.x$dimXY[1L])
  ny <- purrr::map_int(ri, ~.x$dimXY[2L])

  tibble::tibble(path = path,
                 xmin = purrr::map_dbl(ri, ~.x$geotransform[1]),
                 xmax = purrr::map_dbl(ri, ~.x$geotransform[1] + nx *
                                         purrr::map_dbl(ri, ~.x$geotransform[2])),
                 ymax = purrr::map_dbl(ri, ~.x$geotransform[4]),
                 ymin = ymax + nx * purrr::map_dbl(ri, ~.x$geotransform[6])
                 )[c("path", "xmin", "xmax", "ymin", "ymax")]

}

r <- tabularaster::ghrsst
#raster::writeRaster(r, "file.tif")
system("gdal_translate file.tif file.png -of PNG")
library(dplyr)
library(ggplot2)
library(ggimg)
create_tiles("file.png") %>%
  ggplot() + geom_rect(aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax))

StatGDAL <- ggproto("StatGDAL", Stat,
                      setup_params = function(data, params) {
                        if (is.null(params$xmin)) params$xmin <- 0
                        if (is.null(params$xmax)) params$xmax <- 1
                        if (is.null(params$ymin)) params$ymin <- 0
                        if (is.null(params$ymax)) params$ymax <- 1
                        if (is.null(params$img)) params$img <- "file.png"
                        params
                      },
                      setup_data = function(data, params) {
                        if (anyDuplicated(data$group)) {
                          data$group <- paste(data$group, seq_len(nrow(data)), sep = "-")
                        }
                        data
                      },
                      compute_panel = function(data, scales) {
                        cols_to_keep <- setdiff(names(data), c("path"))
                        cbind(create_tiles(data$path), data[, cols_to_keep, drop = FALSE])

                      },
                      required_aes = c("path")
)


GeomGDAL <- ggplot2::ggproto(
  "GeomGDAL",
  ggplot2::Geom,
  required_aes = c("path"),
  default_aes = ggplot2::aes(),
  draw_key = ggplot2::draw_key_point,
  draw_panel = function(data, panel_params, coord, interpolate = TRUE) {
    coords <- coord$transform(data, panel_params)
    path <- coords$path
    coords$path <- NULL
    coords <- cbind(coords, create_tiles(path))
    grobs <- vector("list", length(coords$path))
    class(grobs) <- "gList"
    for (i in seq_along(grobs))
    {

      img <- scales::rescale(raster::as.matrix(as_raster(lazyraster(coords$path[i]))))
      browser()
      grobs[[i]] <- grid::rasterGrob(
        img,
        coords$xmin[i],
        coords$ymin[i],
        coords$xmax[i] - coords$xmin[i],
        coords$ymax[i] - coords$ymin[i],
        hjust = 0,
        vjust = 0,
        interpolate = interpolate
      )
    }
    return(grobs)
  }
)

geom_gdal <- function(mapping = NULL, data = NULL, stat = "identity",
                        position = "identity", ...,
                        show.legend = NA, inherit.aes = TRUE) {

  layer(
    data = data,
    mapping = mapping,
    stat = stat,
    geom = GeomGDAL,
    position = position,
    show.legend = show.legend,
    inherit.aes = inherit.aes,
    params = list(
      ...
    )
  )
}
library(lazyraster)
d <- tibble::tibble(path = "file.png")
ggplot(d) + geom_gdal(aes(path = path)) + xlim(c(0, 180)) + ylim(c(-90, 0))
