function [fData, params] = CFF_filter_WC_sidelobe_artifact(fData, varargin)
%CFF_FILTER_WC_SIDELOBE_ARTIFACT  Apply sidelobe artefact filtering algo
%
%   Apply the function that runs a variation of the Slant Range Signal
%   Normalization (SRSN) algorithm (Schimel et al., 2020. DOI:
%   10.3390/rs12091371) to filter sidelobe artefacts in water-column data.
%
%   FDATA = CFF_FILTER_WC_SIDELOBE_ARTIFACT(FDATA) applies the
%   sidelobe-artefact filtering function
%   CFF_FILTER_WC_SIDELOBE_ARTIFACT_CORE to the WCD in FDATA. The function
%   returns FDATA with the modified WCD.
%
%   CFF_FILTER_WC_SIDELOBE_ARTIFACT(FDATA,PARAMS) uses processing
%   parameters defined as the fields in the PARAMS structure. See
%   CFF_FILTER_WC_SIDELOBE_ARTIFACT_CORE for the possible parameters.
%
%   CFF_FILTER_WC_SIDELOBE_ARTIFACT(...,'comms',COMMS) specifies if and how
%   CFF_FILTER_WC_SIDELOBE_ARTIFACT_CORE will communicate on its internal
%   state (progress, info, errors). COMMS can be either a CFF_COMMS object,
%   or a text string to initiate a new CFF_COMMS object. Options are
%   'disp', 'textprogressbar', 'waitbar', 'oneline', 'multilines'. By
%   default, using an empty CFF_COMMS object (i.e. no communication). See
%   CFF_COMMS for more information. 
%
%   [FDATA,PARAMS] = CFF_FILTER_WC_SIDELOBE_ARTIFACT(...) also outputs the
%   parameters used in processing.
%
%   See also CFF_FILTER_WC_SIDELOBE_ARTIFACT_CORE, CFF_PROCESS_WC,
%   CFF_MASK_WC_DATA, CFF_WC_RADIOMETRIC_CORRECTIONS.

%   Copyright 2024-2024 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

% Just pass CFF_FILTER_WC_SIDELOBE_ARTIFACT_CORE as input to
% CFF_PROCESS_WC. 
% Pass input arguments as is, and let any errors be raised there
fun = @CFF_filter_WC_sidelobe_artifact_CORE;
[fData, params] = CFF_process_WC(fData, fun, varargin{:});