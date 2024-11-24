function [fData, params] = CFF_filter_WC_sidelobe_artifact(fData, varargin)
%CFF_FILTER_WC_SIDELOBE_ARTIFACT  Filter sidelobe artefact in WCD
%
%   FDATA = CFF_FILTER_WC_SIDELOBE_ARTIFACT(FDATA) applies the
%   sidelobe-artefact filtering to the WCD in FDATA. The function returns
%   FDATA with the processed WCD.
%
%   CFF_FILTER_WC_SIDELOBE_ARTIFACT(FDATA,PARAMS) uses processing
%   parameters defined as the fields in the PARAMS structure. See
%   CFF_FILTER_WC_SIDELOBE_ARTIFACT_CORE for the possible parameters.
%
%   [FDATA,PARAMS] = CFF_FILTER_WC_SIDELOBE_ARTIFACT(...) also outputs the
%   parameters used in processing.
%
%   See also CFF_FILTER_WC_SIDELOBE_ARTIFACT_CORE, CFF_PROCESS_WC.

%   Copyright 2024-2024 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

% Just pass CFF_FILTER_WC_SIDELOBE_ARTIFACT_CORE as input to
% CFF_PROCESS_WC. 
% Pass input arguments as is, and let any errors be raised there
[fData, params] = CFF_process_WC(fData, @CFF_filter_WC_sidelobe_artifact_CORE, varargin);
