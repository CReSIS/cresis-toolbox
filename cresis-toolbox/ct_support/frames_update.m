function frames_update(param,param_override)
% frames_update(param,param_override)
%
% This function updates the frames according to the param struct. The
% primary purpose is to update an old frames file to the new file format.
%
% param: parameter spreadsheet structure array
% param_override: usually contains gRadar contents plus any additional
% parameters to override.
%
% Examples: See run_all_frames_update.m
%
% Author: John Paden
%
% See also: run_all_frames_update, run_frames_update, frames_update

param = merge_structs(param,param_override);

dbstack_info = dbstack;
fprintf('=====================================================================\n');
fprintf('%s: %s (%s)\n', dbstack_info(1).name, param.day_seg, datestr(now,'HH:MM:SS'));
fprintf('=====================================================================\n');

%% Input checks
frames_fn = ct_filename_support(param,'','frames');
if cluster_job_check()
  error('frames_update may not be called from cluster_job (gRadar.cluster.is_cluster_job is currently set to true). To remove this error, run frames_update on: %s', frames_fn);
end

if ~isfield(param,'frames_update') || isempty(param.frames_update)
  param.frames_update = [];
end

% param.frames_update.force_update: scalar logical. Default is true. If
% true, the frames file will be updated (e.g. GPS times from records file
% will be updated). If false, the file will be checked for being in the
% newest format. If it is, then nothing is done.
if ~isfield(param.frames_update,'force_update') || isempty(param.frames_update.force_update)
  param.frames_update.force_update = true;
end

%% Update according to file format
var_list = whos('-file',frames_fn);
if any(strcmpi('frames',{var_list.name}))
  % Old format put all the variables into a single struct variable
  % "frames". The new format puts all these variables at the base level in
  % the file.
  param.frames_update.force_update = true;
  old_format = load(frames_fn,'frames');
  
  % Load records file
  records = records_load(param,'gps_time');
  
  frames = [];
  frames.frame_idxs = old_format.frames.frame_idxs;
  frames.gps_time = [records.gps_time(frames.frame_idxs), records.gps_time(end)];
  Nfrms = length(frames.frame_idxs);
  frames.notes = cell(1,Nfrms);
  if isfield(old_format.frames,'quality')
    frames.quality = old_format.frames.quality;
  else
    frames.quality = zeros(1,Nfrms);
  end
  if isfield(old_format.frames,'proc_mode')
    frames.proc_mode = old_format.frames.proc_mode;
  else
    frames.proc_mode = zeros(1,Nfrms);
  end
  frames.Nx = length(records.gps_time);
  frames.param.day_seg = param.day_seg;
  frames.param.season_name = param.season_name;
  frames.param.radar_name = param.radar_name;
  if ~isfield(param,'sw_version')
    param.sw_version = current_software_version;
  end
  frames.param.sw_version = param.sw_version;
  
else
  % New format
  frames = load(frames_fn);
  
  if ~param.frames_update.force_update
    
    if ~isfield(frames,'frame_idxs')
      error('Frames file is missing frame_idxs field. This is an incomplete frames file which cannot be updated without this essential information.');
    end
    
    if ~isfield(frames,'Nx') || length(frames.Nx) ~= 1
      param.frames_update.force_update = true;
    end
    
    if ~isfield(frames,'file_type') || ~strcmp(frames.file_type,'frames')
      param.frames_update.force_update = true;
    end
    
    if ~isfield(frames,'file_version') || ~any(frames.file_version == '1')
      param.frames_update.force_update = true;
    end
    
    if ~isfield(frames,'gps_time') || length(frames.gps_time)-1 ~= length(frames.frame_idxs)
      param.frames_update.force_update = true;
    end
    
    if ~isfield(frames,'notes') || length(frames.notes) ~= length(frames.frame_idxs)
      param.frames_update.force_update = true;
    end
    
    if ~isfield(frames,'param')
      param.frames_update.force_update = true;
    end
    
    if ~isfield(frames.param,'day_seg') || ~strcmp(frames.param.day_seg,param.day_seg)
      param.frames_update.force_update = true;
    end
    
    if ~isfield(frames.param,'season_name') || ~strcmp(frames.param.season_name,param.season_name)
      param.frames_update.force_update = true;
    end
    
    if ~isfield(frames.param,'radar_name') || ~strcmp(frames.param.radar_name,param.radar_name)
      param.frames_update.force_update = true;
    end
    
    if ~isfield(frames.param,'sw_version')
      param.frames_update.force_update = true;
    end
    
    if ~isfield(frames,'proc_mode') || length(frames.proc_mode) ~= length(frames.frame_idxs)
      param.frames_update.force_update = true;
    end
    
    if ~isfield(frames,'quality') || length(frames.quality) ~= length(frames.frame_idxs)
      param.frames_update.force_update = true;
    end
  end
  
  if param.frames_update.force_update
    frames = load(frames_fn);
    
    % Load records file
    records = records_load(param,'gps_time');
    
    frames.gps_time = [records.gps_time(frames.frame_idxs), records.gps_time(end)];
    Nfrms = length(frames.frame_idxs);
    if ~isfield(frames,'notes')
      frames.notes = cell(1,Nfrms);
    end
    if ~isfield(frames,'quality')
      frames.quality = zeros(1,Nfrms);
    end
    if ~isfield(frames,'proc_mode')
      frames.proc_mode = zeros(1,Nfrms);
    end
    frames.Nx = length(records.gps_time);
    frames.param.day_seg = param.day_seg;
    frames.param.season_name = param.season_name;
    frames.param.radar_name = param.radar_name;
    frames.param.sw_version = param.sw_version;
  else
    fprintf('  Frames file does not need to be updated.\n');
  end
end

if param.frames_update.force_update
  if isfield(param,'ct_file_lock') && param.ct_file_lock
    frames.file_version = '1L';
  else
    frames.file_version = '1';
  end
  frames.file_type = 'frames';
  
  fprintf('Saving updated frames file: %s\n', frames_fn);
  ct_save(frames_fn,'-struct','frames');
end
