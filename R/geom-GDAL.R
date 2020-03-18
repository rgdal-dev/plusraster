create_tiles <- function(path, ...) {
  ri <- purrr::map(path, ~vapour::vapour_raster_info(.x))

  nx <- purrr::map_int(ri, ~.x$dimXY[1L])
  ny <- purrr::map_int(ri, ~.x$dimXY[2L])

  tibble::tibble(path = path,
                 xmin = purrr::map_dbl(ri, ~.x$geotransform[1]),
                 xmax = purrr::map_dbl(ri, ~.x$geotransform[1]) + nx *
                                         purrr::map_dbl(ri, ~.x$geotransform[2]),
                 ymax = purrr::map_dbl(ri, ~.x$geotransform[4]),
                 ymin = ymax + ny * purrr::map_dbl(ri, ~.x$geotransform[6])
                 )[c("path", "xmin", "xmax", "ymin", "ymax")]

}




# StatGDAL <- ggproto("StatGDAL", Stat,
#                       setup_params = function(data, params) {
#                         if (is.null(params$xmin)) params$xmin <- 0
#                         if (is.null(params$xmax)) params$xmax <- 1
#                         if (is.null(params$ymin)) params$ymin <- 0
#                         if (is.null(params$ymax)) params$ymax <- 1
#                         if (is.null(params$img)) params$img <- "file.png"
#                         params
#                       },
#                       setup_data = function(data, params) {
#                         if (anyDuplicated(data$group)) {
#                           data$group <- paste(data$group, seq_len(nrow(data)), sep = "-")
#                         }
#                         data
#                       },
#                       compute_panel = function(data, scales) {
#                         cols_to_keep <- setdiff(names(data), c("path"))
#                         cbind(create_tiles(data$path), data[, cols_to_keep, drop = FALSE])
#
#                       },
#                       required_aes = c("path")
# )


GeomGDAL <- ggplot2::ggproto(
  "GeomGDAL",
  ggplot2::Geom,
  required_aes = c("path"),
  default_aes = ggplot2::aes(),
  draw_key = ggplot2::draw_key_point,
  draw_panel = function(data, panel_params, coord, interpolate = TRUE) {
    cols_to_keep <- setdiff(names(data), c("path"))
    data <- cbind(data[, cols_to_keep], create_tiles(data$path))
    coords <- coord$transform(data, panel_params)
    grobs <- vector("list", length(coords$path))
    class(grobs) <- "gList"
    for (i in seq_along(grobs))
    {
      rr <- lazyraster::as_raster(lazyraster::lazyraster(coords$path[i]))
      img <- scales::rescale(raster::as.matrix(rr))
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
