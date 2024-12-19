function [fDataGroup,params] = CFF_group_processing(fDataGroup,procFun,varargin)
%CFF_GROUP_PROCESSING  Apply fData processing function(s) to array of fData
%
%   CoFFee processing functions are normally operating with a single fData
%   structure in input as in: CFF_my_function_name(fData).
%   CFF_GROUP_PROCESSING allows applying one or several such processing
%   functions to cell arrays of fData, i.e. fDataGroup. For now, this
%   function only works for processing functions that output an updated
%   fData, as in: fData=CFF_my_function_name(fData). It also works with
%   processing functions that take a parameter, as in:
%   [fData,params]=CFF_my_function_name(fData,params). For example,
%   CFF_COMPUTE_PING_NAVIGATION_V2, CFF_GEOREFERENCE_BOTTOM_DETECT, and
%   CFF_FILTER_BOTTOM_DETECT_V2 work this way and can be used with
%   CFF_GROUP_PROCESSING.
%
%   FDATAGROUP = CFF_GROUP_PROCESSING(FDATAGROUP,PROCFUN), where FDATAGROUP
%   is a fData structure and PROCFUN is a suitable CFF processing function
%   handle (e.g. @CFF_my_function_name), applies the function with default
%   parameters to the fData structure, and returns the processed fData
%   structure. 
%   FDATAGROUP can also be a cell array of fData structures, in which case
%   the function is applied to each cell element, and the cell array of
%   processed fData structures is returned. If the cell array FDATAGROUP
%   contains a single fData structure, the processed fData is returned as a
%   struct, not a cell array.%
%   PROCFUN can also be a cell array of suitable function handles, in which
%   case each function is applied (with default parameters) in series, over
%   each fData structure in FDATAGROUP in turn. The functions are the inner
%   loop, and the fData structures are the outer loop. Aka, it starts with
%   the first function in PROCFUN being applied to the first fData in
%   FDATAGROUP. Then, it takes the output and applies the second PROCFUN
%   function to it, then it takes that output and applies the third PROCFUN
%   function to it, etc. until all PROCFUN functions have been applied to
%   that first fData. Then it repeats the process on the second fData, then
%   again to the third, etc. until all fData have been processed.
%
%   CFF_GROUP_PROCESSING(FDATAGROUP,PROCFUN,PARAMS) does the same as above,
%   but with passing the structure of parameters PARAMS in input to
%   PROCFUN. If PROCFUN is a cell array of functions, CFF_GROUP_PROCESSING
%   expects a matching array of cell parameter structures as PARAMS. The
%   input parameters are used for all fData in FDATAGROUP, without
%   parameter piping. See the optional parameter 'pipeParams' to modify
%   this behaviour, and for more information. 
%
%   [FDATAGROUP,PARAMS] = CFF_GROUP_PROCESSING(...) also outputs the
%   parameters PARAMS in output of the last iteration of PROCFUN, if
%   parametes were piped (see the optional parameter 'pipeParams' for more
%   information). If parameters were not piped, this output PARAMS is the
%   same as the input PARAMS.
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
%   CFF_GROUP_PROCESSING(...,'saveFDataToDrive',FLAG) with FLAG=1 will
%   force a re-write of fData on the disk after the data are processed. By
%   default (FLAG=0), fData on the disk are not re-written.
%
%   CFF_GROUP_PROCESSING(...,'pipeParams',FLAG) with FLAG=1 will pipe
%   parameters from a processing of a fData to the next. By default
%   (FLAG=0) forces the use of the input parameters for all fData.
%   More info: a CoFFee processing function can take input parameters, as
%   in FDATA=PROCFUN(FDATA,PARAMS). But if some, or all, of the input
%   parameters are missing, then the function uses default parameters. To
%   keep a record of the processing applied, the processing function
%   usually also allows the output of the parameters effectively used, as
%   in [FDATA,PARAMS_OUT]=PROCFUN(FDATA,PARAMS_IN). So if multiple FDATA
%   are to be processed, it is possible to reuse the exact same parameters
%   from one FDATA to the next. This is piping the parameters. 
%   For example, you can call CFF_COMPUTE_PING_NAVIGATION_V2 without input
%   params on a first FDATA with
%   [FDATA,PARAMS]=CFF_COMPUTE_PING_NAVIGATION_V2(FDATA) in order to
%   request that the function automatically finds from the input data 
%   appropriate values for the ellipsoid (PARAMS.ellips) and projection
%   (PARAMS.tmprj) parameters, and use them in processing. Then, with
%   FLAG=1, you can pass those parameters in input to the next FDATA to
%   ensure it is processed with the same projection parameters.
%   Doing so, however, comes with some risk. For example, without input
%   parameters, the processing of the first FDATA may automatically finds
%   'WC' as the datagram source to use (PARAMS.datagramSource), and pipe
%   that parameter to the next FDATA. But if the next FDATA cannot use this
%   datagram source (e.g. you are processing a mix of Kongsberg files,
%   which use 'WC' and Reson-Teledyne s7k files, which use 'AP'), then you
%   will get an error.
%
%   CFF_GROUP_PROCESSING(...,'continueOnError',FLAG) with FLAG=1 will allow
%   to continue processing if an error is encountered with one fData. The
%   function will log the error and resume processing with the next fData.
%   By default (FLAG=0), any error is immediately thrown, which interupts
%   the process. The FLAG=1 option is useful when processing a large number
%   of files overnight, to not let one error interrupt the entire job.
%
%   CFF_GROUP_PROCESSING(...,'comms',COMMS) specifies if and how this
%   function communicates on its internal state (progress, info, errors). 
%   COMMS can be either a CFF_COMMS object, or a text string to initiate a
%   new CFF_COMMS object. Options are 'disp', 'textprogressbar', 'waitbar',
%   'oneline', 'multilines'. By default, using an empty CFF_COMMS object
%   (i.e. no communication). See CFF_COMMS for more information.
%
%   See also CFF_COMPUTE_PING_NAVIGATION_V2,
%   CFF_GEOREFERENCE_BOTTOM_DETECT, CFF_FILTER_BOTTOM_DETECT_V2,
%   CFF_PROCESS_WC. 

%   Copyright 2022-2024 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

%% Input arguments management
p = inputParser;

% fData structure or cell array of fData structures
addRequired(p,'fDataGroup',@(x) all(CFF_is_fData_version_current(x)));

% fData processing function (or cell array of functions)
OneProcFunCheck = @(x) isa(x,'function_handle');
MultProcFunCheck = @(x) iscell(x) && all(cellfun(OneProcFunCheck,x));
addRequired(p,'procFun',@(x) OneProcFunCheck(x) || MultProcFunCheck(x));

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

% pipe parameters from one fdata to the next? 0: no (default), 1: yes
addParameter(p,'pipeParams',0,@(x) mustBeMember(x,[0,1]));

% what if error occurs? 0: throw error (default), 1: log error and go to next file
addParameter(p,'continueOnError',0,@(x) mustBeMember(x,[0,1]));

% information communication (none by default)
addParameter(p,'comms',CFF_Comms()); 

% parse and clean up
parse(p,fDataGroup,procFun,varargin{:});
params = p.Results.params;
procMsg = p.Results.procMsg;
saveFDataToDrive = p.Results.saveFDataToDrive;
pipeParams = p.Results.pipeParams;
continueOnError = p.Results.continueOnError;
comms = p.Results.comms;
clear p
if ischar(comms)
    comms = CFF_Comms(comms);
end

% fDataGroup checks and edits
if isstruct(fDataGroup)
    fDataGroup = {fDataGroup};
end

% number of fData to process
nFData = numel(fDataGroup);

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


%% Prep

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

% start progress
comms.progress(0,nFData);


%% Processing
for iFD = 1:nFData
    
    % get fData
    fData = fDataGroup{iFD};
    
    % display for this line
    filename = CFF_file_name(fData.ALLfilename{1});
    comms.step(sprintf('%i/%i: fData line %s',iFD,nFData,filename));
    
    % processing using a try-catch so that processing left overnight can
    % continue even if one file fails.
    try
        
        % apply each processing function in turn to this fData
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
                comms.info(sprintf('%s...',infoMsg));
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
                    if pipeParams
                        % if we want to pipe parameters from one fData to
                        % the next, save output parameters back as input
                        % parameters
                        [fData,params{iFun}] = feval(procFun{iFun},fData,params{iFun});
                    else
                        % otherwise, just discard that output
                        [fData,~] = feval(procFun{iFun},fData,params{iFun});
                    end
                end
                
            end
        end
        
        % save the updated fData on the drive
        if saveFDataToDrive
            folder_for_converted_data = CFF_converted_data_folder(fData.ALLfilename);
            mat_fdata_file = fullfile(folder_for_converted_data,'fData.mat');
            comms.info('Saving...');
            save(mat_fdata_file,'-struct','fData','-v7.3');
        end
        
        % save fData
        fDataGroup{iFD} = fData;
        
        % communicate progress
        comms.info('Done.');
        comms.progress(iFD,nFData);
        
        % error catching
    catch err
        if continueOnError
            % log the error and continue
            errorFile = CFF_file_name(err.stack(1).file,1);
            errorLine = err.stack(1).line;
            errrorFullMsg = sprintf('%s Error in %s (line %i)',err.message,errorFile,errorLine);
            comms.error(errrorFullMsg);
            comms.progress(iFD,nFData);
        else
            % just rethrow error to terminate execution
            rethrow(err);
        end
    end
    
end


%% finalise

% if we had a single function, output params as struct, not cell array of
% one struct
if nFun == 1
    params = params{1};
end

%% end message
comms.finish('Done');