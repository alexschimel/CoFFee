function [fData, params] = CFF_mask_WC_data(fData, varargin)
%CFF_MASK_WC_DATA  Apply water-column data masking algorithm
%
%	Apply the function that masks unwanted parts of the water-column data,
%	e.g. data in outer beams, within a range from the sonar, bottom echo,
%	distance from bottom echo, within an Easting-Northing polygon,
%	exceeding a threshold of faulty bottom detects, ranges beyong the
%	Minimum Slant Range, etc. 
%
%   FDATA = CFF_MASK_WC_DATA(FDATA) applies the WCD masking function
%   CFF_MASK_WC_DATA_CORE to the WCD in FDATA. The function returns FDATA
%   with the modified WCD. 
%
%   CFF_MASK_WC_DATA(FDATA,PARAMS) uses processing parameters defined as
%   the fields in the PARAMS structure. See CFF_MASK_WC_DATA_CORE for the
%   possible parameters.
%
%   CFF_MASK_WC_DATA(...,'comms',COMMS) specifies if and how
%   CFF_MASK_WC_DATA_CORE will communicate on its internal state (progress,
%   info, errors). COMMS can be either a CFF_COMMS object, or a text string
%   to initiate a new CFF_COMMS object. Options are 'disp',
%   'textprogressbar', 'waitbar', 'oneline', 'multilines'. By default,
%   using an empty CFF_COMMS object (i.e. no communication). See CFF_COMMS
%   for more information. 
%
%   [FDATA,PARAMS] = CFF_MASK_WC_DATA(...) also outputs the
%   parameters used in processing.
%
%   See also CFF_MASK_WC_DATA_CORE, CFF_PROCESS_WC,
%   CFF_FILTER_WC_SIDELOBE_ARTIFACT, CFF_WC_RADIOMETRIC_CORRECTIONS.

%   Copyright 2024-2024 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

% Just pass CFF_MASK_WC_DATA_CORE as input to CFF_PROCESS_WC. 
% Pass input arguments as is, and let any errors be raised there
fun = @CFF_mask_WC_data_CORE;
[fData, params] = CFF_process_WC(fData, fun, varargin{:});