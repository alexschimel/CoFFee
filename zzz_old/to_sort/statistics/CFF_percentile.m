function [P] = CFF_percentile(X,V)

X = X(:);
X = X(~isnan(X));
X = sort(X);
X2 = abs(X-V);
[a,b]=min(X2);
P = b*100./numel(X);