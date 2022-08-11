function out = CFF_is_field_or_prop(structOrObj,fieldOrPropName)
%CFF_IS_FIELD_OR_PROP  Test if field or property is in struct or object
%
%   CFF_IS_FIELD_OR_PROP(structOrObj,fieldOrPropName) returns 1 if
%   "structOrObj" is a structure and "fieldOrPropName" is one of its
%   fields, OR if "structOrObj" is an object and "fieldOrPropName" is one
%   of its fields properties.
%
%   Created so as to test for the existence of a field in a structure even
%   when that structure was not loaded in memory but mapped as a MapFile
%   object.

%   See also ISSTRUCT, ISPROP.

%   Authors: Alex Schimel (NGU, alexandre.schimel@ngu.no) and Yoann Ladroit
%   (NIWA, yoann.ladroit@niwa.co.nz) 
%   2021-2021; Last revision: 01-12-2021


if isstruct(structOrObj)
    out = isfield(structOrObj,fieldOrPropName);
elseif isobject(structOrObj)
    out = isprop(structOrObj,fieldOrPropName);
else
    out = NaN;
end

