% script runOpsCopyLayers.m
%
% Example script for running opsCopyLayers.m. Demonstrates a few of the
% most common operations to be performed with opsCopyLayers.
%
% Authors: John Paden

% =====================================================================
%% User Settings
% =====================================================================

% Load the parameter spreadsheet 
params = read_param_xls(ct_filename_param('rds_param_2019_Antarctica_Ground.xls'));
params = ct_set_params(params,'cmd.generic',0);
params = ct_set_params(params,'cmd.generic',1,'day_seg','20200107_01');
params = ct_set_params(params,'cmd.frms',[1]);

% Set the operation to run (just choose one operation)
if 1
  % Use this option if copying to and from the same instrument (typical case)
  runOpsCopyLayers_operation = 'copy_layer';
else
  % Use this option if copying a layer from one instrument (e.g. rds) to another
  % instrument (e.g. snow).
  runOpsCopyLayers_operation = 'copy_layer_nonmatch_sys';
end

%% copy_layer: Copy layer from one location to another and optionally apply operation during copy
if strcmp(runOpsCopyLayers_operation,'copy_layer')
  copy_param = [];
  copy_param.layer_source.existence_check = false;
  copy_param.layer_dest.existence_check = false;

  % Set the layer name(s) for the source (e.g. 'surface', 'bottom', {'surface','bottom'})
  copy_param.layer_source.name = 'surface';
  
  % Set the layer name(s) for the destination (e.g. 'surface', 'bottom', {'surface','bottom'})
  copy_param.layer_dest.name = 'surface';

  % Set the source (choose one)
  if 0
    copy_param.layer_source.source = 'ops';
  elseif 0
    copy_param.layer_source.source = 'records';
  elseif 0
    copy_param.layer_source.source = 'echogram';
    % Set the echogram source if using echogram
    if 1
      copy_param.layer_source.echogram_source = 'qlook';
    elseif 0
      copy_param.layer_source.echogram_source = 'deconv';
    else
      copy_param.layer_source.echogram_source = 'standard';
    end
  elseif 1
    copy_param.layer_source.source = 'layerdata';
    copy_param.layer_source.layerdata_source = 'layer';
  elseif 0
    copy_param.layer_source.source = 'custom';
    copy_param.layer_source.gps_time = {[0 1e20]};
    copy_param.layer_source.twtt = {[1e-6 1e-6]};
    copy_param.layer_source.type = {[2 2]};
    copy_param.layer_source.quality = {[1 1]};
  else
    copy_param.layer_source.source = 'lidar';
    copy_param.layer_source.lidar_source = 'awi';
    copy_param.layer_source.lever_arm_en = true;
  end

  if 1
    copy_param.copy_method = 'overwrite'; % default
  elseif 0
    copy_param.copy_method = 'fillgaps';
  else
    copy_param.copy_method = 'merge';
  end
  
  if strcmpi(copy_param.layer_dest.name,'surface')
    copy_param.gaps_fill.method = 'interp_finite';
  else
    copy_param.gaps_fill.method = 'preserve_gaps';
    copy_param.gaps_fill.method_args = [40 20];
  end
  
  % Set the twtt offset (for positive offset layer shifts down)
  twtt_offset = 0e-6;
  
  % Set the GPS time offset (for positive offset layer shifts right)
  gps_time_offset = 0;
  
  if twtt_offset ~= 0 || gps_time_offset ~= 0
    warning('You have set a nonzero twtt_offset(%.12g) or gps_time_offset(%.3g). Normally these are both zero. Please verify that this is what you want to do before running "dbcont" to continue.\n', twtt_offset, gps_time_offset);
    keyboard
    copy_param.eval.cmd = sprintf('s = interp1(time+%.3g,s + %.12g,time);',gps_time_offset,twtt_offset);
  end
  
  % Set overwrite quality level (e.g. []: do not overwrite, 1: good, 2: medium, 3: bad)
  quality = [];
  if ~isempty(quality) && any(quality == [1 2 3])
    warning('You have set quality to %d. Normally it should be []. Please verify that you want to overwrite the quality level before running "dbcont" to continue.\n', quality);
    keyboard
    copy_param.quality.mode = 'overwrite';
    copy_param.quality.value = quality;
  end
  
  % Set the destination (choose one): it can be the same as the source
  if 0
    copy_param.layer_dest.source = 'ops';
  elseif 0
    copy_param.layer_dest.source = 'records';
  elseif 0
    copy_param.layer_dest.source = 'echogram';
    % Set the echogram source if using echogram
    if 1
      copy_param.layer_dest.echogram_source = 'qlook';
    elseif 0
      copy_param.layer_dest.echogram_source = 'deconv';
    else
      copy_param.layer_dest.echogram_source = 'standard';
    end
  elseif 1
    copy_param.layer_dest.source = 'layerdata';
    copy_param.layer_dest.layerdata_source = 'layer';
  end

  % Usually the group name is standard
  copy_param.layer_dest.group_name = 'standard';
  
end
%% Copy surface from mcords records to snow layerdata  
if strcmp(runOpsCopyLayers_operation,'copy_layer_nonmatch_sys')
  % Modify the code below to load the source layer information
  
  % Load mcords records data
  load_params = read_param_xls(ct_filename_param('rds_param_2015_Greenland_Polar6.xls'),'20150913.*','post');  
  layer_params = []; idx = 1;
  layer_params(idx).name = 'surface';
  layer_params(idx).source = 'records';
  global gRadar;
  gps_time = []; twtt = [];
  for param_idx = 1:length(load_params)
    param = load_params(param_idx);
    param = merge_structs(param,gRadar);
    layers = opsLoadLayers(param,layer_params);
    gps_time = [gps_time, layers.gps_time];
    twtt = [twtt, layers.twtt];
  end
  
  copy_param.layer_source.source = 'custom';
  copy_param.layer_source.gps_time = gps_time;
  copy_param.layer_source.twtt = twtt;
  
  copy_param.layer_dest.name = 'surface_rds';
  copy_param.layer_dest.source = 'layerdata';
  copy_param.layer_dest.layerdata_source = 'layerData';
  copy_param.layer_dest.existence_check = false;

  copy_param.copy_method = 'overwrite';
  copy_param.gaps_fill.method = 'interp_finite';

end

% =====================================================================
%% Automated Section
% =====================================================================

global gRadar;

% Input checking
if exist('param_override','var')
  param_override = merge_structs(gRadar,param_override);
else
  param_override = gRadar;
end

%% Copy layers for each of the enabled segments
failed_segments = [];
for param_idx = 1:length(params)
  param = params(param_idx);
  if ~isfield(param.cmd,'generic') || iscell(param.cmd.generic) || ischar(param.cmd.generic) || ~param.cmd.generic
    continue;
  end
  param = merge_structs(param,param_override);
  fprintf('opsCopyLayers %s from %s:%s to %s:%s (%s)\n', param.day_seg, copy_param.layer_source.source, copy_param.layer_source.name, copy_param.layer_dest.source, copy_param.layer_dest.name, datestr(now));
  try
    opsCopyLayers(param,copy_param);
  catch ME
    failed_segments(end+1).param_idx = param_idx;
    failed_segments(end).report = ME.getReport;
    failed_segments(end).message = ME.message;
    %keyboard
  end
  fprintf('  Complete (%s)\n', datestr(now));
end

for failed_idx = 1:length(failed_segments)
  fprintf('%s: %s\n', params(failed_segments(failed_idx).param_idx).day_seg, ...
    failed_segments(failed_idx).message);
end
