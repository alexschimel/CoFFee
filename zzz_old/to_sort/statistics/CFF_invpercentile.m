function [V] = CFF_invpercentile(X,P)
% Calculates inverse percentile
%   Copyright 2014-2014 Alexandre Schimel
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
