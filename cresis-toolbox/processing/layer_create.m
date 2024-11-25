function layer_create(param,param_override)
% layer_create(param,param_override)
%
% The layer_create function performs one of three actions depending on the
% "update_mode" field:
% * It can be used to make layer files when they do not exist
% * It can be used to blank out layer information in layer files
% * It can be used to update GPS information in layer files (e.g. if the
% records file is updated with new GPS information with records_update.m)
%
% The layer files are used by the imb.picker.m program as well as the data
% processing.
%
% This function should be run from run_layer_create.m (that script sets up
% all the control variables).
%
% Author: John Paden
%
% See also: layer_create, run_layer_create

param = merge_structs(param,param_override);

dbstack_info = dbstack;
fprintf('=====================================================================\n');
fprintf('%s: %s (%s)\n', dbstack_info(1).name, param.day_seg, datestr(now,'HH:MM:SS'));
fprintf('=====================================================================\n');

%% Input Checks

if ~isfield(param.layer_file_make,'update_mode') || isempty(param.layer_file_make.update_mode)
  param.layer_file_make.update_mode = 0;
  % In all modes, if file does not exist, then a new file is created. If a
  % file exists, how it is updated is controlled by the update_mode field.
  % The update_mode field is a nonnegative integer scalar indicating:
  %
  % 0: no updates are made, layer file is created only if no layer file
  % exists or if there were problems with an existing layer file. This is
  % the default setting.
  %
  % 1: layer file is overwritten with new information (blank layer file)
  % and old layer data is lost
  %
  % 2: Old GPS time field is adjusted according to changes in
  % param.records.gps.time_offset and then the position and layer
  % information is reinterpolated from the old GPS time field to the new
  % GPS time field.
end

if ~isfield(param.layer_file_make,'out_path') || isempty(param.layer_file_make.out_path)
  param.layer_file_make.out_path = 'layer';
end

%% Make or update layer files
layers = layerdata(param,param.layer_file_make.out_path);
if param.layer_file_make.update_mode == 1
  if isempty(param.cmd.frms)
    layers.delete_all();
  else
    layers.delete_layer_file(param.cmd.frms);
  end
end
if param.layer_file_make.update_mode == 2
  layers.update_gps_all();
end
layers.check_all();
layer_names = layers.get_layer_names();
surface_idx = find(strcmp('surface',layer_names));
if isempty(surface_idx)
  layer_organizer.lyr_name = {'surface'};
  layer_organizer.lyr_group_name = {'standard'};
  layers.insert_layers(layer_organizer);
  layers.update_layer(1:length(layers.frames.frame_idxs),'surface',layers.frames.gps_time([1 end]),[NaN NaN]);
else
  obj.layer_organizer.lyr_group_name{surface_idx} = 'standard';
end
bottom_idx = find(strcmp('bottom',layer_names));
if isempty(bottom_idx)
  layer_organizer.lyr_name = {'bottom'};
  layer_organizer.lyr_group_name = {'standard'};
  layers.insert_layers(layer_organizer);
  layers.update_layer(1:length(layers.frames.frame_idxs),'bottom',layers.frames.gps_time([1 end]),[NaN NaN]);
else
  obj.layer_organizer.lyr_group_name{bottom_idx} = 'standard';
end
layers.save();
