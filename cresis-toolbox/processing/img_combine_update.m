function img_combine_update(param, param_override)
% img_combine_update(param, param_override)
%
% Function for running img_combine on echogram files. Works with
% get_heights and combine files.
%
% param = struct with processing parameters
%  .img_combine_update: struct with processing parameters
%   .mode: string containing 'get_heights' or 'combine' depending on which
%     one generated the echogram files
% param_override = parameters in this struct will override parameters
%         in param.  This struct must also contain the gRadar fields.
%         Typically global gRadar; param_override = gRadar;
%
% Example:
%  See run_img_combine_update.m for how to run this function directly.
%  This function may be called from the run_master.m script using the
%  param spreadsheet and the cmd.generic column.
%
% Authors: John Paden
% See also: run_img_combine_update.m, img_combine_update.m

%% General Setup
% =====================================================================

if exist('param_override','var')
  param = merge_structs(param, param_override);
end

fprintf('=====================================================================\n');
fprintf('%s: %s (%s)\n', mfilename, param.day_seg, datestr(now));
fprintf('=====================================================================\n');

%% Input checks
% =====================================================================

mode = param.img_combine_update.mode;

param = img_combine_input_check(param,mode);

% Load frames file
frames = frames_load(param);

% If no frames specified, then do all frames
if isempty(param.cmd.frms)
  param.cmd.frms = 1:length(frames.frame_idxs);
end

% Remove frames that do not exist from param.cmd.frms list
[valid_frms,keep_idxs] = intersect(param.cmd.frms, 1:length(frames.frame_idxs));
if length(valid_frms) ~= length(param.cmd.frms)
  bad_mask = ones(size(param.cmd.frms));
  bad_mask(keep_idxs) = 0;
  warning('Nonexistent frames specified in param.cmd.frms (e.g. frame "%g" is invalid), removing these', ...
    param.cmd.frms(find(bad_mask,1)));
  param.cmd.frms = valid_frms;
end

%% Setup processing
% =====================================================================

% Load surface information
if isfield(param.(mode),'img_comb_layer_params') && ~isempty(param.(mode).img_comb_layer_params)
  param_load_layers = param;
  param_load_layers.cmd.frms = 1:length(frames.frame_idxs);
  
  layers = opsLoadLayers(param_load_layers,param.(mode).img_comb_layer_params);
else
  layers = [];
end

% Output path
out_path = ct_filename_out(param,param.(mode).out_path,'');

%% Process each frame
for frm = param.cmd.frms
  
  out_fn = fullfile(out_path, sprintf('Data_%s_%03d.mat', ...
    param.day_seg, frm));
  fprintf('%s %s (%s)\n', mfilename, out_fn, datestr(now));

  param_mode_str = sprintf('param_%s',mode);
  if ~exist(out_fn,'file')
    tmp_out_fn = fullfile(out_path, sprintf('Data_img_01_%s_%03d.mat', ...
      param.day_seg, frm));
    warning('Combined file does not exist, so using img_01 file as the base for the combined file.');
    copyfile(tmp_out_fn,out_fn);
  end
  load(out_fn,param_mode_str,'Surface','GPS_time');
  
  if isempty(param.(mode).img_comb)
    % No image combining is required
    continue;
  end
  
  if length(param.(mode).img_comb) ~= 3*(length(param.(mode).imgs)-1)
    warning('param.(%s).img_comb not the right length. There should be 3 entries for each image combination interface ([Tpd second image for surface saturation, -inf for second image blank, Tpd first image to avoid roll off] is typical). Set correctly here and update param spreadsheet before dbcont.', mode);
    keyboard
  end
  
  % Combine images
  param.load.frm = frm;
  [Data, Time] = img_combine(param, mode, layers);

  % Update parameter structure with new parameters
  cmd = sprintf('%s.(mode).img_comb = param.(mode).img_comb;', param_mode_str);
  eval(cmd);
  cmd = sprintf('%s.(mode).img_comb_weights = param.(mode).img_comb_weights;', param_mode_str);
  eval(cmd);
  cmd = sprintf('%s.(mode).img_comb_mult = param.(mode).img_comb_mult;', param_mode_str);
  eval(cmd);
  cmd = sprintf('%s.(mode).img_comb_bins = param.(mode).img_comb_bins;', param_mode_str);
  eval(cmd);
  cmd = sprintf('%s.(mode).img_comb_weights_mode = param.(mode).img_comb_weights_mode;', param_mode_str);
  eval(cmd);
  cmd = sprintf('%s.(mode).img_comb_trim = param.(mode).img_comb_trim;', param_mode_str);
  eval(cmd);
  cmd = sprintf('%s.(mode).img_comb_layer_params = param.(mode).img_comb_layer_params;', param_mode_str);
  eval(cmd);
  
  % Save output
  save(out_fn,'-append','Time','Data',param_mode_str);
  
end
