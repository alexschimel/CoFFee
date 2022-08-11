function status = ascwrite(data, hdr, fnm)
    % Write data and hdr to an ESRI ASCII grid file.
    % No checks are performed to ensure the validity of the data or hdr. For
    % safety, the tofile() method of the geogrid class can be used.
    %
    % Written by Nat Wilson

    f = fopen(fnm, 'w');

    if isa(data, 'float')
        ftype = 'f';
    elseif isa(data, 'integer')
        ftype = 'i';
    end

    fprintf(f, '%s            %i\n', 'NCOLS', hdr.ncols);
    fprintf(f, '%s            %i\n', 'NROWS', hdr.nrows);
    fprintf(f, '%s        %i\n', 'XLLCENTER', hdr.xllcenter);
    fprintf(f, '%s        %i\n', 'YLLCENTER', hdr.yllcenter);
    fprintf(f, '%s         %i\n', 'CELLSIZE', hdr.cellsize);
    fprintf(f, '%s     %i\n', 'NODATA_VALUE', hdr.nodata_value);

    for row=1:hdr.nrows
        fprintf(f, ['%', ftype, ' '], data(row, :));
        fprintf(f, '\n');
    end

    status = fclose(f);

end
