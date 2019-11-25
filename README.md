# raad-deriv

Derived products using raadtools

# Ocean colour

Scripts in 'ocean_colour/' process the daily L3bin RRS data from NASA for SeaWiFS and MODISA, calculating Johnson 2013 and NASA-algorithm 
chlorophyll-a and storing as data frames. This is used by the 'read_chla()' function in raadtools. 

# Polar currents

Scripts in 'polar_currents' process the daily SSALTO/DUACS Delayed-Time Level-4 sea surface height altimetry surface currents (U, V m/s) 
into polar grid form and stored as native raster binary (.grd, RRASTER). 

## TODO

time since melt, sospatial lat-packing, derivaadc

