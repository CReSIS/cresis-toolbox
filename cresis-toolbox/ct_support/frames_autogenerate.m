function autogenerate_frames(param,param_override)
%
% Reads in a param file's generic column and creates frames for each
% segment selected.  Everything is automated.  This is useful for the
% FMCW radars where frames are always auto generated.
%

%% General Setup
% =====================================================================
param = merge_structs(param, param_override);

fprintf('=====================================================================\n');
fprintf('%s: %s (%s)\n', mfilename, param.day_seg, datestr(now));
fprintf('=====================================================================\n');

%% Input checks
% =====================================================================

[output_dir,radar_type,radar_name] = ct_output_dir(param.radar_name);

if ~isfield(param,'records') || isempty(param.records)
  param.records = [];
end

if ~isfield(param.records,'frames') || isempty(param.records.frames)
  param.records.frames = [];
end

if ~isfield(param.records.frames,'mode') || isempty(param.records.frames.mode)
  param.records.frames.mode = 2;
end

if ~isfield(param.records.frames,'length') || isempty(param.records.frames.length)
  if any(strcmpi(output_dir,'rds'))
    param.records.frames.length = 50000;
  elseif any(strcmpi(output_dir,'accum'))
    param.records.frames.length = 20000;
  elseif any(strcmpi(output_dir,{'kaband','kuband','snow'}))
    param.records.frames.length = 5000;
  else
    error('%s is not a supported radar', param.radar_name);
  end
end
frame_length = param.records.frames.length;

%% Setup creation of frames
% =====================================================================

records_fn = ct_filename_support(param,'','records');
frames_fn = ct_filename_support(param,'','frames');

if ~exist(records_fn,'file')
  warning('  Skipping: records file does not exist %s', records_fn);
  return;
end

records = records_load(param);
frames = [];

%% Mode 2: fixed along-track spacing
% =====================================================================
if any(param.records.frames.mode == [1 2])
  % Create monotonically increasing along_track vector
  along_track = geodetic_to_along_track(records.lat,records.lon);
  
  % Speed check
  speed = diff(along_track) ./ diff(records.gps_time);
  if mean(speed) < 0.1
    warning('This appears to be stationary data because the mean speed is < 0.1 m/s. Use param.records.frames.mode = 3 if this is stationary data.');
  end

  % Break segment into frames based on the desired frame length in
  % "frame_length" (units of meters).
  frame_breaks = 0:frame_length:along_track(end);
  if along_track(end)-frame_breaks(end) < frame_length/2
    frame_breaks = frame_breaks(1:end-1);
  end
  frames.frame_idxs = zeros(size(frame_breaks));
  
  frames.frame_idxs(1) = 1;
  idx = 2;
  rec = 2;
  while idx <= length(frame_breaks)
    if along_track(rec) > frame_breaks(idx)
      frames.frame_idxs(idx) = rec;
      idx = idx + 1;
    end
    rec = rec + 1;
  end
end

%% Mode 3: fixed number of records (for stationary data)
% =====================================================================
if param.records.frames.mode == 3
  warning('Frame generation mode %d should only be used for stationary data (e.g. test data).', param.records.frames.mode);
  
  frames.frame_idxs = 1:50000:length(records.gps_time)-50000/2;
  if isempty(frames.frame_idxs)
    frames.frame_idxs = 1;
  end
end

%% Save frames file
% =====================================================================
frames.proc_mode = zeros(size(frames.frame_idxs));

frames.gps_time = [records.gps_time(frames.frame_idxs), records.gps_time(end)];
Nfrms = length(frames.frame_idxs);
frames.notes = cell(1,Nfrms);
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

fprintf('  Saving %s (%s)\n', frames_fn, datestr(now));
frames_fn_dir = fileparts(frames_fn);
if ~exist(frames_fn_dir,'dir')
  mkdir(frames_fn_dir);
end
if param.ct_file_lock
  frames.file_version = '1L';
else
  frames.file_version = '1';
end
frames.file_type = 'frames';
ct_file_lock_check(frames_fn,3);
ct_save(frames_fn,'-struct','frames');
