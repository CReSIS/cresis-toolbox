function [surface,pnt] = tracker_snake_simple(data,surf)
% [surface,pnt] = tracker_snake_simple(data,surf)
%
% Pick a few (Ninit_pnts) points by finding the maximum value and then snake out from
% a subset (sort_inds) of the these initial points. The snake searches for max power pixels
% in the neighboring columns which do not differ by more than search_rng.
%
% data = Nt by Nx 2D matrix of nonnegative linear power values
% surf = structure controlling operating of the tracker
%  .min_bin = positive integer, the minimum range bin to search for the
%    max in;
%  .max_bin = positive integer, the maximum range bin to search for the
%    max in;
%  .search_rng = range of pixels to search for neighboring points when
%    snaking through the data
%  .Ninit_pnts = the number of initial points to use with the max method
%  .sort_ind = indices into the Ninit_pnts that will be used as the initial
%    points for the snake algorithm
%  .dem = 1 by Nx vector. Max search for column N is dem(N) +/- max_diff.
%    Default is empty and the column is searched.
%  .max_diff = used with .dem field
%
% surface = 1 by size(data,2) vector of range bins where the surface
%   was tracked at
%
% See also: get_heights.m, update_surface_with_tracker.m,
% tracker_snake_simple.m, tracker_max.m, tracker_threshold.m
%
% Author: John Paden

if ~exist('surf','var')
  surf = struct();
end
if ~isfield(surf,'min_bin') || isempty(surf.min_bin)
  surf.min_bin = ones(1,size(data,2));
end
surf.min_bin(~isfinite(surf.min_bin)) = 1;
if ~isfield(surf,'max_bin') || isempty(surf.max_bin)
  surf.max_bin = size(data,1)*ones(1,size(data,2));
end
surf.max_bin(~isfinite(surf.max_bin)) = size(data,1);

if ~isfield(surf,'search_rng')
  surf.search_rng = -1:1;
end
if ~isfield(surf,'Ninit_pnts')
  surf.Ninit_pnts = 15;
end
if ~isfield(surf,'sort_ind')
  surf.sort_ind = 3;
end
if ~isfield(surf,'dem')
  % Constrain maximum search with this expected surface
  surf.dem = [];
end
if ~isfield(surf,'max_diff')
  % Maximum difference from dem, field is not used if dem is empty
  surf.max_diff = inf;
end

% Set initial point
%  - Look at the maximum along Ninit_pnts equally spaced range lines
%    and choose the sort_ind bin. The range line and corresponding
%    bin become the initial point.
Ninit_pnts = surf.Ninit_pnts;
sort_ind = surf.sort_ind;
start_idxs = unique(round(size(data,2) * linspace(0.2,0.8,Ninit_pnts)));
surface = zeros(1,size(data,2));
if isfield(surf,'dem') && any(isfinite(surf.dem))
  dem_low = round(surf.dem - surf.max_diff);
  dem_low(dem_low < 1) = 1;
  dem_low(dem_low > size(data,1)) = size(data,1);
  dem_high = round(surf.dem + surf.max_diff);
  dem_high(dem_high < 1) = 1;
  dem_high(dem_high > size(data,1)) = size(data,1);
  for idx=1:length(start_idxs)
    rline = start_idxs(idx);
    [tmp surfBins_init(idx)] = max(data(dem_low(rline):dem_high(rline),rline));
    surfBins_init(idx) = surfBins_init(idx) + dem_low(rline) - 1;
  end
else
  [tmp surfBins_init] = max(data(surf.min_bin:surf.max_bin,start_idxs));
  surfBins_init = surfBins_init + surf.min_bin - 1;
end
[tmp surfBins_init_sort_ind] = sort(surfBins_init);
startInd = start_idxs(surfBins_init_sort_ind(sort_ind));
surface(startInd) = surfBins_init(surfBins_init_sort_ind(sort_ind));
for idx = 1:length(startInd)
  pnt(idx).col = startInd(idx);
  pnt(idx).row = surface(startInd(idx));
  pnt(idx).method = 's';
end

% Automated: find remaining points (snake method)
searchRng = surf.search_rng; % Must be centered on zero, as in -X to X
done = zeros(1,size(data,2));
for pntInd = 1:length(pnt)
  done(pnt(pntInd).col) = 1;
  surface(pnt(pntInd).col) = pnt(pntInd).row;
end
while sum(done) ~= length(done)
  for line = 1:length(done)
    if done(line) == 0
      if line < length(done) && done(line+1) == 1
        done(line) = 1;
        tmpSearchRng = searchRng(1+max(0,1-(surface(line+1)+searchRng(1))) : ...
          end-max(0,searchRng(end)-size(data,1)+surface(line+1)));
        [tmp newBin] = max(data(surface(line+1)+tmpSearchRng,line));
        surface(line) = surface(line+1)+tmpSearchRng(1)-1 + newBin;
      end
      if line > 1 && done(line-1) == 1
        done(line) = 1;
        tmpSearchRng = searchRng(1+max(0,1-(surface(line-1)+searchRng(1))) : ...
          end-max(0,searchRng(end)-size(data,1)+surface(line-1)));
        [tmp newBin] = max(data(surface(line-1)+tmpSearchRng,line));
        surface(line) = surface(line-1)+tmpSearchRng(1)-1 + newBin;
      end
    end
  end
end

if 0
  % Debug plot
  figure(1); clf;
  imagesc(lp(data));
  hold on;
  plot(surface,'b');
  ylims = [min(surface) max(surface)];
  ylims = ylims + diff(ylims)*[-0.1 0.1];
  try
    ylim(ylims)
  end
  colormap(1-gray(256));
end

end
