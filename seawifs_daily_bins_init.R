source(file.path(getOption("default.datadir"), "data_local/acecrc.org.au/ocean_colour/oc-funs.R"))
get_l3 <- function(file_package) {
  file <- file_package$file
  datei <- file_package$datei
  yr <- format(datei, "%Y")
  fname <- file.path(getOption("default.datadir"), "data_local/acecrc.org.au/ocean_colour/seawifs_daily", yr, sprintf("%s", format(datei, "seawifs_%Y%j.rds")))
  if (file.exists(fname)) return(NULL)
  bins <- file_package$bins
  binlist <- try(read_binlist(file), silent = TRUE)
  if (inherits(binlist, "try-error")) return(file)
  bins_present <- inner_join(bins, binlist, "bin_num")
  if (nrow(bins_present) < 1) return(NULL)
  d1 <-   try(bind_cols(binlist, read_compound(file,
                                           compound_vars = c("Rrs_443", "Rrs_490", "Rrs_555", "Rrs_510"))) %>%
    inner_join(bins, "bin_num")  %>% mutate(chla_johnson = chla(., sensor = "SeaWiFS", algo = "johnson")) %>%
    mutate(chla_nasa = chla(., sensor = "SeaWiFS", algo = "oceancolor")) %>%
    dplyr::select(bin_num, chla_johnson, chla_nasa) %>%
    filter(!is.na(chla_johnson), chla_johnson > 0)  %>%
    mutate(date = datei))
  if (inherits(d1, "try-error")) {
    print(fname)
    return(NULL)
  }
 saveRDS(d1, fname, compress = FALSE)
}

library(raadtools)
library(roc)
library(tibble)
library(dplyr)
## data frame of all L3 RRS files for SeaWiFS
files <- ocfiles(time.resolution = "daily", product = "SeaWiFS", varname = "RRS", type = "L3b", bz2.rm = TRUE, ext = "nc") %>%
  as_tibble() %>% transmute(date, file = basename(fullname), fullname)

#daterange <- as.POSIXct(c("2015-07-01", "2016-07-01"), tz = "GMT")
lonrange <- c(-180, 180)
#latrange <- c(-78, -30)
latrange <- c(-90, 90)
library(roc)
## initialize the bin logic for MODISA
init <- initbin(NUMROWS = 2160)
latbin_idx <- which(between(init$latbin, latrange[1], latrange[2]))
bins <- tibble(bin_num = seq(init$basebin[min(latbin_idx)], init$basebin[min(c(max(latbin_idx)+1, length(init$latbin)))]))
#xy <- bin2lonlat(bins$bin_num, 2160)
#bins <- bins %>% filter(between(xy$x, lonrange[1], lonrange[2])) %>%
#  mutate(bin_idx = row_number())
#rm(xy)



pkgs <- lapply(seq(nrow(files)), function(x) list(file = files$fullname[x], datei = files$date[x], bins = bins))
library(future)
plan(multiprocess)

print(Sys.time())
aa <- future_lapply(pkgs, get_l3)
print(Sys.time())


