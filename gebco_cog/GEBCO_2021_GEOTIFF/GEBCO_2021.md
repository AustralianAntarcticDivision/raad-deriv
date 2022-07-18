

```bash
gdalwarp ../data/www.bodc.ac.uk/data/open_download/gebco/gebco_2021/zip/GEBCO_2021.nc ../data_local/aad.gov.au/gebco/GEBCO_2021.tif  -co NUM_THREADS=28  -co BLOCKSIZE=512 -co BIGTIFF=YES -co COMPRESS=DEFLATE -ot Int16 -t_srs  "OGC:CRS84" -of COG -te -180 -90 180 90 -ts  86400 43200
```
