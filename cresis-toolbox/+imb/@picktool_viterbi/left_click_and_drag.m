function cmds = left_click_and_drag(obj,param)
% cmds = left_click_and_drag(obj,param)
%
% Detect tool
%
% Compile with
%   mex -largeArrayDims viterbi.cpp

physical_constants;

image_x = param.image_x;
image_y = param.image_y;
image_c = param.image_c;
cur_layers = param.cur_layers;
x = param.x;
y = param.y;
cmds = [];

fprintf('Performing viterbi tracking on points %f to %f, %f to %f\n', x, y);

param.x_bounds = 3;
param.y_bounds = 1;

for layer_idx = 1:length(cur_layers)
  cur_layer = cur_layers(layer_idx);
  
  param.x_bounds = 1;
  [all_gt_idxs,~,~] = find_matching_pnts(obj,param,cur_layer);
  
  % Nx: number of along track records/range lines
  Nx = length(image_x);
  
  % Match GT points with axis coordinates
  gt = [interp1(image_x, 1:length(image_x),param.layer.x(all_gt_idxs), 'nearest', 'extrap');
    interp1(image_y, 1:length(image_y),param.layer.y{cur_layer}(all_gt_idxs), 'nearest', 'extrap')];
  x_points       = gt(1, :);
  y_points       = gt(2, :);
  gt             = nan(1, Nx);
  gt(x_points)   = y_points;
  gt_idxs = find(~isnan(gt));

  % Echogram Parameters
  viterbi_data   = image_c;
  
  % Get values from picktool params
  n = cur_layer;  % Used in top/bottom layer eval
  try
    top_layer_num = eval(obj.top_panel.top_layer_TE.String);
  catch ME
    top_layer_num = NaN;
    warning('Could not evaluate Viterbi top layer input. Defaulting to %.0f.', top_layer_num);
  end
  try
    bottom_layer_num = eval(obj.top_panel.bottom_layer_TE.String);
  catch ME
    bottom_layer_num = NaN;
    warning('Could not evaluate Viterbi bottom layer input. Defaulting to %.0f.', bottom_layer_num);
  end
  try
    along_track_weight = eval(obj.top_panel.along_track_weight_TE.String);
  catch ME
    along_track_weight = 1;
    warning('Could not evaluate Viterbi along track weight input. Defaulting to %.2f.', along_track_weight);
  end
  try
    gt_cutoff = eval(obj.top_panel.ground_truth_cutoff_TE.String);
  catch ME
    gt_cutoff = 5;
    warning('Could not evaluate Viterbi groundtruth cutoff input. Defaulting to %.0f.', gt_cutoff);
  end
  try
    layer_guard = eval(obj.top_panel.layer_guard_TE.String);
  catch ME
    layer_guard = 2;
    warning('Could not evaluate Viterbi layer_guard input. Defaulting to %.0f.', layer_guard);
  end
  clear n;
  
  vert_bound_selection = obj.top_panel.vert_bound_PM.Value;
  vert_bound_selection = obj.top_panel.vert_bound_PM.String{vert_bound_selection};

  layers = [top_layer_num bottom_layer_num];
  layers_bins = nan(length(layers),length(image_x));
  for layers_idx = 1:length(layers)
    layer_num = layers(layers_idx);
    if isnan(layer_num)
      continue
    end
    if (layer_num > length(param.layer.y) || layer_num < 1)
      if strcmp(vert_bound_selection, 'Layers')
        warning('Layer %.0f not found. Defaulting to echogram bound.', layer_num);
      end
      continue;
    end
    layers_bins(layers_idx, :) = interp_layer(param.layer.y{layer_num}, param.layer.x, image_x, image_y);
  end
  
  % Get Vertical Bounds
  %   upper_bounds: nearest row to radar
  %   lower_bounds: furthest row from radar
  %   upper_bounds <= lower_bounds or an error will occur in c++ call
  if strcmp(vert_bound_selection, 'Entire Echogram')
    upper_bounds = ones(1, Nx);
    lower_bounds = ones(1, Nx)*length(image_y);
  elseif strcmp(vert_bound_selection, 'Selection Box')
    upper_bounds = ones(1, Nx)*interp1(image_y, 1:length(image_y),param.y(1), 'nearest', 'extrap');
    lower_bounds = ones(1, Nx)*interp1(image_y, 1:length(image_y),param.y(2), 'nearest', 'extrap');
    % Sort upper and lower bounds
    if upper_bounds(1) > lower_bounds(1)
      temp_bounds = lower_bounds;
      lower_bounds = upper_bounds;
      upper_bounds = temp_bounds;
      clear temp_bounds;
    end
  elseif strcmp(vert_bound_selection, 'Layers')
    upper_bounds = layers_bins(1, :) + layer_guard;
    lower_bounds = layers_bins(2, :) - layer_guard;

    % Handle overlapped bounds
    half_bounds = round((upper_bounds + lower_bounds) / 2);
    invalid_mask = upper_bounds > lower_bounds;
    upper_bounds(invalid_mask) = half_bounds(invalid_mask);
    lower_bounds(invalid_mask) = half_bounds(invalid_mask);
  end
  
  % Get horizontal bounds
  hori_bound_selection = obj.top_panel.hori_bound_PM.Value;
  hori_bound_selection = obj.top_panel.hori_bound_PM.String{hori_bound_selection};
  if strcmp(hori_bound_selection, 'Entire Echogram')
    % Image points
    hori_bounds = [1 Nx];
    % Layer points
    hori_layer_idxs = 1:length(param.layer.x);
  elseif strcmp(hori_bound_selection, 'Selection Box')
    % Image points
    hori_bounds = interp1(image_x, 1:length(image_x),param.x, 'nearest', 'extrap');
    % Layer points
    hori_layer_idxs = find(param.layer.x >= param.x(1) & param.layer.x <= param.x(2));
  elseif strcmp(hori_bound_selection, 'Extreme Groundtruth')
    % Image points
    selected_gt_idxs = gt_idxs(gt_idxs >= param.x(1) & gt_idxs <= param.x(2));
    if length(selected_gt_idxs) < 2
      warning('At least two ground truth points must be selected when horizontal bounding option is set to track between the "extreme gt points". Cancelling.');
      return;
    end
    hori_bounds = selected_gt_idxs([1 end]);
    % Layer points
    hori_layer_idxs = find(param.layer.x >= image_x(selected_gt_idxs(1)) & param.layer.x <= image_x(selected_gt_idxs(end)));
  end
  hori_bounds(1) = max(hori_bounds(1), 1);
  hori_bounds(end) = min(hori_bounds(end), Nx);

  bound_gt_idxs = gt_idxs(gt_idxs >= hori_bounds(1) & gt_idxs <= hori_bounds(end)); 
  if any(gt(bound_gt_idxs) < upper_bounds(bound_gt_idxs) | gt(bound_gt_idxs) > lower_bounds(bound_gt_idxs))
    warning('Groundtruth points outside vertical bounds. Cancelling.');
    return;
  end

  upper_bounds(gt_idxs) = max([gt(gt_idxs) - gt_cutoff; upper_bounds(gt_idxs)]);
  lower_bounds(gt_idxs) = min([gt(gt_idxs) + gt_cutoff; lower_bounds(gt_idxs)]);
  
  elevation = param.echowin.eg.elev;
  vel_air = c/2;
  vel_ice = c/(sqrt(er_ice)*2);
  dt = param.echo_time(2) - param.echo_time(1);
  along_track_slope = diff(elevation);
  
  yaxis_choice = get(param.echowin.left_panel.yaxisPM,'Value');
  if yaxis_choice == 1 % TWTT
    drange = dt * vel_air;
    along_track_slope = round(along_track_slope / drange);
  elseif yaxis_choice == 2 % WGS_84 Elevation
    drange = dt * vel_ice;
    along_track_slope = round(along_track_slope / drange);
  elseif yaxis_choice == 3 % Range
    drange = dt * vel_ice;
    along_track_slope = round(along_track_slope / drange);
  elseif yaxis_choice == 4 % Range bin
    drange = dt * vel_air;
    along_track_slope = round(along_track_slope / drange);
  elseif yaxis_choice == 5 % Surface flat
    drange = dt * vel_ice;
    along_track_slope(:) = 0;
  end
  
  % Crop input data to horizontal bounds
  viterbi_data = viterbi_data(:,hori_bounds(1):hori_bounds(end));
  along_track_slope = along_track_slope(:,hori_bounds(1):hori_bounds(end)-1);
  upper_bounds = upper_bounds(:,hori_bounds(1):hori_bounds(end));
  lower_bounds = lower_bounds(:,hori_bounds(1):hori_bounds(end));
  
  % Handle NaNs and negative or too large bounds
  upper_bounds(~isfinite(upper_bounds) | upper_bounds < 1) = 1;
  upper_bounds(upper_bounds > size(viterbi_data, 1)) = size(viterbi_data, 1);
  lower_bounds(lower_bounds < 1) = 1;
  lower_bounds(~isfinite(lower_bounds) | lower_bounds > size(viterbi_data, 1)) = size(viterbi_data, 1);
  
  % Echogram image normalization
  viterbi_data(~isfinite(viterbi_data)) = NaN;
  viterbi_data = echo_norm(viterbi_data,struct('scale',[-40 90]));
  viterbi_data(~isfinite(viterbi_data)) = -1e4;

  viterbi_timer = tic;
  y_new = tomo.viterbi2(single(viterbi_data), along_track_slope, along_track_weight, upper_bounds, lower_bounds);
  fprintf('Viterbi call took %.2f sec.\n', toc(viterbi_timer));
  
  bounding_idxs = hori_bounds(1):hori_bounds(end);
  
  % Resample and interpolate y_new to match layer axes
  y_new = interp1(1:length(image_y), image_y,y_new,'linear','extrap');
  y_new = interp1(image_x(bounding_idxs),y_new,param.layer.x(hori_layer_idxs),'linear', 'extrap');
  
  cmds(end+1).undo_cmd = 'insert';
  cmds(end).undo_args = {cur_layer, hori_layer_idxs, ...
    param.layer.y{cur_layer}(hori_layer_idxs), ...
    param.layer.type{cur_layer}(hori_layer_idxs), ...
    param.layer.qual{cur_layer}(hori_layer_idxs)};
  
  cmds(end).redo_cmd = 'insert';
  type = param.layer.type{cur_layer}(hori_layer_idxs);
  type(type ~= 1 | ~isfinite(param.layer.y{cur_layer}(hori_layer_idxs))) = 2; % Some day we will set different types based on the automated method used...
  cmds(end).redo_args = {cur_layer, hori_layer_idxs, y_new, ...
    type, param.cur_quality*ones(size(hori_layer_idxs))};
end

end

function new_layer_bins = interp_layer(layer, layer_x, image_x, image_y)
% Interpolate layer to match image x-axis coordinates
new_layer_bins = interp1(layer_x, layer, image_x, 'nearest');
% Interpolate layer y-axis units to image pixels
new_layer_bins = interp1(image_y, 1:length(image_y),new_layer_bins, 'nearest');
end
