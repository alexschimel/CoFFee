function [V] = CFF_invpercentile(X,P)
%CFF_INVPERCENTILE  Calculates inverse percentile
%
%   Authors: Alex Schimel (NGU, alexandre.schimel@ngu.no) and Yoann
%   Ladroit (NIWA, yoann.ladroit@niwa.co.nz)
%   2017-2021; Last revision: 27-07-2021

if all(isnan(X))
    V = NaN;
    return
end

X = X(:);
X = X(~isnan(X));
X = sort(X);
iP = round(P.*numel(X)./100);
V = X(iP);
