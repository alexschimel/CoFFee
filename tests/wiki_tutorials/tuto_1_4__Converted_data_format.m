% This help page informs on the format of converted multibeam data in CoFFee.

% CoFFee's MATLAB multibeam data format `fData` is a single structure (named `fData`) whose fields contains the various relevant data elements.

% # 1. "a_b_c" fields

% Most fields are coded as "a_b_c" where:
% * "a" is a two-character code indicating the data's origin datagram type ('source datagram' code),
% * "b" is a two- or three-character code indicating the data's dimensions ('data dimension' code), and 
% * "c" is the name of the data ('data name' code).

% For example, `fData.X8_BP_DepthZ` is the bathymetry data (_DepthZ_), as a beam/ping matrix (_BP_), coming from the 'XYZ 88' datagrams of a Kongsberg .all file (_X8_).

% ## a. Source datagram code

% A non-exhaustive list of source datagram codes is:
% * IP: Installation parameters
% * Ru: Runtime Parameters
% * De: Depth datagram
% * He: Height datagram
% * X8: XYZ 88 datagram
% * SI: Seabed image datagram
% * S8: Seabed image data 89
% * WC: Watercolumn data
% * Po: Position datagram
% * At: Attitude datagram
% * SS: Sound speed profile datagram
% * AP: "Amplitude and phase" water-column data

% **IMPORTANT NOTES**:
% * As the names indicate, this format was created for Kongsberg raw data in the *.all format. Other formats are now supported, but those original 'datagram source' names are conserved. For example, when converting .s7k data, the field `fData.X8_BP_DepthZ` is used to store data from the 'Depth' data from the R7027 records. (Yes that's not ideal, but I was not planning to ever support other formats when I initially designed this during my Ph.D using a Kongsberg system.) 
% * Not all datagram type is converted. If a datagram type is missing (e.g. raw range and angle datagrams), it is because I never ended up needing it (e.g. I never ended up redoing the ray-bending).

% Also note that data derived from computations are recorded back into the structure, using 'X' for the source datagram code.

% ## b. Data dimension code

% The data dimension code informs the units for each dimension of the data. 

% In a matrix, the first letter correspond to the rows and the second letter corresponds to the columns:
% * BP: beam/ping array (e.g. bathymetry)
% * SB: sample/beam array (e.g. water-column data for one ping)
% * TP: transmit-sector/ping array
% * HP: head/ping array (e.g. ping information for dual-head systems)
% * SP: samples/ping array (note: samples are not sorted, this is not equivalent to range!)
% * ED: entries-per-datagram/datagram array (for attitude or position data)
% * RP: range (choose distance, time or sample) / ping array
% * SP: swathe (meters) / ping array
% * LL: lat/long (WGS84) array
% * NE: northing/easting array

% Row-vectors and column-vectors follow the same principle, with a "1" for the unit dimension, aka:
% * 1P: ping-like single-row-vector
% * B1: beam-like single-column-vector
% * 1D: datagram-like single-row-vector (for attitude or position data)
% * N1: northing-like single-column-vector
% * 1E: easting-like single-row-vector

% Water-column data are three-dimensional and thus have a three-character code:
% * SBP: sample/beam/ping tensor

% Same for data gridded in three dimensions:
% * NEH: northing/easting/height tensor

% # 2. Non-structured fields

% There are a few other fields who don't follow the above structure. These are metadata:
% * MET_Fmt_version (string): version number of the `fData` format.
% * ALLfilename (string or 1x2 cell): source filename(s).
% * IP_ASCIIparameters (struct): decoded ASCII parameters from the Installation Parameters datagrams.
% * dr_sub: decimation factor in range (for water-column data).
% * db_sub: decimation factor in beams (for water-column data).

% # 3. Converted data saved on the drive

% To avoid having to reconvert data for every MATLAB session, `fData` can be saved on the drive. CoFFee functions (and apps based on CoFFee) will expect to find them as a `fData.mat` file located in a subfolder named after the file (without the extension) inside a `Coffee_files` folder at the same location as the raw data file. For example, for a raw data file located at `C:\Data\my_raw_data_file.all`, CoFFee functions will look for converted data in the file `C:\Data\Coffee_files\my_raw_data_file\fData.mat`.

% # 4. Water-column data

% Raw water-column data are massive. They are even larger if converted directly in the MATLAB format. So instead, CoFFee saves them as a simple (but large) ping/beam/sample array that is stored on the drive in a binary data file, which is then memory-mapped to the field `fData.WC_SBP_SampleAmplitudes` for fast access. The binary data file is stored in the `Coffee_files` folder, near the `fData.mat` file. 

% Note that you will not be able to delete a binary data file if it is currently memory-mapped in MATLAB. Also, if you delete a binary data file and then load an `fData.mat` file in MATLAB where the now-deleted binary data file was supposed to be mapped, you will obviously run into issues. For a clean delete of a binary data file, first ensure that there are no `fData` structure in memory in MATLAB that memory-maps it (just `clear` those variables, or do it when MATLAB is closed), then delete the binary data file AND the corresponding `fData.mat` file.

% Note that since data are stored as sample/beam/ping tensors, the ping with the largest number of sample defines the size of the entire tensor. To avoid having to store a large number of NaN values in the case that number changes significantly during the file (e.g. recording on a slope), the water-column data are often broken down into several binary files storing tensors of different sample dimension. All of them are memory-mapped to the `fData` field `fData.WC_SBP_SampleAmplitudes`. This makes retrieving the data from `fData` a bit complicated, so use the function `CFF_get_WC_data` to read a desired range of pings of water-column data from `fData`. This function has the advantage of also allowing decimating in range and beams when reading.
