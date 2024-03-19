function Mout = CFF_nanindexable(M,ind)
%
% Exactly same as "Mout = M(ind)" except that ind can contains NaNs, then
% M(NaN) returns NaN.
%
% NEW FEATURES
%
% 2014-10-02: first version.
%
% EXAMPLE
%
% data1=[10 11 15]
% ind1=[2 NaN 3]
% sprintf('What should be data1(ind1) but written M1=CFF_nanindexable(data1,ind1):')
% M1=CFF_nanindexable(data1,ind1)
%
% data2 = [10 15 17 18 19]
% ind2 = [1 4; NaN 2]
% sprintf('What should be data2(ind2) but written M2=CFF_nanindexable(data2,ind2):')
% M2 = CFF_nanindexable(data2,ind2)

%   Copyright 2014-2014 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/


indtemp = ind;
indtemp(isnan(indtemp)) = 1;
Mtemp = M(indtemp);
mask = double(~isnan(ind));
mask(mask==00) = NaN;
Mout = Mtemp.*mask;





