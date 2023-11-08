classdef CFF_Comms < handle
    %CFF_COMMS Information communication object.
    %
    %   A CFF_COMMS object specifies if and how a function communicates on
    %   its internal state (progress, info, warnings, errors). It is
    %   initalized with a string specifying the type of communication: 
    %   'disp' will display communication as its own line in the command
    %   window. 
    %   'textprogressbar' will display communication in a text progress bar
    %   in the command window. 
    %   'waitbar' will display communication in a Matlab waitbar figure.
    %   'oneline' will display communication as a dynamic (changing) 
    %   single line. 
    %   'multilines' will display communication as dynamic (changing)
    %   multiple lines. 
    %   '' (default) will not display NOR STORE any communication. NOTE:
    %   Originally, in this mode, messages were still being recorded so
    %   they could be inspected. But this recording of message (in
    %   particular, the call to function DATETIME) could amount to a lot of
    %   time if there are a lot of messages being recorded. So in this
    %   updated version, using mode this '' (empty) results in NO messages
    %   being recorded at all. Eventually, create another mode where there
    %   is NO display BUT messages are recorded.

    %   Authors: Alex Schimel (NGU, alexandre.schimel@ngu.no) and Yoann
    %   Ladroit (Kongsberg Maritime, yoann.ladroit@km.kongsberg.com) 
    %   2021-2023; Last revision: 19-10-2023
    
    properties
        Type (1,:) char {mustBeMember(Type,{'', 'disp','textprogressbar','waitbar','oneline','multilines'})} = ''
        FigObj = []
        Msgs = {} % messages received (includes error)
        Prog = {} % progress values received
    end
    
    methods
        function obj = CFF_Comms(inputArg)
            %CFF_COMMS Construct an instance of this class
            %   Detailed explanation goes here
            if nargin == 0
                obj.Type = '';
            else
                obj.Type = inputArg;
            end
        end
        
        function start(obj,str)
            %START Summary of this method goes here
            %   Detailed explanation goes here
            
            if isempty(obj.Type)
                return
            end
            
            % record start message
            obj.Msgs(end+1,:) = {datetime('now'), 'Start', str};
            
            % display
            switch obj.Type
                case 'disp'
                    dispstr = [char(string(obj.Msgs{end,1},'HH:mm:ss')) ' - ' obj.Msgs{end,2} ' - ' obj.Msgs{end,3}];
                    disp(dispstr);
                case 'textprogressbar'
                    % init textprogressbar with a string
                    textprogressbar([obj.Msgs{end,3} ': ']);
                case 'waitbar'
                    % init waitbar with title
                    obj.FigObj = waitbar(0,'');
                    obj.FigObj.Name = obj.Msgs{end,3};
                    % init interpreter for future info messages
                    obj.FigObj.Children.Title.Interpreter = 'None';
                    % init message of two line
                    set(obj.FigObj.Children.Title,'String',newline);
                    drawnow
                case {'oneline','multilines'}
                    % init dipstat
                    dispstat('','init');
                    % top line to print and keep
                    dispstr = [obj.Msgs{end,3} ' (started ' char(string(obj.Msgs{end,1})) '):'];
                    dispstat(dispstr,'keepthis');
            end
        end
        
        function step(obj,str)
            %STEP Summary of this method goes here
            %   Detailed explanation goes here
            
            if isempty(obj.Type)
                return
            end
            
            % record step message
            obj.Msgs(end+1,:) = {datetime('now'), 'Step', str};
            
            switch obj.Type
                case 'disp'
                    dispstr = [char(string(obj.Msgs{end,1},'HH:mm:ss')) ' - ' obj.Msgs{end,2} ' - ' obj.Msgs{end,3}];
                    disp(dispstr);
                case 'waitbar'
                    set(obj.FigObj.Children.Title,'String',sprintf('%s\n',obj.Msgs{end,3}));
                    drawnow;
                case 'oneline'
                    % step message
                    dispstr = [obj.Msgs{end,3} '.'];
                    if obj.Prog{end,2}>0
                        % estimated time to complete, from prior progress
                        durationPerStep = cellfun(@minus, obj.Prog(2:end,1), obj.Prog(1:end-1,1));
                        nRemainingSteps = obj.Prog{end,3} - obj.Prog{end,2};
                        ETC = median(durationPerStep).*nRemainingSteps;
                        dispstr = sprintf([dispstr newline 'Estimated time to complete: ' char(string(ETC))]);
                    end
                    % print with dispstat, to be overwritten
                    dispstat(dispstr);
                case 'multilines'
                    % if there was a previous step, reprint and keep it
                    idxPrevStep = find(matches(string(obj.Msgs(1:end-1,2)),'Step'),1,'last');
                    if ~isempty(idxPrevStep)
                        % first, get that last step message
                        dispstr = [obj.Msgs{idxPrevStep,3}];
                        if matches(obj.Msgs(end-1,2),["Info","Error"])
                            % next, add last info message if it exists
                            dispstr = [dispstr '. ' obj.Msgs{end-1,3}];
                        end
                        % finally, add completion
                        dispstr = [dispstr ' (completed ' char(string(obj.Msgs{end,1})) ')'];
                        dispstat(dispstr,'keepthis');
                    end
                    % step message
                    dispstr = [obj.Msgs{end,3} '.'];
                    if obj.Prog{end,2}>0
                        % estimated time to complete, from prior progress
                        durationPerStep = cellfun(@minus, obj.Prog(2:end,1), obj.Prog(1:end-1,1));
                        nRemainingSteps = obj.Prog{end,3} - obj.Prog{end,2};
                        ETC = median(durationPerStep).*nRemainingSteps;
                        dispstr = sprintf([dispstr newline 'Estimated time to complete: ' char(string(ETC))]);
                    end
                    % print with dispstat, to be overwritten
                    dispstat(dispstr);
            end
        end
        
        function info(obj,str)
            %INFO Summary of this method goes here
            %   Detailed explanation goes here
            
            if isempty(obj.Type)
                return
            end
            
            % record info message
            obj.Msgs(end+1,:) = {datetime('now'), 'Info', str};
            
            switch obj.Type
                case 'disp'
                    dispstr = [char(string(obj.Msgs{end,1},'HH:mm:ss')) ' - ' obj.Msgs{end,2} ' - ' obj.Msgs{end,3}];
                    disp(dispstr);
                case 'waitbar'
                    % get last step message
                    idx = find(strcmp(obj.Msgs(:,2),'Step'),1,'last');
                    if isempty(idx)
                        stepStr = '';
                    else
                        stepStr = obj.Msgs{idx,3};
                    end
                    % set waitbar title
                    set(obj.FigObj.Children.Title,'String',sprintf('%s\n%s',stepStr,obj.Msgs{end,3}));
                    drawnow;
                case {'oneline','multilines'}
                    % last step, and new info message
                    idxLastStep = find(matches(string(obj.Msgs(:,2)),'Step'),1,'last');
                    dispstr = [obj.Msgs{idxLastStep,3} '. ' obj.Msgs{end,3}];
                    if obj.Prog{end,2}>0
                        % estimated time to complete, from prior progress
                        durationPerStep = cellfun(@minus, obj.Prog(2:end,1), obj.Prog(1:end-1,1));
                        nRemainingSteps = obj.Prog{end,3} - obj.Prog{end,2};
                        ETC = median(durationPerStep).*nRemainingSteps;
                        dispstr = sprintf([dispstr newline 'Estimated time to complete: ' char(string(ETC))]);
                    end
                    % print with dispstat, to be overwritten
                    dispstat(dispstr);
            end
        end
        
        function error(obj,str)
            %ERROR Summary of this method goes here
            %   Detailed explanation goes here

            if isempty(obj.Type)
                return
            end
            
            % record info message
            obj.Msgs(end+1,:) = {datetime('now'), 'Error', str};
            
            switch obj.Type
                case 'disp'
                    dispstr = [char(string(obj.Msgs{end,1},'HH:mm:ss')) ' - ' obj.Msgs{end,2} ' - ' obj.Msgs{end,3}];
                    disp(dispstr);
                case 'waitbar'
                    % get last step message
                    idx = find(strcmp(obj.Msgs(:,2),'Step'),1,'last');
                    if isempty(idx)
                        stepStr = '';
                    else
                        stepStr = obj.Msgs{idx,3};
                    end
                    % set waitbar title
                    set(obj.FigObj.Children.Title,'String',sprintf('%s\n%s',stepStr,obj.Msgs{end,3}));
                    drawnow;
                case {'oneline','multilines'}
                    % last step, and new info message
                    idxLastStep = find(matches(string(obj.Msgs(:,2)),'Step'),1,'last');
                    dispstr = [obj.Msgs{idxLastStep,3} '. ' obj.Msgs{end,3}];
                    if obj.Prog{end,2}>0
                        % estimated time to complete, from prior progress
                        durationPerStep = cellfun(@minus, obj.Prog(2:end,1), obj.Prog(1:end-1,1));
                        nRemainingSteps = obj.Prog{end,3} - obj.Prog{end,2};
                        ETC = median(durationPerStep).*nRemainingSteps;
                        dispstr = sprintf([dispstr newline 'Estimated time to complete: ' char(string(ETC))]);
                    end
                    % print with dispstat, to be overwritten
                    dispstat(dispstr);
            end
        end
        
        
        function finish(obj,str)
            %FINISH Summary of this method goes here
            %   Detailed explanation goes here
            
            if isempty(obj.Type)
                return
            end
            
            % record finish message
            obj.Msgs(end+1,:) = {datetime('now'), 'Finish', str};
            
            % complete
            switch obj.Type
                case 'disp'
                    dispstr = [char(string(obj.Msgs{end,1},'HH:mm:ss')) ' - ' obj.Msgs{end,2} ' - ' obj.Msgs{end,3}];
                    disp(dispstr);
                case 'textprogressbar'
                    textprogressbar(100);
                    textprogressbar([' ' obj.Msgs{end,3}]);
                case 'waitbar'
                    waitbar(1,obj.FigObj,obj.Msgs{end,3});
                    pause(0.1);
                    close(obj.FigObj);
                case 'oneline'
                    dispstr = [obj.Msgs{end,3} ' (completed ' char(string(obj.Msgs{end,1})) '). Total processing time: ' char(string(obj.Msgs{end,1}-obj.Msgs{1,1}))];
                    dispstat(dispstr,'keepthis');
                case 'multilines'
                    % if there was a previous step, reprint and keep it
                    idxLastStep = find(matches(string(obj.Msgs(:,2)),'Step'),1,'last');
                    dispstr = [obj.Msgs{idxLastStep,3}];
                    if matches(obj.Msgs(end-1,2),["Info","Error"])
                        % next, add last info message if it exists
                        dispstr = [dispstr '. ' obj.Msgs{end-1,3}];
                    end
                    dispstat(dispstr,'keepthis');
                    % complete progress
                    dispstr = [obj.Msgs{end,3} ' (completed ' char(string(obj.Msgs{end,1})) '). Total processing time: ' char(string(obj.Msgs{end,1}-obj.Msgs{1,1}))];
                    dispstat(dispstr,'keepthis');
            end
            
            % show received error messages, if any, and
            % corresponding steps
            if ~isempty(obj.Type) && any(strcmp(obj.Msgs(:,2),'Error'))
                idxStp = cellfun(@(x) strcmp(x,'Step'), obj.Msgs(:,2));
                idxErr = cellfun(@(x) strcmp(x,'Error'), obj.Msgs(:,2));
                idxStp = ismember((1:numel(idxStp))', unique(arrayfun(@(idx) find(idxStp(1:idx-1),1,'last') ,find(idxErr))));
                idxFinal = num2cell(find(idxStp|idxErr));
                errlog = cellfun(@(idx) [char(string(obj.Msgs{idx,1},'HH:mm:ss')) ' - ' obj.Msgs{idx,2} ' - ' obj.Msgs{idx,3}], idxFinal,'UniformOutput', false);
                errlog = strjoin(errlog,newline);
                switch obj.Type
                    case 'waitbar'
                        wardlgTxt = sprintf('Error messages were received:\n');
                        warndlg([wardlgTxt, newline, errlog],'Warning');
                    otherwise
                        % print to screen
                        fprintf('Error messages were received:\n');
                        disp(errlog);
                end
            end

        end
        
        function progress(obj,ii,N)
            %PROGRESS Summary of this method goes here
            %   Detailed explanation goes here
            
            if isempty(obj.Type)
                return
            end
            
            % record progress values
            obj.Prog(end+1,:) = {datetime('now'), ii, N};
            
            switch obj.Type
                case 'disp'
                    fprintf('#%.10g/%.10g\n',ii,N);
                case 'textprogressbar'
                    textprogressbar(100.*ii./N);
                case 'waitbar'
                    waitbar(ii./N,obj.FigObj);
            end
        end
        
    end
end

