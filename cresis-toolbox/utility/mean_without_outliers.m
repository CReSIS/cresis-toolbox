function [m,mask] = mean_without_outliers(x, num_stddev, percent, dim)
% [m,mask] = mean_without_outliers(x, num_stddev, percent, dim)
%
% Finds the mean of x without outliers. Similar to Matlab's trimmean
%
% 1. Removes ~isfinite elements of x and elements defined by percent
% 2. Finds the median, uses this to calculate the standard deviation instead
% of the mean
% 3. Removes elements of x that are num_stddev standard deviations out from
% the median.
% 4. Finds the mean of the remaining elements
%
% x: array of values, operates on first non-singleton dimension, ~isfinite
%   are ignored
% percent: value from 0 to 1, this fraction of elements on top and bottom
%   will be removed, default is 0.1
% num_stddev: threhold to remove elements, number of standard deviations
%   about the median to remove elements, default is 1
%
% Examples:
%
% mean([1 1 1 1 2 2 2 3 3 3])
% x = [1 1 1 1 2 2 2 1000 3 3 3;1 1 1 1 2 2 2 1000 3 3 3];
% m = mean_without_outliers(x, 1, 0, 2)
% 
% x = [-20 1 1 1 1 2 2 2 1000 3 3 3;-20 1 1 1 1 2 2 2 1000 3 3 3];
% m = mean_without_outliers(x, 1, 0, 2)
% 
% x = [-20 1 1 1 1 2 2 2 1000 3 3 3;-20 1 1 1 1 2 2 2 1000 3 3 3];
% m = mean_without_outliers(x, 1, 0.2, 2)
% 
% x = [-20 1 1 1 1 2 2 2 1000 3 3 3;-20 1 1 1 1 2 2 2 1000 3 3 3].';
% [m,mask] = mean_without_outliers(x, 1, 0.2)
%
% Author: John Paden

%% Check Inputs
if ~exist('num_stddev','var')
  num_stddev = 2;
end

if ~exist('percent','var') || isempty(percent)
  percent = 0;
end

if isempty(x)
  m = NaN;
  return;
end

dims = size(x);
if ~exist('dim','var') || isempty(dim)
  dim = find(dims > 1,1);
end

%% Calculate mean without outliers

% Permute dimension to operate on to the first dimension
permute_idxs = 1:size(dims,2);
permute_idxs([1 dim]) = permute_idxs([dim 1]);
x = permute(x, permute_idxs);

% Remove ~isfinite values
x(~isfinite(x)) = NaN;

% Remove percent outliers
if percent ~= 0
  median_x = nanmedian(x,1);
  dist_median = abs(bsxfun(@minus,x,median_x)).^2;
  [~,dist_idxs] = sort(dist_median,1);
  for remaining_idxs = 1:numel(x)/size(x,1)
    x(dist_idxs(:,remaining_idxs) > round((1-percent)*size(x,1)),remaining_idxs) = NaN;
  end
end

% Remove standard deviation outliers
median_x = nanmedian(x,1);
x_zeromean = abs(bsxfun(@minus,x,median_x)).^2;
var_x = nanmean(x_zeromean,1);

x(bsxfun(@gt, x_zeromean, num_stddev^2 * var_x)) = NaN;

m = nanmean(x,1);
mask = ~isnan(x);

% Permute matrix back to original form
m = permute(m, permute_idxs);
mask = permute(mask, permute_idxs);

