function [surface,quality] = tracker_threshold(data,surf)
% surface = tracker_threshold(data,surf)
%
% data = Nt by Nx 2D matrix of nonnegative linear power values
% surf = structure controlling operating of the tracker
%  .data_noise: matrix the same size as data, if specified, this matrix
%    rather than data will be used to estimate the noise
%  .threshold_noise_rng: [0 -inf -1];
%    Specifies the region relative to the initial surface to estimate the
%    noise power from. It is a 1 by 3 integer array.
%    first element: All data points that are zero at the beginning of the
%      record will be ignored in the noise calculation. This specifies a
%      buffer beyond this in sample bins that will also be ignored.
%    second and third elements: Specifies a range of bins relative to the
%      max bin that will be used to estimate the noise (usually these
%      are negative such as [-50 -10] so that the noise estimate uses data
%      before the peak).
%  .threshold_noise_dB: double scalar, use this value for the noise estimate
%     rather than the value estimated from threshold_noise_rng
%  .threshold = double scalar, relative threshold above noise estimate
%    in log10 scale. Default is 17.
%  .threshold_rel_max = negative double scalar, relative threshold below
%    max of valid bins in dB scale. Default is NaN (i.e. threshold not used).
%  .threshold_rng: threshold for a given range line uses this range of
%     range values around the current range line to estimate the threshold.
%     Set to inf to include all range lines in estimate. Default is inf.
%  .dem = initial dem (used in estimate noise)
%  .init.max_diff = maximum deviation of the surface from surf.dem in
%    range bins), set to inf to not have a limit
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
if ~isfield(surf,'data_noise') || isempty(surf.data_noise)
  surf.data_noise = data;
end
if ~isfield(surf,'threshold') || isempty(surf.threshold)
  surf.threshold = 17;
end
if ~isfield(surf,'threshold_noise_dB') || isempty(surf.threshold_noise_dB)
  surf.threshold_noise_dB = [];
end
if ~isfield(surf,'threshold_noise_rng') || isempty(surf.threshold_noise_rng)
  surf.threshold_noise_rng = [0 -inf -1];
end
if ~isfield(surf,'threshold_rel_max') || isempty(surf.threshold_rel_max)
  % Threshold for each range line is the maximum of 1. the threshold found
  % from the noise estimate+threshold and 2. the maximum value plus this
  % relative amount. Default is -inf so that the max value threshold is not
  % used.
  surf.threshold_rel_max = NaN;
end
if ~isfield(surf,'threshold_rng') || isempty(surf.threshold_rng)
  surf.threshold_rng = inf;
end
surf.dem = round(surf.dem);

%% Determine the threshold value using range bins specified by noise_rng
median_data = nan(1,size(data,2));
for rline=1:size(data,2)
  % Remove range bins that are zero (this should no longer 
  good_mask = surf.data_noise(:,rline) ~= 0;
  % Remove range bins at start and end of record
  good_mask(1:min(length(good_mask),find(good_mask,1)-1+surf.threshold_noise_rng(1))) = 0;
  good_mask(max(1,find(good_mask,1,'last')+1-surf.threshold_noise_rng(1)):end) = 0;
  % Grab the specified range of bins
  good_mask(1:min(length(good_mask),max(0,surf.dem(rline)+surf.threshold_noise_rng(2)))) = 0;
  good_mask(max(1,surf.dem(rline)+surf.threshold_noise_rng(3)):end) = 0;
  if any(good_mask)
    median_data(rline) = nanmedian(surf.data_noise(good_mask,rline));
  end
end

if 0
  % Sample CFAR Detector Code
  surf.threshold_noise_rng(2) = min(0,surf.threshold_noise_rng(2));
  surf.threshold_noise_rng(3) = min(0,max(surf.threshold_noise_rng(2:3)));
  B = ones(1,-surf.threshold_noise_rng(2));
  B(surf.threshold_noise_rng(3)-surf.threshold_noise_rng(2)+1:end) = 0;
  B = B./sum(B);
  Bcenter = [B zeros(1,length(B)+1)];
  data_cfar = 10*log10(nan_fir_dec(10.^(data/10).',Bcenter,1).');
  for rline = 1:size(data,2)
    mask = data(:,rline)-max(data(:,rline)) < surf.threshold_rel_max;
    data(mask,rline) = nan;
  end
  
  if 0
    % Debug
    figure(1); clf; colormap(1-gray(256));
    imagesc(data);
    h_axes = gca;
    figure(2); clf; colormap(1-gray(256));
    imagesc(data_cfar);
    h_axes(end+1) = gca;
    figure(3); clf; colormap(1-gray(256));
    h_image = imagesc(data > data_cfar+surf.threshold);
    h_axes(end+1) = gca;
    linkaxes(h_axes);
    if 0
      for threshold = 5:30
        surf.threshold = threshold;
        threshold
        set(h_image,'CData',data > data_cfar+surf.threshold);
        pause
      end
    end
  end
end

% median_data: Noise estimate for each range line
% surf.threshold_noise_dB: Hard coded noise value
% surf.threshold: Threshold in dB above the noise estimate
% surf.threshold_rng: +/- range lines to use in the noise estimate for a
%   particular range line (this is useful if the noise estimates are noisy)
% surf.threshold_rel_max: Threshold in dB below the maximum value in the
%   rbin range
if isempty(surf.threshold_noise_dB) && all(isnan(median_data)) && surf.threshold_rel_max == -inf 
  warning('Insufficient information to generate threshold since all values are zero.');
  surface = surf.dem;
  return
end
if surf.threshold_rng == inf
  all_median_data = nanmedian(median_data);
end

%% Perform thresholding
surface = NaN*zeros(1,size(data,2));
quality = 3*ones(1,size(data,2));
for rline=1:size(data,2)
  rbins = max(1,round(surf.dem(rline) - surf.init.max_diff)) : min(size(data,1),round(surf.dem(rline) + surf.init.max_diff));

  if ~isempty(surf.threshold_noise_dB)
    threshold_rline = surf.threshold_noise_dB;
  elseif surf.threshold_rng == inf
    threshold_rline = all_median_data + surf.threshold;
  else
    threshold_rline = surf.threshold + ...
      nanmedian(median_data( max(1,rline-surf.threshold_rng) : min(length(median_data),rline+surf.threshold_rng) ));
  end
  threshold_rline = max(threshold_rline,max(data(rbins,rline))+surf.threshold_rel_max);
  
  if 1
    thresh_bin = find(data(rbins,rline) > threshold_rline,1);
  else
    thresh_bin = find(data(rbins,rline) > data_cfar(rbins,rline)+surf.threshold,1);
  end
  if ~isempty(thresh_bin)
    quality(rline) = 1;
    surface(rline) = rbins(1) - 1 + thresh_bin;
  end
end

if 0
  % Debug plot
  figure(1); clf;
  imagesc(data);
  hold on;
  plot(surf.dem,'b');
  plot(find(quality==1), surface(quality==1),'g.','LineWidth',2);
  plot(find(quality==3), surface(quality==3),'r.','LineWidth',2);
  cc = caxis;
  colorbar;
  if THRESHOLD < cc(2)
    caxis([THRESHOLD THRESHOLD+3]);
  else
    title(sprintf('ERROR: no value in image is larger than THRESHOLD %g.', THRESHOLD));
  end
  colormap(1-gray(256));
  keyboard
end
