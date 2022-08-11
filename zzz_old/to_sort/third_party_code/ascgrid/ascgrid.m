classdef ascgrid < handle
    % Regular grid implementation for handling geographic raster data.
    % This is built with the ESRI ASCII grid format in mind, and is based on
    % karta.raster.aaigrid
    %
    % Written by Nat Wilson

    properties (GetAccess=protected)
        hdr = struct;
    end

    properties (SetAccess=protected)
        data = ascgrid.empty;
    end

    methods (Access=private)

        function [x0, y0, nx, ny, d] = geo(this)
            % Return geographical parameters pulled from ascgrid.hdr
            x0 = this.hdr.xllcenter;
            y0 = this.hdr.yllcenter;
            d = this.hdr.cellsize;
            [ny, nx] = size(this.data);
        end

        function this = fullheader(this)
            % Make sure that both corner and center references are in header
            % and are consistent. Gives xllcenter/yllcenter priority over
            % xllcorner/yllcorner.
            d = this.hdr.cellsize;
            names = lower(fieldnames(this.hdr));
            if ~ismember('xllcenter', names)
                this.hdr.xllcenter = this.hdr.xllcorner + d/2.0;
            else
                this.hdr.xllcorner = this.hdr.xllcenter - d/2.0;
            end
            if ~ismember('yllcenter', names)
                this.hdr.yllcenter = this.hdr.yllcorner + d/2.0;
            else
                this.hdr.yllcorner = this.hdr.yllcenter - d/2.0;
            end
        end

    end

    methods (Hidden=true)

        function res = plus(this, that)
            if isa(this, 'ascgrid') && isnumeric(that)
                res = ascgrid(this.data + that, this.hdr);
            elseif isnumeric(this) && isa(that, 'ascgrid')
                res = ascgrid(this + that.data, that.hdr);
            elseif isa(this, 'ascgrid') && isa(that, 'ascgrid')
                if isequaln(this.hdr, that.hdr)
                    res = ascgrid(this.data + that.data, this.hdr);
                else
                    error('Both ascgrid instances must have equivalent spatial references');
                end
            else
                error(['Arithmetic operations not defined for ', ...
                       class(this), ' and ', class(that)]);
            end
        end

        function res = uminus(this)
            res = ascgrid(-this.data, this.hdr);
        end

        function res = minus(this, that)
            res = this + (-that);
        end

        function res = mtimes(this, that)
            if isa(this, 'ascgrid') && isnumeric(that)
                res = ascgrid(this.data .* that, this.hdr);
            elseif isnumeric(this) && isa(that, 'ascgrid')
                res = ascgrid(this .* that.data, that.hdr);
            elseif isa(this, 'ascgrid') && isa(that, 'ascgrid')
                if isequaln(this.hdr, that.hdr)
                    res = ascgrid(this.data .* that.data, this.hdr);
                else
                    error('Both ascgrid instances must have equivalent spatial references');
                end
            else
                error(['Arithmetic operations not defined for ', ...
                       class(this), ' and ', class(that)]);
            end
        end

        function res = mrdivide(this, that)
            if isa(this, 'ascgrid') && isnumeric(that)
                res = ascgrid(this.data ./ that, this.hdr);
            elseif isnumeric(this) && isa(that, 'ascgrid')
                res = ascgrid(this ./ that.data, that.hdr);
            elseif isa(this, 'ascgrid') && isa(that, 'ascgrid')
                if isequaln(this.hdr, that.hdr)
                    res = ascgrid(this.data ./ that.data, this.hdr);
                else
                    error('Both ascgrid instances must have equivalent spatial references');
                end
            else
                error(['Arithmetic operations not defined for ', ...
                       class(this), ' and ', class(that)]);
            end
        end

        function res = mpower(this, that)
            if isa(this, 'ascgrid') && isnumeric(that)
                res = ascgrid(this.data.^that, this.hdr);
            else
                error(['mpower not defined for ', ...
                       class(this), ' raised to ', class(that)]);
            end
        end

        function tf = eq(this, that)
            if ~isa(this, 'ascgrid') || ~isa(that, 'ascgrid')
                error('Equality operations only defined with other instances of ascgrid');
            end
            tf = all(this.data(:) == that.data(:)) && isequaln(this.hdr, that.hdr);
        end

        function tf = neq(this, that)
            if ~isa(this, 'ascgrid') || ~isa(that, 'ascgrid')
                error('Equality operations only defined with other instances of ascgrid');
            end
            tf = any(this.data(:) ~= that.data(:)) || ~isequaln(this.hdr, that.hdr);
        end

        function tf = lt(this, that)
            error(['Comparison not defined for type ', class(this)]);
        end

        function tf = gt(this, that)
            error(['Comparison not defined for type ', class(this)]);
        end

        function tf = le(this, that)
            error(['Comparison not defined for type ', class(this)]);
        end

        function tf = ge(this, that)
            error(['Comparison not defined for type ', class(this)]);
        end

    end

    methods

        function this = ascgrid(varargin)
            if length(varargin) == 1
                fnm = varargin{1};
                [Z, hdr] = ascread(fnm);
                this.data = Z;
                this.hdr = hdr;

            elseif length(varargin) == 2
                this.data = varargin{1};
                this.hdr = varargin{2};

            else
                error(['Constructor arguments must be either a valid ', ...
                       'filename or a data array and a valid header struct']);
            end

            if ~check_hdr(this)
                error('Invalid header')
            end
            fullheader(this);
            this.data(this.data==this.hdr.nodata_value) = nan;

        end

        function tf = check_hdr(this)
            % Test that the header contains all required fields
            tf = all([isfield(this, 'ncols'), ...
                      isfield(this, 'nrows'), ...
                      isfield(this, 'xllcenter'), ...
                      isfield(this, 'yllcenter'), ...
                      isfield(this, 'cellsize'), ...
                      isfield(this, 'nodata_value')]);
            tf = 1;
        end

        function A = asmatrix(this)
            % Return data as a matrix
            A = this.data;
        end

        function hdr = getheader(this)
            % Return geographical header information
            hdr = this.hdr;
        end

        function [X, Y] = coordmesh(this)
            % Return X and Y coordinate matrices
            [x0, y0, nx, ny, d] = geo(this);
            x = x0:d:(nx-1)*d+x0;
            y = (ny-1)*d+y0:-d:y0;
            [X, Y] = meshgrid(x, y);
            if nargout == 1
                X = cat(3, X, Y);
            end
        end

        %% Query functions

        function [a, b] = size(this)
            sz = size(this.data);
            if nargout > 1
                a = sz(1);
                b = sz(2);
            else
                a = sz;
            end
        end

        function a = min(this)
            a = min(this.data(this.data~=this.hdr.nodata_value));
        end

        function a = max(this)
            a = max(this.data(this.data~=this.hdr.nodata_value));
        end

        function a = minmax(this)
            a = [min(this), max(this)];
        end

        function reg = getregion(this)
            % Return region extents (xmin, xmax, ymin, ymax)
            [x0, y0, nx, ny, d] = geo(this);
            reg = [x0, x0 + d*(nx-1), y0, y0 + d*(ny-1)];
        end

        function [yi, xi] = getindices(this, x, y)
            % Return the indices in ascgrid nearest to the provided x,y coordinates
            [x0, y0, nx, ny, d] = geo(this);
            xi = round((x - x0) / d) + 1;
            yi = round((y - y0) / d) + 1;
            xi(xi<1) = 1;
            xi(xi>nx) = nx;
            yi(yi<1) = 1;
            yi(yi>ny) = ny;
            if nargout == 1
                yi = [yi, xi];
            end
        end

        function z = sample(this, x, y)
            [i, j] = getindices(this, x, y);
            z = this.data(i, j);
        end

        function q = profile(varargin)
            error('Not implemented');
        end

        %% Processing functions

        function clip(this, zmin, zmax)
            % Clip data extents in-place
            this.data(this.data<zmin) = zmin;
            this.data(this.data>zmax) = zmax;
        end

        function resample(this, dnew)
            % Resample data to a new cellsize
            [X, Y] = coordmesh(this);
            Xi = X(1):dnew:X(end);
            Yi = Y(1):-dnew:Y(end);
            [Xi, Yi] = meshgrid(Xi, Yi);
            this.data = interp2(X, Y, this.data, Xi, Yi);
            [ny, nx] = size(this.data);
            this.hdr.nrows = ny;
            this.hdr.ncols = nx;
            this.hdr.cellsize = dnew;
        end

        function resize(this, te)
            % Resize data to new extents (xmin, xmax, ymin, ymax)
            [X, Y] = coordmesh(this);
            d = this.hdr.cellsize;
            Xi = te(1):d:te(2);
            Yi = te(3):d:te(4);
            [Xi, Yi] = meshgrid(Xi, Yi);
            this.data = interp2(X, Y, this.data, Xi, Yi, 'linear', nan);
            [ny, nx] = size(this.data);
            this.hdr.nrows = ny;
            this.hdr.ncols = nx;
            this.hdr.xllcenter = te(1);
            this.hdr.yllcenter = te(3);
            fullheader(this)
        end

        %% Analysis functions

        function m = slope(this)
            % Return the slope |(Ddx, Ddy)|
            d = this.hdr.cellsize;
            [Ddx, Ddy] = gradient(this);
            m = sqrt(Ddx.^2 + Ddy.^2);
        end

        function [Ddx, Ddy] = gradient(this)
            % Calculate gradient vectors (dv/dx, dv/dy)
            d = this.hdr.cellsize;
            Z = this.data;
            Ddx = ((2 * Z(2:end-1, 3:end) + Z(1:end-2, 3:end) + Z(3:end, 3:end)) - ...
                   (2 * Z(2:end-1, 1:end-2) + Z(1:end-2, 1:end-2) + Z(3:end, 1:end-2))) / ...
                   (8.0 * d);
            Ddy = ((2 * Z(3:end, 2:end-1) + Z(3:end, 3:end) + Z(3:end,1:end-2)) - ...
                   (2 * Z(1:end-2, 2:end-1) + Z(1:end-2, 1:end-2) + Z(1:end-2, 3:end))) / ...
                   (8.0 * d);

            %% Upper edge
            %Ddx = [((2 * Z(1, 3:end) + Z(2, 3:end)) - ...
            %        (2 * Z(1, 1:end-2) + Z(2, 1:end-2))) / (6.0 * d);
            %       Ddx];
            %Ddy = [((2 * Z(2, 2:end-1) + Z(2, 1:end-2) + Z(2, 3:end)) - ...
            %        (2 * Z(1, 1:end-1) + Z(1, 1:end-2) + Z(1, 3:end))) / ...
            %        (4.0 * d);
            %       Ddy];

            %% Lower edge
            %Ddx = [Ddx;
            %       ((2 * Z(end, 3:end) + Z(end-1, 3:end)) - ...
            %        (2 * Z(end, 1:end-2) + Z(end-1, 1:end-2))) / (6.0 * d)];
            %Ddy = [Ddy;
            %       ((2 * Z(end, 2:end-1) + Z(end, 1:end-2) + Z(end, 3:end)) - ...
            %        (2 * Z(end-1, 1:end-1) + Z(end-1, 1:end-2) + Z(end-1, 3:end))) / ...
            %        (4.0 * d)];

            %% Left edge
            %Ddx = [((2 * Z(2:end-1, 2) + Z(1:end-2, 2) + Z(3:end, 2)) - ...
            %        (2 * Z(2:end-1, 1) + Z(1:end-2, 1) + Z(3:end, 1))) / ...
            %        (4.0 * d),
            %       Ddx];
            %Ddy = [((2 * Z(

            %       Ddy];

            %% Right edge
            %Ddx = [Ddx,
            %       ((2 * Z(2:end-1, end) + Z(1:end-2, end) + Z(3:end, end)) - ...
            %        (2 * Z(2:end-1, end-1) + Z(1:end-2, end-1) + Z(3:end, end-1))) / ...
            %        (4.0 * d)];
            Ddx = pad(Ddx, 0);
            Ddy = pad(Ddy, 0);

            if nargout == 1
                Ddx = cat(3, Ddx, Ddy);
            end
        end

        function asp = aspect(this)
            % Return slope aspect
            [Ddx, Ddy] = gradient(this);
            asp = atan2(Ddy, -Ddx);
        end

        function uagrid = upstream(this)
            R = dem_flow(this.data);
            T = flow_matrix(this.data, R);
            UA = upslope_area(this.data, T);
            uagrid = ascgrid(UA, this.hdr);
        end

        % Plotting functions
        function [vargout] = contour(varargin)
            this = varargin{1};
            [X, Y] = coordmesh(this);
            [c, h] = contour(X, Y, this.data, varargin{2:end});
            if nargout >= 1
                vargout{1} = c;
                if nargout == 2
                    vargout{2} = h;
                end
            end
        end

        function [vargout] = contourf(varargin)
            this = varargin{1};
            [X, Y] = coordmesh(this);
            [c, h] = contourf(X, Y, this.data, varargin{2:end});
            if nargout >= 1
                vargout{1} = c;
                if nargout == 2
                    vargout{2} = h;
                end
            end
        end

        function [vargout] = surf(varargin)
            this = varargin{1};
            [X, Y] = coordmesh(this);
            h = surf(X, Y, this.data, 'EdgeColor', 'none', varargin{2:end});
            if nargout == 1
                vargout{1} = h;
            end
        end

        function [vargout] = pcolor(varargin)
            this = varargin{1};
            [X, Y] = coordmesh(this);
            h = pcolor(X, Y, this.data);
            shading interp
            if nargout == 1
                vargout{1} = h;
            end
        end

        function [vargout] = imshow(varargin)
            this = varargin{1};
            [X, Y] = coordmesh(this);
            h = imshow(this.data, [], 'XData', [X(1) X(end)], ...
                                      'YData', [Y(end) Y(1)]);
            if nargout == 1
                vargout{1} = h;
            end
        end


        % File IO

        function status = tofile(this, fnm)
            % Write to ESRI ASCII grid file
            status = ascwrite(this.data, this.hdr, fnm);
        end

    end

end
