function [fDataGroup,params] = CFF_group_processing(procFun,fDataGroup,varargin)
%CFF_GROUP_PROCESSING  Apply fData processing function(s) to array of fData
%
%   CoFFee processing functions are normally operating with a single fData
%   structure in input as in: CFF_my_function_name(fData).
%   CFF_GROUP_PROCESSING allows applying one or several such processing
%   functions to cell arrays of fData, i.e. fDataGroup. For now, this
%   function only works for processing functions that output an updated
%   fData, as in: fData=CFF_my_function_name(fData). It also works with
%   processing functions that take a parameter, as in:
%   [fData,params]=CFF_my_function_name(fData,params). See
%   CFF_COMPUTE_PING_NAVIGATION_V2 for example of a suitable processing
%   function.
%
%   FDATAGROUP = CFF_GROUP_PROCESSING(PROCFUN,FDATAGROUP), with PROCFUN
%   being a suitable CFF processing function handle (e.g.
%   @CFF_my_function_name), applies the function to the cell array of
%   fData structures FDATAGROUP, and returns the cell array of processed
%   fData structures. PROCFUN can also be a cell array of suitable function
%   handles, in which case all functions are applied in chain to each
%   element of FDATAGROUP before moving to the next element, with the fData
%   output by a processing function used in input for the next processing
%   function. No other input arguments are passed to PROCFUN, so if 
%   the PROCFUN function(s) require(s) parameters, then it/they will use
%   default parameters.
%
%   CFF_GROUP_PROCESSING(PROCFUN,FDATAGROUP,PARAMS) also passes the
%   structure of parameters PARAMS in input to PROCFUN. If PROCFUN is a
%   cell array of functions, CFF_GROUP_PROCESSING expects a matching array
%   of cell parameter structures. Note that PARAMS gets updated with each
%   application of PROCFUN to a fData, as in
%   [FDATA,PARAMS]=PROCFUN(FDATA,PARAMS), implying that subsequent 
%   iterations may use a different PARAMS than earlier ones. For example,
%   it is typical to pass an empty PARAMS to the function
%   CFF_COMPUTE_PING_NAVIGATION_V2 in order to request default parameters,
%   which are then output by that function. As a result, for the next
%   fData, the function will use those defined parameters. 
%
%   [FDATAGROUP,PARAMS] = CFF_GROUP_PROCESSING(...) also outputs the
%   parameters PARAMS in output of the last iteration of PROCFUN.
%
%   CFF_GROUP_PROCESSING(...,'procMsg',MSG) uses the string of characters
%   MSG as a communication message. If a single processing function is
%   used, this message will be the start message. If several processing
%   functions are in input, this message will be info messages for each
%   step of the processing. Note that if there is no communication
%   requested (see parameter 'comms'), then this parameter is ignored. By
%   default (or specifying MSG = 'default'), the message is 'Applying
%   PROCFUN'.
%
%   CFF_GROUP_PROCESSING(...,'saveFDataToDrive',FLAG) with FLAG = 1 will
%   force a re-write of fData on the disk after the data are processed. By
%   default (FLAG = 0), fData on the disk are not re-written.
%
%   CFF_GROUP_PROCESSING(...,'abortOnError',FLAG) with FLAG = 1 will
%   interrupt processing if an error is encountered. By default (FLAG = 0),
%   the error is logged and processing continues to the next fData. 
%
%   CFF_GROUP_PROCESSING(...,'comms',COMMS) specifies if and how this
%   function communicates on its internal state (progress, info, errors). 
%   COMMS can be either a CFF_COMMS object, or a text string to initiate a
%   new CFF_COMMS object. Options are 'disp', 'textprogressbar', 'waitbar',
%   'oneline', 'multilines'. By default, using an empty CFF_COMMS object
%   (i.e. no communication). See CFF_COMMS for more information.
%
%   See also CFF_COMPUTE_PING_NAVIGATION_V2,
%   CFF_GEOREFERENCE_BOTTOM_DETECT_V2, CFF_FILTER_BOTTOM_DETECT. 

%   Authors: Alex Schimel (NGU, alexandre.schimel@ngu.no) and Yoann Ladroit
%   (NIWA, yoann.ladroit@niwa.co.nz) 
%   2022-2022; Last revision: 27-07-2022


%% Input arguments management
p = inputParser;

% fData processing function (or cell array of functions)
OneProcFunCheck = @(x) isa(x,'function_handle');
MultProcFunCheck = @(x) iscell(x) && all(cellfun(OneProcFunCheck,x));
addRequired(p,'procFun',@(x) OneProcFunCheck(x) || MultProcFunCheck(x));

% array of fData structures
addRequired(p,'fDataGroup',@(x) iscell(x) && all(cellfun(@CFF_is_fData_version_current,x)));

% function parameters (or cell array of parameters)
OneParamsCheck = @(x) isstruct(x);
MultParamsCheck = @(x) iscell(x) && all(cellfun(OneParamsCheck,x));
addOptional(p,'params',struct(),@(x) OneParamsCheck(x)||MultParamsCheck(x));

% string message for each processing function ('default' for default
% message) 
OneProcMsgCheck = @(x) ischar(x);
MultProcMsgCheck = @(x) iscell(x) && all(cellfun(OneProcMsgCheck,x));
addParameter(p,'procMsg','default',@(x) OneProcMsgCheck(x) || MultProcMsgCheck(x));

% save fData to hard-drive? 0: no (default), 1: yes
addParameter(p,'saveFDataToDrive',0,@(x) mustBeMember(x,[0,1]));

% what if error during conversion? 0: to next file (default), 1: abort
addParameter(p,'abortOnError',0,@(x) mustBeMember(x,[0,1]));

% information communication (none by default)
addParameter(p,'comms',CFF_Comms()); 

% parse and clean up
parse(p,procFun,fDataGroup,varargin{:});
params = p.Results.params;
procMsg = p.Results.procMsg;
saveFDataToDrive = p.Results.saveFDataToDrive;
abortOnError = p.Results.abortOnError;
comms = p.Results.comms;
clear p
if ischar(comms)
    comms = CFF_Comms(comms);
end


%% Prep

% if single procFun, params, and procMsg in input, turn to cell
if ~iscell(procFun), procFun = {procFun}; end
if ~iscell(params), params = {params}; end
if ~iscell(procMsg), procMsg = {procMsg}; end

% number of processing functions
nFun = numel(procFun);

% check that number of inputs match
if nFun == 1
   % one function 
   if numel(params)>1 || numel(procMsg)>1
       error('Too many params or procMsg in input');
   end
else
    % more than one function
    if numel(params)==1
        % but only 1 param, assumed to be used for all functions
        % repeat input
        params = repmat(params,size(procFun));
    end
    if numel(procMsg)==1
        % but only 1 procMsg, assumed to be used for all functions
        % repeat input
        procMsg = repmat(procMsg,size(procFun));
    end
    if numel(params)~=nFun || numel(procMsg)~=nFun
        error('Number of procFun, params, and procMsg in input must match');
    end
end

% start message
if nFun == 1
    % with a single processing function, the start message is that function
    % message
    startMsg = procMsg{1};
    if strcmp(startMsg,'default')
        % default start message is using the name of the function
        procFunInfo = functions(procFun{1});
        startMsg = sprintf('Applying %s',procFunInfo.function); 
    end
else
   % with multiple processing functions, the start message is a generic
   % message
   startMsg = 'Applying multiple processing'; 
end
comms.start(startMsg);

% number of fData to process
nFData = numel(fDataGroup);

% start progress
comms.progress(0,nFData);


%% Processing
for iFD = 1:nFData
    
    % try-catch sequence to allow continuing to next file if one fails
    try
        
        % get fData
        fData = fDataGroup{iFD};
        
        % display for this line
        filename = CFF_file_name(fData.ALLfilename{1});
        comms.step(sprintf('%i/%i: fData line %s',iFD,nFData,filename));
        
        % apply each processing function in turn
        for iFun = 1:nFun
            
            % if applying multiple processing functions, use each
            % function's procMsg as an info message. If only one single
            % function, this was done at the start.
            if nFun>1 
                infoMsg = procMsg{iFun};
                if strcmp(infoMsg,'default')
                    % default start message is using the name of the function
                    procFunInfo = functions(procFun{iFun});
                    infoMsg = sprintf('Applying %s',procFunInfo.function);
                end
                comms.info(infoMsg)
            end

            % function application is dependent on whether function takes
            % parameters or not
            if nargin(procFun{iFun}) == 1
                % processing function takes only one input (fData)
                fData = feval(procFun{iFun},fData);
            else
                % processing function takes at least one argument
                % (nargin>=2) or a varargin (nargin<0). In any case, give
                % it parameters in input
                if nargout(procFun{iFun}) == 1
                    % processing function has only one output (fData)
                    fData = feval(procFun{iFun},fData,params{iFun});
                else
                    % processing function has at least one extra output
                    % argument (nargout>=2) or a varargout (nargout<0). In
                    % any case, assume the first is output parameters
                    [fData,params{iFun}] = feval(procFun{iFun},fData,params{iFun});
                end
                
            end
        end
        
        % save fData to drive
        if saveFDataToDrive
            % get output folder and create it if necessary
            wc_dir = CFF_converted_data_folder(fData.ALLfilename);
            mat_fdata_file = fullfile(wc_dir, 'fData.mat');
            comms.info('Saving');
            save(mat_fdata_file,'-struct','fData','-v7.3');
        end
        
        % save fData
        fDataGroup{iFD} = fData;
        
        % successful end of this iteration
        comms.info('Done');
        
    catch err
        if abortOnError
            % just rethrow error to terminate execution
            rethrow(err);
        else
            % log the error and continue
            errorFile = CFF_file_name(err.stack(1).file,1);
            errorLine = err.stack(1).line;
            errrorFullMsg = sprintf('%s (error in %s, line %i)',err.message,errorFile,errorLine);
            comms.error(errrorFullMsg);
        end
    end
    
    % communicate progress
    comms.progress(iFD,nFData);
    
end


%% finalise

% if we had a single function, output params as struct, not cell array of
% one struct
if nFun == 1
    params = params{1};
end


%% end message
comms.finish('Done');