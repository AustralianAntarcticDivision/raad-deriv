default_grid <- function() {
  
  prjj <-         "+proj=laea +lat_0=-90 +datum=WGS84"
  raster(spex::buffer_extent(projectExtent(raster(extent(-180, 180, -90, -30), 
                                                  crs = "+init=epsg:4326"), 
                                           prjj), 25000), 
         res = 25000, crs = prjj)
  
  
}


library(raadtools)
library(dplyr)
files <- currentsfiles()

#u <- readcurr(xylim = extent(-180, 180, -75, -20), uonly = TRUE)
#v <- readcurr(xylim = extent(-180, 180, -75, -20), vonly = TRUE)

ex <- extent(-180, 180, -75, -30)
geti_u <- function(i = 1) {
  readcurr(files$date[i], xylim = ex, uonly = TRUE, inputfiles = files)
}
geti_v <- function(i = 1) {
  readcurr(files$date[i], xylim = ex, vonly = TRUE, inputfiles = files)
}
u <- geti_u()
target <- default_grid()
library(nabor)
xy <- coordinates(target)
xyi <- rgdal::project(xy, projection(target), inv = TRUE)
library(tabularaster)
index <- tibble(cellindex = seq_len(ncell(u)))
index[c("qx", "qy")] <- rgdal::project(xyFromCell(u, index$cellindex), "+proj=eqc")
index[c("sx", "sy")] <- rgdal::project(xyFromCell(u, index$cellindex), projection(target))
knn <- WKNNF(as.matrix(index[c("sx", "sy")]))

dirbase <- "/rdsi/PRIVATE/raad/data_local/aad.gov.au/currents/polar"
for (i in seq_len(nrow(files))) {
#for (i in 9400:nrow(files)) {
  ## split by year
  diryear <- file.path(dirbase, format(files$date[i], "%Y"))
  if (!file.exists(diryear)) dir.create(diryear)
  #ufile <- file.path(diryear, gsub( "nc$", "grd", gsub("dt_global_allsat_phy_l4_", "dt_south_polar_u_", basename(files$fullname[i]))))
  #vfile <- file.path(diryear, gsub( "nc$", "grd", gsub("dt_global_allsat_phy_l4_", "dt_south_polar_v_", basename(files$fullname[i]))))

  ufile <- file.path(diryear, sprintf("dt_south_polar_u_%s_12345678.grd", format(files$date[i], "%Y%m%d")))
  vfile <- file.path(diryear, sprintf("dt_south_polar_v_%s_12345678.grd", format(files$date[i], "%Y%m%d")))
   if (file.exists(ufile) && file.exists(vfile)) next; 
  
  U <- try(geti_u(i))
  if (inherits(U, "try-error")) next;
  V <- geti_v(i)
  index$x1 <- index$qx + values(U)
  index$y1 <- index$qy + values(V)
  
  index[c("ex", "ey")] <- rgdal::project(rgdal::project(as.matrix(index[c("x1", "y1")]), "+proj=eqc", inv = TRUE), 
                                         projection(target))
  
  #index$pu <- index$sx - index$ex
  #index$pv <- index$sy - index$ey
  
## DAMN - get the sign right 2021-04-29 lols
  index$pu <- index$ex - index$sx 
  index$pv <- index$ey - index$sy

  ee <- extract(U, xyi)

  
  xyq <- xy[!is.na(c(ee)), ]
  idx <- knn$query(xyq, k = 1, eps = 0, radius = 0)
  uu <- vv <- target
  uu[!is.na(ee)] <- index$pu[idx$nn.idx]
  vv[!is.na(ee)] <- index$pv[idx$nn.idx]
  uu <- setZ(uu, files$date[i])
  vv <- setZ(vv, files$date[i])
  tmp <- writeRaster(uu, filename = ufile, overwrite = TRUE)
  tmp <- writeRaster(vv, filename = vfile, overwrite = TRUE)
  print(i)
}
