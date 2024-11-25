function [fData, params] = CFF_WC_radiometric_corrections(fData, varargin)
%CFF_WC_RADIOMETRIC_CORRECTIONS  Apply WCD radiometric correction algorithm
%
%   Apply the function that applies physical (aka, not aestethic ones)
%   corrections to the dB level in water-column data: TVG, dB offset, etc.
%
%   FDATA = CFF_WC_RADIOMETRIC_CORRECTIONS(FDATA) applies the WCD
%   radiometric correction function CFF_WC_RADIOMETRIC_CORRECTIONS_CORE to
%   the WCD in FDATA. The function returns FDATA with the modified WCD. 
%
%   CFF_WC_RADIOMETRIC_CORRECTIONS(FDATA,PARAMS) uses processing parameters
%   defined as the fields in the PARAMS structure. See
%   CFF_WC_RADIOMETRIC_CORRECTIONS_CORE for the possible parameters.
%
%   CFF_WC_RADIOMETRIC_CORRECTIONS(...,'comms',COMMS) specifies if and how
%   CFF_WC_RADIOMETRIC_CORRECTIONS_CORE will communicate on its internal
%   state (progress, info, errors). COMMS can be either a CFF_COMMS object,
%   or a text string to initiate a new CFF_COMMS object. Options are
%   'disp', 'textprogressbar', 'waitbar', 'oneline', 'multilines'. By
%   default, using an empty CFF_COMMS object (i.e. no communication). See
%   CFF_COMMS for more information. 
%
%   [FDATA,PARAMS] = CFF_WC_RADIOMETRIC_CORRECTIONS(...) also outputs the
%   parameters used in processing.
%
%   See also CFF_WC_RADIOMETRIC_CORRECTIONS_CORE, CFF_PROCESS_WC,
%   CFF_FILTER_WC_SIDELOBE_ARTIFACT, CFF_MASK_WC_DATA.

%   Copyright 2024-2024 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

% Just pass CFF_WC_RADIOMETRIC_CORRECTIONS_CORE as input to CFF_PROCESS_WC. 
% Pass input arguments as is, and let any errors be raised there
fun = @CFF_WC_radiometric_corrections_CORE;
[fData, params] = CFF_process_WC(fData, fun, varargin{:});