library(raadtools)
library(croc)
library(tibble)
library(dplyr)
## data frame of all L3 RRS files for MODISA
files <- ocfiles(time.resolution = "daily", product = "MODISA", varname = "RRS", type = "L3b", bz2.rm = TRUE, ext = "nc") %>%
  as_tibble() %>% transmute(date, file = basename(fullname), fullname)

lonrange <- c(-180, 180)
latrange <- c(-90, 90)

## initialize the bin logic for MODISA
init <- initbin(NUMROWS = 4320)
latbin_idx <- which(between(init$latbin, latrange[1], latrange[2]))
bins <- tibble(bin_num = seq(init$basebin[min(latbin_idx)], init$basebin[min(c(max(latbin_idx)+1, length(init$latbin)))]))

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


for (i in seq_len(nrow(files))) {

  datei = files$date[i]
  yr <- format(datei, "%Y")

  if (!file.exists(file.path(outp, yr))) {
    dir.create(file.path(outpath, yr))
  }

  file <- files$fullname[i]
  fname <- file.path(outp, yr, sprintf("%s", format(datei, "modis_%Y%j.rds")))
  if (!file.exists(fname)) {

    pkg <- list(file = file, datei = datei, bins = bins)
    get_l3(pkg, outpt)
  }
}
