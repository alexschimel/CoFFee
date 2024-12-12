function bool = CFF_is_WC_processed(fDataInput)
%CFF_IS_WC_PROCESSED  Check if fData has processed WCD
%
%   BOOL = CFF_PROCESS_WC(FDATA) where FDATA is a single fData structure
%   returns True if FDATA has processed WCD, otherwise False.

%   BOOL = CFF_PROCESS_WC(FDATAGROUP) where FDATAGROUP is a cell array of
%   fData structures returns a vector of booleans where each element is
%   True or False whether the corresponding fData element of FDATAGROUP has
%   processed WCD. 
%
%   See also CFF_IS_FDATA_VERSION_CURRENT

%   Copyright 2024-2024 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

% Input arguments management
p = inputParser;
addRequired(p,'fData',@(x) all(CFF_is_fData_version_current(x)));
parse(p,fDataInput);
fDataInput = p.Results.fData;
clear p

% condition
testFun = @(x) isfield(x,'X_SBP_WaterColumnProcessed');
if isstruct(fDataInput)
    bool = testFun(fDataInput);
else
    bool = cellfun(testFun,fDataInput);
end