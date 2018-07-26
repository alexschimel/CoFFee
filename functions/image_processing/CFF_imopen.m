function B = CFF_imopen(A,H,varargin)
% B = CFF_imopen(A,H,varargin)
%
% DESCRIPTION
%
% Image morphological opening (ie erodes, and then dilates
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
% - varagin
%
% OUTPUT VARIABLES
%
% - NA
%
% RESEARCH NOTES
%
% ...
%
% NEW FEATURES
%
% 2014-10-13: first version.
%
% EXAMPLE
%
% ...
%
%%%
% Alex Schimel, Deakin University
%%%

B = CFF_imerode(A,H);
B = CFF_imdilate(B,H);


