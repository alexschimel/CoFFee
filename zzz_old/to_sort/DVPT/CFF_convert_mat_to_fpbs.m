function DATA = CFF_convert_mat_to_fpbs(MATfile)
%CFF_CONVERT_MAT_TO_FPBS  Convert a mat file (Kongsberg) to FPBS format.
%
%	PROCESSING SUMMARY
% 
%   - get number of files in input
%   - create file table and store file-specific variables
%   - for each file
%     - get number of pings in file
%     - create ping table and store ping-specific variables
%     - for each ping
%         - get number of beams in ping
%         - create beam table and store beam-specific variables
%         - for each beam
%             - get number of samples
%             - create sample table and store sample-specific variables
%   - save the four tables in DATA
% 
%   RESEARCH NOTES
% 
%   - FPBS format consists in four tables: File, Ping, Beam and Samp
%   containing the data relative to each of the levels of this hierarchy.
%   For example, a transmit beam angle is a ping parameter and will
%   therefore be stored in the Ping table, while a receive beam angle is a
%   beam parameter and will therefore be stored in the Beam table.
% 
%   - This code uses datagram "EM_SeabedImage89" to get needed information
%   in number of pings, beams and samples. For older datagrams, modify this
%   code with a test at the beggining for existence of "EM_SeabedImage89"
% 
%   - There is potential display at several levels. Beam level is on.
%   Comment it too to speed up process. Maybe add a flag to specify which
%   level of comment is wanted

%   See also CFF_OTHER_FUNCTION_NAME.

%   Copyright 2014-2014 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

% This function is made for a cell array of filenames. If input is a single
% filename string, turn to cell
if ischar(MATfile)
    MATfile = {MATfile};
end

% initializing number of entries:
tnf = 0;
tnp = 0;
tnb = 0;
tns = 0;

% get number of files in this project
nFiles = length(MATfile);

% initialize File table with ID
File.ID(tnf+(1:nFiles))   = tnf+[1:nFiles]';

% grab File variables here
File.Name(tnf+(1:nFiles)) = MATfile';
% ...

% update tnf
tnf = tnf+nFiles;

% now get inside each file
for ff = 1:nFiles
    
    % display
    %txt = sprintf('file #%i (ID %i)',ff,File.ID(ff));
    %disp(txt)
    
    % get file data
    DAT = load(MATfile{ff});
    
    % get ping counters
    pingCounter = DAT.EM_SeabedImage89.PingCounter;
    
    % get number of pings in this file
    nPings = length(pingCounter);
    
    % initialize Ping table with ID, Index and Rank
    thisPingID = tnp+[1:nPings]';
    Ping.ID(tnp+(1:nPings))    = thisPingID;
    Ping.Index(tnp+(1:nPings)) = ff .* ones(nPings,1); % corresponding file ID
    Ping.Rank(tnp+(1:nPings))  = [1:nPings]'; % rank of ping in this file
    
    % %%%%%%%%%%%%%%%%%% grab Ping variables here %%%%%%%%%%%%%%%%%%%%%%%%%
    
    % from XYZ 88
    Ping.Counter(tnp+(1:nPings)) = pingCounter;
    Ping.Time(tnp+(1:nPings)) = datenum(int2str(DAT.EM_XYZ88.Date'),'yyyymmdd') + DAT.EM_XYZ88.TimeSinceMidnightInMilliseconds'./(1000.*60.*60.*24);
    Ping.SonarDepth(tnp+(1:nPings)) = DAT.EM_XYZ88.TransmitTransducerDepth;
    
    % from Raw Range and Angle 78
    Ping.SamplingFrequency(tnp+(1:nPings)) = DAT.EM_RawRangeAngle78.SamplingFrequencyInHz;
    Ping.SoundSpeedAtSonarDepth(tnp+(1:nPings)) = DAT.EM_RawRangeAngle78.SoundSpeedAtTransducer./10;
    Ping.TiltAngle(tnp+(1:nPings)) = cell2mat(DAT.EM_RawRangeAngle78.TiltAngle)./100;
    
    % from Seabed Image 89
    Ping.RangeToNormalIncidence(tnp+(1:nPings)) = DAT.EM_SeabedImage89.RangeToNormalIncidence;
    Ping.BSN(tnp+(1:nPings)) = DAT.EM_SeabedImage89.NormalIncidenceBS./10;
    Ping.BSO(tnp+(1:nPings)) = DAT.EM_SeabedImage89.ObliqueBS./10;
    Ping.TxBeamwidth(tnp+(1:nPings)) = DAT.EM_SeabedImage89.TxBeamwidthAlong./10;
    Ping.TVGLawCrossoverAngle(tnp+(1:nPings)) = DAT.EM_SeabedImage89.TVGLawCrossoverAngle./10;
    
    % ...
    
    % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % update tnp
    tnp = tnp+nPings;
    
    % now for this file, get inside each ping
    for pp = 1:nPings
        
        % display
        %txt = sprintf('file #%i (ID %i)\t\tping #%i (ID %i)',ff,File.ID(ff),pp,thisPingID(pp));
        %disp(txt)
        
        % get number of beams in this ping
        nBeams = DAT.EM_SeabedImage89.NumberOfValidBeams(pp);
        
        % Initialize Beam table with ID, Index and Rank
        thisBeamID = tnb+[1:nBeams]';
        Beam.ID(tnb+(1:nBeams))    = thisBeamID;
        Beam.Index(tnb+(1:nBeams)) = thisPingID(pp) .* ones(nBeams,1); % corresponding ping ID
        Beam.Rank(tnb+(1:nBeams))  = [1:nBeams]'; % rank of beam in this ping
        
        % %%%%%%%%%%%%%% grab beam variables here %%%%%%%%%%%%%%%%%%%%%%%%%
        
        % from XYZ 88
        Beam.DepthZ(tnb+(1:nBeams)) = DAT.EM_XYZ88.DepthZ{pp};
        Beam.AcrosstrackDistanceY(tnb+(1:nBeams)) = DAT.EM_XYZ88.AcrosstrackDistanceY{pp};
        Beam.AlongtrackDistanceX(tnb+(1:nBeams)) = DAT.EM_XYZ88.AlongtrackDistanceX{pp};
        Beam.QualityFactor(tnb+(1:nBeams)) = DAT.EM_XYZ88.QualityFactor{pp};
        Beam.BeamIncidenceAngleAdjustment(tnb+(1:nBeams)) = DAT.EM_XYZ88.BeamIncidenceAngleAdjustment{pp}./10;
        Beam.ReflectivityBS(tnb+(1:nBeams)) = DAT.EM_XYZ88.ReflectivityBS{pp}./10;
        
        % from Raw Range and Angle 78
        Beam.BeamPointingAngleReNormalToSonarFace(tnb+(1:nBeams)) = DAT.EM_RawRangeAngle78.BeamPointingAngle{pp}./100;
        
        % ...
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        % update tnb
        tnb = tnb+nBeams;
        
        % now for this ping in this file, get inside each beam
        for bb = 1:nBeams
            
            % display
            %txt = sprintf('file #%i (ID %i)\t\tping #%i (ID %i)\t\tbeam #%i (ID %i)',ff,File.ID(ff),pp,thisPingID(pp),bb, thisBeamID(bb));
            %disp(txt)
            
            % get number of samples in this beam
            nSamples = DAT.EM_SeabedImage89.NumberOfSamplesPerBeam{pp}(bb);
            
            % Initialize Samp table with ID, Index and Rank
            thisSampID = tns+[1:nSamples]';
            Samp.ID(tns+(1:nSamples))    = thisSampID;
            Samp.Index(tns+(1:nSamples)) = thisBeamID(bb) .* ones(nSamples,1); % corresponding ping ID
            Samp.Rank(tns+(1:nSamples))  = [1:nSamples]'; % rank of beam in this ping
            
            % %%%%%%%%%%%%%% grab Samp variables here %%%%%%%%%%%%%%%%%%%%%
            % ...
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            % update tns
            tns = tns+nSamples;
            
        end
        
    end
    
end

DATA.File = File;
DATA.Ping = Ping;
DATA.Beam = Beam;
DATA.Samp = Samp;



% % How to access data:
% 
% % Forward: Given a sample at random in the sample table (ie, its ID).
% % What beam, ping and file is it in? (ie, their ID)
% i_s = 506897;
% i_b = DATA.Samp.Index(i_s);
% i_p = DATA.Beam.Index(i_b);
% i_f = DATA.Ping.Index(i_p);
% % pretty easy.
% 
% % Backward: Given a file, ping, beam and sample numbers (ie, file ID, and
% % ping, beam and sample ranks). What ID is that sample? 
% i_f = 3; % 3rd file
% r_p = 2; % 2nd ping in that file
% r_b = 1; % 1st beam in that ping
% r_s = 5; % 5th sample in that beam
% i_p = find((DATA.Ping.Index==i_f)&(DATA.Ping.Rank==r_p)); % ID of 2nd ping in 3rd file
% i_b = find((DATA.Beam.Index==i_p)&(DATA.Beam.Rank==r_b)); % ID of 1st beam in 2nd ping in 3rd file
% i_s = find((DATA.Samp.Index==i_b)&(DATA.Samp.Rank==r_s)); % ID of 5th sample in 1st beam in 2nd ping in 3rd file
% 
% % to be sure, let's retrieve the ranks from these IDs
% sN = DATA.Samp.Rank(i_s)
% bN = DATA.Beam.Rank(i_b)
% pN = DATA.Ping.Rank(i_p)
% fN = DATA.File.ID(i_f)


