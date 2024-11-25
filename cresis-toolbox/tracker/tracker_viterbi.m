function labels = tracker_viterbi(data,track)
% labels = tracker_viterbi(data,track)
%

gt = [track.crossovers track.ground_truths];
physical_constants;

transition_weight = track.viterbi.transition_weight;

along_track_slope = zeros(1, size(data, 2) - 1);

upper_bounds = track.min_bin;
lower_bounds = track.max_bin;
upper_bounds(gt(1, :)) = gt(2, :) - gt(3, :);
lower_bounds(gt(1, :)) = gt(2, :) + gt(3, :);

upper_bounds = round(upper_bounds);
lower_bounds = round(lower_bounds);
lower_bounds(~track.ice_mask) = round(track.dem(~track.ice_mask));
upper_bounds(~track.ice_mask) = round(track.dem(~track.ice_mask));
upper_bounds(upper_bounds < 1 | ~isfinite(upper_bounds)) = 1;
upper_bounds(upper_bounds > size(data, 1)) = 1;
lower_bounds(lower_bounds > size(data, 1) | ~isfinite(lower_bounds)) = size(data, 1);
lower_bounds(lower_bounds < 1) = 1;

% Set nonfinite values to a very low value. If this is not done and the
% bounds force the path through an area with nonfinite values, viterbi fails
min_data = min(data(:));
max_data = max(data(:));
data(~isfinite(data)) = min_data - 100*(max_data-min_data);

if 0
  %% Debug Plot
  figure;
  clf;
  imagesc(data);
  hold on
  plot(upper_bounds,'k-');
  plot(lower_bounds,'k-');
  % plot(labels,'k.');
end

labels = tomo.viterbi2(single(data), along_track_slope, transition_weight, ...
                       upper_bounds, lower_bounds);
