function [V] = CFF_invpercentile(X,P)
%CFF_INVPERCENTILE  Calculates inverse percentile
%
%   Copyright 2017-2021 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

if all(isnan(X))
    V = NaN;
    return
end

X = X(:);
X = X(~isnan(X));
X = sort(X);
iP = round(P.*numel(X)./100);
V = X(iP);
