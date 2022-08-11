# MATLAB ASCII Grid Interface

This project includes tools to simplify handling ASCII raster data in MATLAB.
The *Mapping Toolbox* contains an `arcgridread` function, but it doesn't
implement the entire ESRI ASCII grid format, and there is no equivalent
`arcgridwrite`.

## Getting started

The code in this package revolves around the *ascgrid* class. The easiest way
to get started is to run

    asc = ascgrid(fnm);

where `fnm` is a path to an existing ESRI ASCII grid file (*\*.asc*). An
*ascgrid* can also be created from scratch by supplying a data matrix `Z` and a
header struct `hdr`:

    asc = ascgrid(Z, hdr);

## Working with ascgrid objects

The resulting object `asc` can be added, subtracted, multiplied, divided, or
compared with other instances of the *ascgrid* class. For example, a glacier
hydraulic potential surface could be calculated from surface (`sur`) and ice
thickness (`thickness`) *ascgrid* objects as:

    rho_w = 1000;
    rho_i = 910;
    g = 9.8;
    bed = sur - thickness;
    pot = rho_w * g * bed + rho_i * g * thickness;

The resulting dataset `pot` is a new *ascgrid* instance with proper spatial
reference information, and can be exported to a file `fnm` with:

    tofile(pot, fnm);

Furthermore, each *ascgrid* instance has a number of methods (functions) that
work on it to retrieve data, perform analyses, or resize or sample the raster
while preserving correct header information. For example, to calculate
hillslope:

    m = slope(asc);

At the time of writing, the following methods exist:

Method                                  |   Description
:---------------------------------------|:-------------------------------------
`checkheader(asc)`                      |   Validate header information
`getheader(asc)`                        |   Retrieve header as a `struct`
`asmatrix(asc)`                         |   Output raster data as a matrix
`coordmesh(asc)`                        |   Generate coordinate matrices
`size(asc)`                             |   Return raster dimensions
`min(asc)`, `max(asc)`, `minmax(asc)`   |   Return values at extrema
`getregion(asc)`                        |   Return the data bounding coordinates
`getindices(asc, x, y)`                 |   Return the indices nearest an (x,y) coordinate
`sample(asc, x, y)`                     |   Return data value at an (x,y) coordinate
`clip(asc, minval, maxval)`             |   Limit data to a `minval`/`maxval`
`resample(asc, res)`                    |   Resample grid to new resolution
`resize(asc, limits)`                   |   Resize grid to new spatial limits
`slope(asc)`                            |   Return the slope
`gradient(asc)`                         |   Return a gradient vector field
`aspect(asc)`                           |   Return slope aspect
`upstream(asc)`                         |   Return upstream area
`contour(asc, ...)`, `contourf(asc, ...)`|  Create controur plots customized for *ascgrid*
`surf(asc, ...)`                        |   Create surface plots customized for *ascgrid*
`pcolor(asc, ...)`                      |   Create pcolor plots customized for *ascgrid*
`imshow(asc, ...)`                      |   Create imshow plots customized for *ascgrid*
`tofile(asc, fnm)`                      |   Export data to a valid ESRI ASCII grid file

