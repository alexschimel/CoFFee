function B = pad(varargin)
    % B = pad(A, padval, ...)
    %
    % Pad array with a padval. Additional argument indicate how far to pad
    % (default 1), either as
    %   B = pad(A, padval, top/bottom, left/right)
    % or
    %   B = pad(A, padval, top, bottom, left, right)
    %
    % Corners take the top/bottom value.
    %
    % Written by Nat Wilson

    if nargin == 2
        ll = 1;
        rr = 1;
        tt = 1;
        bb = 1;
    elseif nargin == 4
        tt = varargin{3};
        bb = varargin{3};
        ll = varargin{4};
        rr = varargin{4};
    elseif nargin == 6
        tt = varargin{3};
        bb = varargin{4};
        ll = varargin{5};
        rr = varargin{6};
    else
        error('Requires at least two arguments')
    end

    A = varargin{1};
    pv = varargin{2};

    [m, n] = size(A);

    B = [pv*ones(m, ll), A, pv*ones(m, rr)];
    B = [pv*ones(tt, n+ll+rr); B; pv*ones(bb, n+ll+rr)];

return
