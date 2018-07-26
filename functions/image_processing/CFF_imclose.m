function B = CFF_imclose(A,H,varargin)
% B = CFF_imclose(A,H,varargin)
%
% DESCRIPTION
%
% Image morphological closing (ie dilates the erodes)
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

B = CFF_imdilate(A,H);
B = CFF_imerode(B,H);


