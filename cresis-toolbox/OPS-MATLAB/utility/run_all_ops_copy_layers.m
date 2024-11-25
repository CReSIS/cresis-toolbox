% script runOpsCopyLayers.m
%
% Example script for running opsCopyLayers.m. Demonstrates a few of the
% most common operations to be performed with opsCopyLayers.
%
% Authors: John Paden

%% User Settings
% =========================================================================

% Select seasons in run_all:
run_all;

copy_param = [];
copy_param.layer_source.existence_check = false;
copy_param.layer_dest.existence_check = false;

% Set the layer name(s) for the source (e.g. 'surface', 'bottom', {'surface','bottom'})
copy_param.layer_source.name = {'surface'};

% Set the layer name(s) for the destination (e.g. 'surface', 'bottom', {'surface','bottom'})
copy_param.layer_dest.name = {'surface'};

% Set the source (choose one)
if 0
  copy_param.layer_source.source = 'ops';
elseif 0
  copy_param.layer_source.source = 'records';
elseif 1
  copy_param.layer_source.source = 'echogram';
  % Set the echogram source if using echogram
  if 1
    copy_param.layer_source.echogram_source = 'CSARP_post/qlook';
  elseif 0
    copy_param.layer_source.echogram_source = 'deconv';
  else
    copy_param.layer_source.echogram_source = 'standard';
  end
elseif 0
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
end

if 1
  copy_param.copy_method = 'overwrite';
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

% =====================================================================
%% Automated Section
% =====================================================================

global gRadar;

%% Loop to process each season
for param_idx = 1:length(param_fns)
  
  % Read in parameter spreadsheet
  param_fn = ct_filename_param(param_fns{param_idx});
  fprintf('Reading %s\n', param_fn);
  params = read_param_xls(param_fn,'');
  
  if isempty(params)
    continue;
  end
  
  % Run all segments (except "do not process")
  if 0
    params = ct_set_params(params,'cmd.generic',1);
    params = ct_set_params(params,'cmd.generic',0,'cmd.notes','do not process');
    params = ct_set_params(params,'cmd.generic',0,'day_seg','20120330_04');
  else
    % HACK!!!
    keyboard
%     params = ct_set_params(params,'cmd.generic',0);
%     params = ct_set_params(params,'cmd.generic',1,'day_seg','20120330_04');
    params = ct_set_params(params,'cmd.generic',1);
    params = ct_set_params(params,'cmd.generic',0,'cmd.notes','do not process');
    params = ct_set_params(params,'cmd.generic',0,'day_seg','20120330_04');
  end
  
  %% Process each segment
  for param_idx = 1:length(params)
    param = params(param_idx);
    
    if ~isfield(param.cmd,'generic') || iscell(param.cmd.generic) || ischar(param.cmd.generic) || ~param.cmd.generic
      fprintf('%s\tdo not process\n', param.day_seg);
      continue;
    end
    
    global gRadar;
    param = merge_structs(param,gRadar);
    
    try
      fprintf('opsCopyLayers %s (%s)\n', param.day_seg, datestr(now));
      opsCopyLayers(param,copy_param);
      fprintf('  Complete (%s)\n', datestr(now));
    catch ME
      fprintf('%s\terror!!!\t%s\n', param.day_seg, ME.getReport);
      continue;
    end
  end
end
