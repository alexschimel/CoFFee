function [P] = CFF_percentile(X,V)
% Calculates percentile
%   Copyright 2014-2014 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

X = X(:);
X = X(~isnan(X));
X = sort(X);
X2 = abs(X-V);
[a,b]=min(X2);
P = b*100./numel(X);