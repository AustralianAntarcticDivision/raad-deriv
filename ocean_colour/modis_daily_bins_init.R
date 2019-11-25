library(raadtools)
library(croc)
library(tibble)
library(dplyr)
## data frame of all L3 RRS files for MODISA
files <- ocfiles(time.resolution = "daily", product = "MODISA", varname = "RRS", type = "L3b", bz2.rm = TRUE, ext = "nc") %>%
  as_tibble() %>% transmute(date, file = basename(fullname), fullname)

#daterange <- as.POSIXct(c("2015-07-01", "2016-07-01"), tz = "GMT")
lonrange <- c(-180, 180)
#latrange <- c(-78, -30)
latrange <- c(-90, 90)

## initialize the bin logic for MODISA
init <- initbin(NUMROWS = 4320)
latbin_idx <- which(between(init$latbin, latrange[1], latrange[2]))
bins <- tibble(bin_num = seq(init$basebin[min(latbin_idx)], init$basebin[min(c(max(latbin_idx)+1, length(init$latbin)))]))
# xy <- bin2lonlat(bins$bin_num, 4320)
# bins <- bins %>% filter(between(xy$x, lonrange[1], lonrange[2])) %>%
#   mutate(bin_idx = row_number())
# rm(xy)

outp <- "/rdsi/PRIVATE/raad/data_local/acecrc.org.au/ocean_colour/modis_daily"
get_l3 <- function(file_package, outpath) {
  file <- file_package$file
  datei <- file_package$datei
  yr <- format(datei, "%Y")
  
#  "/rdsi/PRIVATE/raad/data_local/acecrc.org.au/ocean_colour/modis_daily",
  fname <- file.path(outpath, yr, sprintf("%s", format(datei, "modis_%Y%j.rds")))
 if (file.exists(fname)) return(NULL)
  bins <- file_package$bins
  binlist <- try(read_binlist(file), silent = TRUE)
  if (inherits(binlist, "try-error")) return(file)
  bins_present <- inner_join(bins, binlist, "bin_num")
  if (nrow(bins_present) < 1) return(NULL)
  d1 <-   bind_cols(binlist, read_compound(file,
                                           compound_vars = c("Rrs_443", "Rrs_488", "Rrs_555", "Rrs_547"))) %>%
    inner_join(bins, "bin_num")  %>% mutate(chla_johnson = chla(., sensor = "MODISA", algo = "johnson")) %>%
    mutate(chla_nasa = chla(., sensor = "MODISA", algo = "oceancolor")) %>%
    dplyr::select(bin_num, chla_johnson, chla_nasa) %>%
    filter(!is.na(chla_johnson), chla_johnson > 0)  %>%
    mutate(date = datei)
  print(basename(fname))
  saveRDS(d1, fname, compress = FALSE)
}

pkgs <- lapply(seq(nrow(files)), function(x) list(file = files$fullname[x], datei = files$date[x], bins = bins))
library(future.apply)
plan(multiprocess)

#"2018-04-03 16:12:15 AEST"
print(Sys.time())
aa <- future_lapply(pkgs, get_l3, outpath = outp)
print(Sys.time())

