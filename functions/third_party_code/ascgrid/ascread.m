function [Z, hdr] = ascread(fnm)
    % Read an ESRI ASCII grid file and return a data matrix and a header
    % struct. This function is meant to replace the function arcgridread() that
    % comes with the Mapping Toolbox, because that function doesn't support the
    % full format properly.
    %
    % Written by Nat Wilson

    hdr = struct;

    validattrs = {'nrows', 'ncols', 'xllcorner', 'yllcorner', 'xllcenter',...
                  'yllcenter', 'nodata_value', 'cellsize'};

    h = fopen(fnm);

    inhdr = true;

    while inhdr
        s = fgetl(h);
        ln = regexp(s, '\s+', 'split');
        attr = ln{1};
        val = str2double(ln{2});

        if ismember(lower(attr), validattrs)
            hdr = setfield(hdr, lower(attr), val);
        else
            inhdr = false;
        end
    end

    if ~isfield(hdr, 'nodata_value')
        hdr.nodata_value = nan;
    end

    Z = zeros(hdr.nrows, hdr.ncols);
    for i=1:hdr.nrows
        Z(i,:) = sscanf(s, '%f')';
        s = fgetl(h);
    end

    Z(Z==nan) = nan;

    fclose(h);

end
