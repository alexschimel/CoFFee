function mosaic = CFF_finalize_mosaic(mosaic)
%CFF_FINALIZE_MOSAIC Finalize a mosaic
%
%   MOSAIC = CFF_FINALIZE_MOSAIC(MOSAIC) finalizes MOSAIC after all
%   accumulating with CFF_ADD_TO_MOSAIC is finished. The only thing it does
%   is set to NaN the grid cells that did not get filled during mosaicking.
%   See CFF_INIT_MOSAIC_V2 for explanations why it is needed.
%
%   See also CFF_MOSAIC_LINES, CFF_INIT_MOSAIC_V2, CFF_ADD_TO_MOSAIC

%   Copyright 2017-2022 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

mosaic.value(mosaic.weight == 0) = NaN;

end

