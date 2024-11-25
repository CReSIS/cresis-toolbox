% script delete_pnts_outside_view
%
% Fixes database based on imb.picker bug.  Generally should only have
% to be run once, but there is no harm in running multiple times.
%
% Since images may have different pixel start/stop because of processing
% parameters, it is possible to have layer information defined outside
% the image area.
%
% A new modification to the picker allows these pixels to be seen, but
% previous to that, these pixels could not be seen. This script deletes
% all of those prevously-unseen points since many are in error.
%
% Removes surface and bottom layers.

params = read_param_xls(ct_filename_param('rds_param_2009_Greenland_TO.xls'),'','post');

% Surface and bottom layers
for param_idx = 1:length(params)
  param = params(param_idx);
  if ~isfield(param.cmd,'generic') || iscell(param.cmd.generic) || ischar(param.cmd.generic) || ~param.cmd.generic
    continue;
  end
  fprintf('delete_pnts_outside_view %s\n', param.day_seg);
  
  frames = frames_load(param);

  layers = {'surface','bottom'};
  for layer = layers
    layer = layer{1};
    % Open first MVDR frame
    data_fn = fullfile(ct_filename_out(param,'mvdr',''), ...
      sprintf('Data_%s_001.mat', param.day_seg))
    tmp = load(data_fn,'GPS_time');
    
    % Get the points before the first echogram range line
    ops_param = struct('properties',[]);
    ops_param.properties.location = param.post.ops.location;
    ops_param.properties.season = param.season_name;
    ops_param.properties.segment = param.day_seg;
    ops_param.properties.start_gps_time = tmp.GPS_time(1)-100;
    ops_param.properties.stop_gps_time = tmp.GPS_time(1)-0.00001;
    ops_param.properties.lyr_name = layer;
    [status,data] = opsGetLayerPoints(sys,ops_param);
    
    % Delete these points
    num_points_to_delete = numel(data.properties.point_path_id);
    fprintf('  Deleting %d points at start\n', num_points_to_delete);
    if num_points_to_delete > 5
      % Unexpected to have so many
      keyboard
    end
    if num_points_to_delete > 0
      data.properties.point_path_id
      ops_param = struct('properties',[]);
      ops_param.properties.season = param.season_name;
      ops_param.properties.segment = param.day_seg;
      ops_param.properties.start_point_path_id = min(data.properties.point_path_id);
      ops_param.properties.stop_point_path_id = max(data.properties.point_path_id);
      ops_param.properties.min_twtt = -100.1;
      ops_param.properties.max_twtt = 5000.1;
      ops_param.properties.lyr_name = layer;
      [status,message] = opsDeleteLayerPoints(sys,ops_param);
    end
    
    % Open last frame
    data_fn = fullfile(ct_filename_out(param,'mvdr',''), ...
      sprintf('Data_%s_%03d.mat', param.day_seg, length(frames.frame_idxs)))
    tmp = load(data_fn,'GPS_time');
    
    % Get the points before the last echogram range line
    ops_param = struct('properties',[]);
    ops_param.properties.location = param.post.ops.location;
    ops_param.properties.season = param.season_name;
    ops_param.properties.segment = param.day_seg;
    ops_param.properties.start_gps_time = tmp.GPS_time(end)+0.00001;
    ops_param.properties.stop_gps_time = tmp.GPS_time(end)+100;
    ops_param.properties.lyr_name = layer;
    [status,data] = opsGetLayerPoints(sys,ops_param);
    
    % Delete these points
    num_points_to_delete = numel(data.properties.point_path_id);
    fprintf('  Deleting %d points at end\n', num_points_to_delete);
    if num_points_to_delete > 5
      % Unexpected to have so many
      keyboard
    end
    if num_points_to_delete > 0
      data.properties.point_path_id
      ops_param = struct('properties',[]);
      ops_param.properties.season = param.season_name;
      ops_param.properties.segment = param.day_seg;
      ops_param.properties.start_point_path_id = min(data.properties.point_path_id);
      ops_param.properties.stop_point_path_id = max(data.properties.point_path_id);
      ops_param.properties.min_twtt = -100.1;
      ops_param.properties.max_twtt = 5000.1;
      ops_param.properties.lyr_name = layer;
      [status,message] = opsDeleteLayerPoints(sys,ops_param);
    end
  end

end

