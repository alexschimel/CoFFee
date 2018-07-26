function [PB,ID] = CFF_pingbeamarray(FPBS,fields)
% [PB,ID] = CFF_pingbeamarray(FPBS,fields)
%
% DESCRIPTION
%
% Turns desired fields from FPBS.Beam into Ping-Beam arrays (for
% visualization or ping/beam processing.
%
% USE
%
% ...
%
% PROCESSING SUMMARY
% 
% - ...
% - ...
% - ...
%
% INPUT VARIABLES
%
% - FPBS: Multibeam data in FPBS format
% - fields: can be one string of characters or cells of strings for several
%
% OUTPUT VARIABLES
%
% - PB: ping/beam matrix of the desired field. Will be returned as a cell
% array of matrices if several fields were requested.
% - ID: ping/beam matrix of corresponding ID. Needed to write back into
% FPBS.
%
% RESEARCH NOTES
%
% Note the output as pings for rows, going 1 to M where M is the maximum
% FPBS.Beam.Index. Beams go from 1 to N where N is the maximum
% FPBS.Beam.Rank.
%
% NEW FEATURES
%
% 2013-10-02: first version.
%
% EXAMPLE
%
% ...
%
%%%
% Alex Schimel, Deakin University
%%%

%% Get a ping/beam matrix of ID fields for indexing
iping=FPBS.Beam.Index;
ibeam=FPBS.Beam.Rank;
ind=FPBS.Beam.ID;
ID = CFF_nanfull(sparse(iping,ibeam,ind));


%% after we have our ID matrix, use it to index the desired fields
if ischar(fields)
    fields={fields};
end
for ff = 1:length(fields)
    PB{ff} = CFF_nanindexable(FPBS.Beam.(fields{ff}),ID);
end
if length(PB)==1
    PB = PB{1};
end

%% last, get the rows and columns variables
% hmmmm. removed for now
%rows_pingID =  
%beam_columns = 


%% trash:

% % original idea using loops. (long!)
% 
% % bounds
% nPings = max(FPBS.Beam.Index);
% nBeams = max(FPBS.Beam.Rank);
% 
% % initialize
% IDs1 = nan(nPings,nBeams);
% 
% % fill in ID
% for pp = 1:nPings
%     for bb = 1:nBeams
%         ind = find( (FPBS.Beam.Index==pp)&(FPBS.Beam.Rank==bb) );
%         if numel(ind)==1
%             IDs1(pp,bb) = FPBS.Beam.ID(ind);
%         end
%     end
% end

% some tests on using sparse patrices for the job
        
% some tests
% i=[1 2 3 3]
% j=[1 3 1 3]
% s=[11 13 17 18]
% S = sparse(i,j,s)
% F = CFF_nanfull(S)
% data = [1:10:200]
% Mout = CFF_nanindexable(data,F)

