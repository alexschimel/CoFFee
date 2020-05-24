%%% CFF_ll2tm.m
%
% Converts geographic coordinates (Latitude, Longitude) to Transverse
% Mercator Projections coordinates (Northing, Easting). Also provides grid
% convergence (angle between true north and grid north), point scale factor
% and UTM zone if not specified in input. Different ellipsoids or
% projections can be specified.    
%
%% Help
%
% *USE*
%
% _This section contains a more detailed description of what the function
% does and how to use it, for the interested user to have an overall
% understanding of its function. Example below to replace. Delete these
% lines XXX._  
%
% This is a text file containing the basic comment template to add at the
% start of any new ESP3 function to serve as function help. XXX 
%
% *INPUT VARIABLES*
%
% * |lon: Required. Longitude scalar or vector in decimal degrees.  
% * |lat|: Required. Latitude scalar or vector in decimal degrees.  
% * |ellips|: Required. code string for the input coordinates' ellipsoid.
% Supported codes: 'wgs84', 'grs80' 
% * |tmproj|: Required. Code string for the ouptut transverse mercator
% projection. Supported codes: 
%       'utm' -> Universal Transvere Mercator projection without zone
%       specified. The function computes the longitudinal zone for input
%       coordinates and returns the result in variable utmzone. Note: UTM
%       projection is based on WGS84 ellipsoid.
%
%       'utmXXY' -> Universal Transvere Mercator projection with sone
%       specified, where XX is the zone and Y the hemisphere (ex: UTM60S).
%       Note: UTM projection is based on WGS84 ellipsoid.
%
%       The following Transverse Mercator projections for New Zealand are
%       based on the NZGD2000 datum, which uses the GRS80 ellipsoid.
%
%   	'nztm2000'   -> "New Zealand Transverse Mercator Projection".
%       'citm2000'   -> "Chatham Islands Transverse Mercator 2000".
%       'aktm2000'   -> "Auckland Islands Transverse Mercator 2000".
%       'catm2000'   -> "Campbell Islands Transverse Mercator 2000".
%       'aitm2000'   -> "Antipodes Islands Transverse Mercator 2000".
%       'ritm2000'   -> "Raoul Island Transverse Mercator 2000".
%       'edentm2000' -> "Mount Eden 2000".
%       'plentm2000' -> "Bay of Plenty 2000".
%       'povetm2000' -> "Poverty Bay 2000".
%       'hawktm2000' -> "Hawkes Bay 2000".
%       'taratm2000' -> "Taranaki 2000".
%       'tuhitm2000' -> "Tuhirangi 2000".
%       'wangtm2000' -> "Wanganui 2000".
%       'wairtm2000' -> "Wairarapa 2000".
%       'welltm2000' -> "Wellington 2000".
%       'colltm2000' -> "Collingwood 2000".
%       'nelstm2000' -> "Nelson 2000".
%       'karatm2000' -> "Karamea 2000".
%       'bulltm2000' -> "Buller 2000".
%       'greytm2000' -> "Grey 2000".
%       'amurtm2000' -> "Amuri 2000".
%       'marltm2000' -> "Marlborough 2000".
%       'hokitm2000' -> "Hokitika 2000".
%       'okartm2000' -> "Okarito 2000".
%       'jacktm2000' -> "Jacksons Bay 2000".
%       'pleatm2000' -> "Mount Pleasant 2000".
%       'gawltm2000' -> "Gawler 2000".
%       'timatm2000' -> "Timaru 2000".
%       'lindtm2000' -> "Tindis Peak 2000".
%       'nichtm2000' -> "Mount Nicholas 2000".
%       'yorktm2000' -> "Mount York 2000".
%       'obsetm2000' -> "Observation Point 2000".
%       'taietm2000' -> "North Taieri 2000".
%       'bluftm2000' -> "Bluff 2000".
%
% *OUTPUT VARIABLES*
%
% * |E|: Projection easting scalar or vector
% * |N|: Projection northing scalar or vector
% * |gridConv|: Grid convergence in degrees. Grid convergence is the angle
% at a point between true and grid North. It is positive when grid north
% lies to the West of the true North.  
% * |pointScaleFactor|: Point scale factor. The scale factor at a point
% away from the central meridian. 
% * |utmzone|: UTM longitudinal zone (ouput if zone was not specified in
% input, i.e. ellips = 'utm').
%
% *DEVELOPMENT NOTES*
%
% * The GRS80 and WGS84 ellipsoids are so close that the differences in
% Lat/Long are usually considered insignificant for most applications. This
% function makes this assumption too, even though a fair conversion from
% say, WGS84 lat/long to a NZ projection based on GRS80 would require a
% datum transformation. If this function is ever extended to different
% ellipsoids, a datum transformation will be required.
% * This function is based on "LINZS25002. Standard for New Zealand
% Geodetic Datum 2000 Projections: version 2." and original code from
% "ll2tm.m" by David Johnson and Brett Beamsley (Metocean Solutions LTD).
%
% *NEW FEATURES*
%
% * 2018-10-11: new header
% * 2010-06: first version.
%
% *EXAMPLE*
%
% _This section contains examples of valid function calls. Note that
% example lines start with 3 white spaces so that the publish function
% shows them correctly as matlab code. Example below to replace. Delete
% these lines XXX._ 
%
%   example_use_1; % comment on what this does. XXX
%   example_use_2: % comment on what this line does. XXX
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Alexandre Schimel, University of Waikato

%% Function
function [E, N, gridConv, pointScaleFactor, utmzone] = CFF_ll2tm(lon, lat, ellips, tmproj)


%% ellipsoid parameters:
% - semi major axis
% - inverse flattening

PARAM_ELLIP = struct( 'grs80', [6378137.0, 298.257222101], ...
                      'wgs84', [6378137.0, 298.257223563] );
                  
%% projection parameters:
% - origin latitude
% - origin longitude
% - false northing
% - false eastin
% - central meridian scale factor

PARAM_PROJ = struct( ...
    'utm',        [                   0                    0        0       0 0      ], ...
    'nztm2000',   [                   0                  173 10000000 1600000 0.9996 ], ...
    'citm2000',   [                   0        -(176+30./60) 10000000 3500000 1      ], ...
    'aktm2000',   [                   0                  166 10000000 3500000 1      ], ...
    'catm2000',   [                   0                  169 10000000 3500000 1      ], ...
    'aitm2000',   [                   0                  179 10000000 3500000 1      ], ...
    'ritm2000',   [                   0                 -178 10000000 1600000 0.9996 ], ...
    'edentm2000', [-(36+52./60+47./3600) 174+45./60+51./3600   800000  400000 0.9999 ], ...
    'plentm2000', [-(37+45./60+40./3600) 176+27./60+58./3600   800000  400000 1      ], ...
    'povetm2000', [-(38+37./60+28./3600) 177+53./60+08./3600   800000  400000 1      ], ...
    'hawktm2000', [-(39+39./60+03./3600) 176+40./60+25./3600   800000  400000 1      ], ...
    'taratm2000', [-(39+08./60+08./3600) 174+13./60+40./3600   800000  400000 1      ], ...
    'tuhitm2000', [-(39+30./60+44./3600) 175+38./60+24./3600   800000  400000 1      ], ...
    'wangtm2000', [-(40+14./60+31./3600) 175+29./60+17./3600   800000  400000 1      ], ...
    'wairtm2000', [-(40+55./60+31./3600) 175+38./60+50./3600   800000  400000 1      ], ...
    'welltm2000', [-(41+18./60+04./3600) 174+46./60+35./3600   800000  400000 1      ], ...
    'colltm2000', [-(40+42./60+53./3600) 172+40./60+19./3600   800000  400000 1      ], ...
    'nelstm2000', [-(41+16./60+28./3600) 173+17./60+57./3600   800000  400000 1      ], ...
    'karatm2000', [-(41+17./60+23./3600) 172+06./60+32./3600   800000  400000 1      ], ...
    'bulltm2000', [-(41+48./60+38./3600) 171+34./60+52./3600   800000  400000 1      ], ...
    'greytm2000', [-(42+20./60+01./3600) 171+32./60+59./3600   800000  400000 1      ], ...
    'amurtm2000', [-(42+41./60+20./3600) 173+00./60+36./3600   800000  400000 1      ], ...
    'marltm2000', [-(41+32./60+40./3600) 173+48./60+07./3600   800000  400000 1      ], ...
    'hokitm2000', [-(42+53./60+10./3600) 170+58./60+47./3600   800000  400000 1      ], ...
    'okartm2000', [-(43+06./60+36./3600) 170+15./60+39./3600   800000  400000 1      ], ...
    'jacktm2000', [-(43+58./60+40./3600) 168+36./60+22./3600   800000  400000 1      ], ...
    'pleatm2000', [-(43+35./60+26./3600) 172+43./60+37./3600   800000  400000 1      ], ...
    'gawltm2000', [-(43+44./60+55./3600) 171+21./60+38./3600   800000  400000 1      ], ...
    'timatm2000', [-(44+24./60+07./3600) 171+03./60+26./3600   800000  400000 1      ], ...
    'lindtm2000', [-(44+44./60+06./3600) 169+28./60+03./3600   800000  400000 1      ], ...
    'nichtm2000', [-(45+07./60+58./3600) 168+23./60+55./3600   800000  400000 1      ], ...
    'yorktm2000', [-(45+33./60+49./3600) 167+44./60+19./3600   800000  400000 1      ], ...
    'obsetm2000', [-(45+48./60+58./3600) 170+37./60+42./3600   800000  400000 1      ], ...
    'taietm2000', [-(45+51./60+41./3600) 170+16./60+57./3600   800000  400000 0.99996], ...
    'bluftm2000', [-(46+36./60+00./3600) 168+20./60+34./3600   800000  400000 1      ]       );
             
             
% add individual UTM zones 
for ii=1:60
	newfield = ['utm' num2str(ii,'%2.2i') 'N'];
    p = [0, -183+6*ii, 0, 500000, 0.9996];
    PARAM_PROJ = setfield(PARAM_PROJ,newfield,p);
    newfield=['utm' num2str(ii,'%2.2i') 'S'];
    p = [0, -183+6*ii, 10000000, 500000, 0.9996];
    PARAM_PROJ = setfield(PARAM_PROJ,newfield,p);
end
               
                 
%% test on input strings                 
if ~ischar(ellips) || ~isfield(PARAM_ELLIP,ellips)
	warning('input ellips not recognised. help CFF_ll2tm for supported string codes');
    return;
end
if ~ischar(tmproj) || ~isfield(PARAM_PROJ,tmproj)
	warning('input tmproj not recognised. help CFF_ll2tm for supported string codes');
    return;
end

%% getting parameters
eval(['a = PARAM_ELLIP.' ellips '(1);']);      % semi-major axis (metres)
eval(['f = 1./PARAM_ELLIP.' ellips '(2);']);   % flattening
eval(['origLat = PARAM_PROJ.' tmproj '(1);']); % origin latitude
eval(['origLon = PARAM_PROJ.' tmproj '(2);']); % origin longitude
eval(['FN = PARAM_PROJ.' tmproj '(3);']);      % false northing (metres)
eval(['FE = PARAM_PROJ.' tmproj '(4);']);      % false easting (metres)
eval(['k0 = PARAM_PROJ.' tmproj '(5);']);      % central meridian scale factor


%% changing parameters if 'utm' input
if strcmp(tmproj,'utm')
    origLat = 0;
    origLon = floor(lon./6).*6+3;
    FN = (lat < 0).*10000000;
    FE = 500000;  
    k0 = 0.9996;
    utmzone = [num2str(floor(origLon./6)+31) char(78.*(lat>=0)+83.*(lat<0))];
else
    utmzone = [];
end

%% every angle in radians for computations
lat = lat.*pi./180;
lon = lon.*pi./180;
origLat = origLat.*pi./180;
origLon = origLon.*pi./180;

%% some more computation parameters

% Semi-minor axis of reference ellipsoid
b  = a.*(1-f); 

% Eccentricity
e  = sqrt((a.^2 - b.^2)./(a.^2));

% Meridian distance: the distance along the meridian from the latitude of
% the projection origin (origLat) to latitude (Lat).
m = a.*(  ( 1 - e.^2./4 - 3.*e.^4./64 - 5.*e.^6./256 )  .* lat         ...
         -( 3.*e.^2./8 + 3.*e.^4./32 + 45.*e.^6./1024 ) .* sin(2.*lat) ...
         +( 15.*e.^4./256 + 45.*e.^6./1024 )            .* sin(4.*lat) ...
         -( 35.*e.^6./3072 )                            .* sin(6.*lat) );
     
% idem for origLat
m0 = a.*(  ( 1 - e.^2./4 - 3.*e.^4./64 - 5.*e.^6./256 )  .* origLat         ...
          -( 3.*e.^2./8 + 3.*e.^4./32 + 45.*e.^6./1024 ) .* sin(2.*origLat) ...
          +( 15.*e.^4./256 + 45.*e.^6./1024 )            .* sin(4.*origLat) ...
          -( 35.*e.^6./3072 )                            .* sin(6.*origLat) );
      
% Radius of curvature of the meridian
rho = a.*(1-e.^2)./(1-e.^2.*sin(lat).^2).^1.5;     
     
% Radius of curvature in the prime vertical
nu = a./sqrt(1-e.^2.*sin(lat).^2); 

psi = nu./rho;
% rsquare = rho.*nu.*k0.^2; % unused

% Last parameters.
t = tan(lat);
om = lon - origLon;

%% compute easting

term1 = (1./6).*om.^2.*cos(lat).^2.* ( psi - t.^2 );
term2 = (1./120).*om.^4.*cos(lat).^4.* ( 4.*psi.^3.*(1-6.*t.^2) + psi.^2.*(1+8.*t.^2)  - psi.*2.*t.^2 + t.^4);
term3 = (1./5040).*om.^6.*cos(lat).^6.* ( 61 - 479.*t.^2 + 179.*t.^4 - t.^6 );

E = FE + k0.*nu.*om.*cos(lat).*(1 + term1 + term2 + term3);

%% compute northing

term1 = (1./2).*om.^2.*nu.*sin(lat).*cos(lat);
term2 = (1./24).*om.^4.*nu.*sin(lat).*cos(lat).^3.* ( 4.*psi.^2 + psi - t.^2 );
term3 = (1./720).*om.^6.*nu.*sin(lat).*cos(lat).^5.* ( 8.*psi.^4.*(11-24.*t.^2) - 28.*psi.^3.*(1-6.*t.^2) + psi.^2.*(1-32.*t.^2) - psi.*2.*t.^2 + t.^4 );
term4 = (1./40320).*om.^8.*nu.*sin(lat).*cos(lat).^7.* ( 1385 - 3111.*t.^2 + 543.*t.^4 - t.^6);

N = FN + k0.*(m - m0 + term1 + term2 + term3 + term4);

%% compute grid convergence

term1 = - om.*sin(lat);
term2 = - (1./3).*om.^3.*sin(lat).*cos(lat).^2.*( 2.*psi.^2-psi );
term3 = - (1./15).*om.^5.*sin(lat).*cos(lat).^4.*( psi.^4.*(11-24.*t.^2) - psi.^3.*(11-36.*t.^2) + 2.*psi.^2.*(1-7.*t.^2) + psi.*t.^2);
term4 = - (1./315).*om.^7.*sin(lat).*cos(lat).^6.*( 17 - 26.*t.^2 + 2.*t.^4 );

gridConv = term1 + term2 + term3 + term4;

%% compute point scale factor

term1 = (1./2).*om.^2.*psi.*cos(lat).^2;
term2 = (1./24).*om.^4.*cos(lat).^4.* ( 4.*psi.^3.*(1-6.*t.^2) + psi.^2.*(1+24.*t.^2)  - 4.*psi.*t.^2);
term3 = (1./720).*om.^6.*cos(lat).^6.* ( 61 - 148.*t.^2 + 16.*t.^4);

pointScaleFactor = k0.*(1 + term1 + term2 + term3);

%% turn angles back to degrees for output
gridConv = gridConv.*180./pi;


