function records_check(param,param_override)
% records_check(param,param_override)
%
% Checks the fields in the records files for potential errors.
% Use run_all_records_check to run on all seasons.
%
% To concatenate and look at all the outputs in Linux:
% grep "^"  `find /cresis/snfs1/dataproducts/ct_data/ct_tmp/records_check -iname "*output*" -print | sort` | less
%
% param = parameter structure indicating which radar and season to load.
%   This causes the standard parameter spreadsheet filename to be created
%   and loaded.  Therefore it will not work if you don't have the parameter
%   spreadsheet in the standard location with the standard name.
%   ALTERNATE MODE: pass in a string containing the filename of a specific
%   record to load
%
% Example:
% param = [];
% param.radar_name = 'rds';
% param.season_name = '2009_Antarctica_DC8';
% records_check(param)
%
% param = [];
% param.radar_name = 'rds';
% param.season_name = '2011_Greenland_P3';
% records_check(param)
%
% param = [];
% param.radar_name = 'snow';
% param.season_name = '2013_Antarctica_Basler';
% records_check(param)
%
% Author: John Paden
%
% See also: check_data_products, frames_check, gps_check, records_check
% run_all_frames_check, run_all_gps_check, run_all_records_check

%% records_check ==========================================================

%% Input checks
global gRadar;
if exist('param_override','var')
  param_override = merge_structs(gRadar,param_override);
else
  param_override = gRadar;
end

old_time = [inf -inf];
if ischar(param)
  %% param is a string containing the filename
  % =======================================================================
  records_fn = param;
  records = load(records_fn,'param_records');
  if ~isfield(records,'param_records')
    error('This mode only supported for new records files with param_records field.');
  end
  
  param = merge_structs(records.param_records,param_override);
  fprintf('%d of %d: Checking records %s\n', 1, 1, records_fn);
  records_check_support_func(records_fn,param,old_time);
  
elseif isstruct(param)
  %% param is a struct
  % =======================================================================
  % struct indicates radar/season to check (checks all segments)
  [output_dir,radar_type] = ct_output_dir(param.radar_name);
  
  param_fn = ct_filename_param(sprintf('%s_param_%s.xls', output_dir, param.season_name));
  params = read_param_xls(param_fn);
  
  for param_idx = 1:length(params)
    param = params(param_idx);
    
    records_fn = ct_filename_support(param,'','records');
    
    if ~isempty(regexpi(param.cmd.notes,'do not process'))
      continue;
    end
    
    % DEBUG OPTION TO JUST CHECK RECORDS BASED ON GENERIC COLUMN IN SPREADSHEET
    % Uses the generic column of the parameter spreadsheet to determine which segments
    % to check.
    %if ~isfield(param.cmd,'generic') || iscell(param.cmd.generic) || ischar(param.cmd.generic) || ~param.cmd.generic
    %  continue;
    %end
    
    fprintf('%d of %d: Checking records %s\n', param_idx, length(params), records_fn);
    
    param = merge_structs(param,param_override);
    
    old_time = records_check_support_func(records_fn,param,old_time);
  end
  
else
  error('Invalid argument')
end

end

%% records_check_support_func =============================================
function old_time = records_check_support_func(records_fn,param,old_time)
% records_check_support_func(records_fn,param,old_time)
%
% Support function which does the actual checking of the records

%% input checks
% =========================================================================

% Setup records_check output file
command_window_out_fn = ct_filename_ct_tmp(param,'','records_check', 'output.txt');
command_window_out_fn_dir = fileparts(command_window_out_fn);
if ~exist(command_window_out_fn_dir,'dir')
  mkdir(command_window_out_fn_dir);
end
fid = fopen(command_window_out_fn,'wb');
fprintf('  Console output: %s\n', command_window_out_fn);
fprintf(fid, '%s\n', param.day_seg);

if ~exist(records_fn,'file')
  warning('Missing records file %s\n', records_fn);
  fprintf(fid,'  Missing records file %s!!!\n', records_fn);
  fclose(fid);
  return;
end

if ~isfield(param,'records_check') || isempty(param.records_check)
  param.records_check = [];
end

% along_track_skip_limit: positive numeric scalar, default 2000, units meters, threshold for
%   maximum allowed along-track skip
if ~isfield(param.records_check,'along_track_skip_limit') || isempty(param.records_check.along_track_skip_limit)
  param.records_check.along_track_skip_limit = 2000;
end

% gps_source_check: logical scalar, default true, if true prints non-final GPS source error
if ~isfield(param.records_check,'gps_source_check') || isempty(param.records_check.gps_source_check)
  param.records_check.gps_source_check = true;
end

% gps_time_skip_limit: positive numeric scalar, default 20, units seconds, threshold for
%   maximum allowed gps time skip
if ~isfield(param.records_check,'gps_time_skip_limit') || isempty(param.records_check.gps_time_skip_limit)
  param.records_check.gps_time_skip_limit = 20;
end

% ground: logical scalar, default true if season name contains "ground" and
%   false otherwise. If true, velocity threshold is a maximum allowed. If
%   false, it assumes aircraft and velocity threshold is a minimum allowed.
if ~isfield(param.records_check,'ground') || isempty(param.records_check.ground)
  param.records_check.ground = ~isempty(regexpi(param.season_name,'ground'));
end

% roll_limit: positive numeric scalar, default 25, units deg, threshold for
%   bad roll
if ~isfield(param.records_check,'roll_limit') || isempty(param.records_check.roll_limit)
  param.records_check.roll_limit = 25;
end

% stationary_threshold_sec: postive numeric scalar, default 10, units m/s, threshold
%   for bad velocity
if ~isfield(param.records_check,'stationary_threshold_sec') || isempty(param.records_check.stationary_threshold_sec)
  param.records_check.stationary_threshold_sec = 50;
end

% stationary_threshold_alongtrack: 2-element postive numeric vector,
%   default [0.1 10], units m, first threshold is the minimum distance the
%   platform must move to stay in the non-stationary state and second
%   threshold is how far the platform can move once it enters a stationary
%   state and still be considered stationary
if ~isfield(param.records_check,'stationary_threshold_alongtrack') || isempty(param.records_check.stationary_threshold_alongtrack)
  param.records_check.stationary_threshold_alongtrack = [0.1 10];
end

% vel_threshold: positive numeric scalar, default 10, units m/s, threshold
%   for bad velocity
if ~isfield(param.records_check,'vel_threshold') || isempty(param.records_check.vel_threshold)
  param.records_check.vel_threshold = 10;
end

records = records_load(param);

if isfield(records,'records')
  warning('Old records file format, skipping');
  fprintf(fid,'  Old records file format, skipping!!!\n');
  fclose(fid);
  return;
end

if param.records_check.gps_source_check && isempty(regexpi(records.gps_source,'final'))
  warning('GPS source is %s and not final\n', records.gps_source);
  fprintf(fid,'  GPS source is %s and not final!!!\n', records.gps_source);
end

%% mcrds specific checks
% =========================================================================
if strcmpi(records.radar_name,'mcrds')
  if length(records.raw.wfs) > 1
    warning('Waveform headers change during records');
    fprintf(fid,'  Waveform headers change during records!!!\n');
  end
  
  if isfield(records,'adc_phase_corr_deg')
    warning('This record has adc_phase_corr_deg field');
    fprintf(fid,'  This record has adc_phase_corr_deg field!!!\n');
  end
  
  radar_clock_delta = records.raw.radar_time - records.raw.comp_time;
  radar_clock_delta = detrend(radar_clock_delta);
  radar_clock_delta = radar_clock_delta - radar_clock_delta(1);
  
  if any(abs(radar_clock_delta) > 0.5)
    warning('Radar and computer clocks show too large delta');
    fprintf(fid,'  Radar and computer clocks show too large delta!!!\n');
    plot(radar_clock_delta)
    keyboard;
  end
  
  settings_inconsistent = false;
  for settings_idx = 1:length(records.raw.wfs)
    for wf = 1:length(records.raw.wfs(settings_idx).Waveform)
      if compare_structs(records.raw.wfs(settings_idx).Waveform(wf), records.raw.wfs(1).Waveform(wf),1)
        settings_inconsistent = true;
      end
      if records.raw.wfs(settings_idx).Waveform(wf).SampleDelay(1) ~= records.raw.wfs(1).Waveform(wf).SampleDelay(1)
        warning('SampleDelay not consistent');
        fprintf(fid,'  SampleDelay not consistent!!!\n');
      end
      if records.raw.wfs(settings_idx).Waveform(wf).NumberSamples(1) ~= records.raw.wfs(1).Waveform(wf).NumberSamples(1)
        warning('NumberSamples not consistent');
        fprintf(fid,'  NumberSamples not consistent!!!\n');
      end
      if param.radar.wfs(wf).Tpd ~= records.raw.wfs(settings_idx).Waveform(wf).PulseDuration
        warning('%d: Pulse duration does not match',settings_idx);
        fprintf(fid,'  %d: Pulse duration does not match!!!\n',settings_idx);
      end
      if param.radar.wfs(wf).f0 ~= records.raw.wfs(settings_idx).Waveform(wf).StartFrequency
        warning('%d: Start frequency does not match',settings_idx);
        fprintf(fid,'  %d: Start frequency does not match!!!\n',settings_idx);
      end
      if param.radar.wfs(wf).f1 ~= records.raw.wfs(settings_idx).Waveform(wf).StopFrequency
        warning('%d: Stop frequency does not match',settings_idx);
        fprintf(fid,'  %d: Stop frequency does not match!!!\n',settings_idx);
      end
      if 20*log10(param.radar.wfs(wf).adc_gains(1)) ~= 70.0-records.raw.wfs(settings_idx).Waveform(wf).RxAttenuation
        warning('%d: Receiver attenuation does not match',settings_idx);
        fprintf(fid,'  %d: Receiver attenuation does not match!!!\n',settings_idx);
      end
    end
  end
  if settings_inconsistent
    records.raw.wfs_file
  end
  
end

%% velocity
% =========================================================================
along_track = geodetic_to_along_track(records.lat,records.lon,records.elev);
vel = diff(along_track) ./ diff(records.gps_time);
if param.records_check.ground
  if any(vel > param.records_check.vel_threshold)
    warning('Large velocity (%g). All below %g m/s.', min(vel), max(vel), param.records_check.vel_threshold);
    fprintf(fid,'  Large velocity (%g). All below %g m/s.\n', min(vel), max(vel), param.records_check.vel_threshold);
  end
else
  if any(vel < param.records_check.vel_threshold)
    if all(vel < param.records_check.vel_threshold)
      warning('Small velocity detected (min %g max %g). All below %g m/s.', min(vel), max(vel), param.records_check.vel_threshold);
      fprintf(fid,'  Small velocity detected (min %g max %g). All below %g m/s.\n', min(vel), max(vel), param.records_check.vel_threshold);
    else
      warning('Small velocity detected (min %g max %g). Some above %g m/s.', min(vel), max(vel), param.records_check.vel_threshold);
      fprintf(fid,'  Small velocity detected (min %g max %g). Some above %g m/s.\n', min(vel), max(vel), param.records_check.vel_threshold);
    end
  end
  if any(vel > 300)
    warning('Large velocity detected (min %g max %g).', min(vel), max(vel));
    fprintf(fid,'  Large velocity detected (min %g max %g)!!!\n', min(vel), max(vel));
  end
end

%% lat, lon, elev
% =========================================================================
if any(records.lat >= 90 | records.lat <= -90)
  warning('lat out of bounds');
  fprintf(fid,'  lat out of bounds!!!');
end

if any(records.lon >= 360 | records.lon <= -360)
  warning('lon out of bounds');
  fprintf(fid,'  lon out of bounds!!!');
end

if any(records.elev >= 40000 | records.elev <= -10000)
  warning('elev out of bounds');
  fprintf(fid,'  elev out of bounds!!!');
end

%% roll, pitch, heading
% =========================================================================
if any(records.roll >= param.records_check.roll_limit/180*pi | records.roll <= -param.records_check.roll_limit/180*pi)
  warning('abs(roll) > %g deg: max %.1f min %.1f', param.records_check.roll_limit, max(records.roll)*180/pi, min(records.roll)*180/pi);
  fprintf(fid,'  abs(roll) > %g deg: max %.1f min %.1f', param.records_check.roll_limit, max(records.roll)*180/pi, min(records.roll)*180/pi);
end

if any(records.pitch >= 25/180*pi | records.pitch <= -25/180*pi)
  warning('abs(pitch) > 25 deg: max %.1f min %.1f', max(records.pitch)*180/pi, min(records.pitch)*180/pi);
  fprintf(fid,'  abs(pitch) > 25 deg: max %.1f min %.1f', max(records.pitch)*180/pi, min(records.pitch)*180/pi);
end

if any(records.heading >= 2*pi | records.heading <= -2*pi)
  warning('abs(heading) > 2*pi');
  fprintf(fid,'  abs(heading) > 2*pi');
end

%% gps_time
% =========================================================================

if old_time(2) > records.gps_time(1)
  warning('records out of order (meaning that the previous segment has a gps time (%s to %s) that is greater than the start of this segment (%s to %s), but the current segment is listed later in the parameters and segments must be listed chronologically)', ...
    datestr(epoch_to_datenum(old_time(1))), datestr(epoch_to_datenum(old_time(end))), ...
    datestr(epoch_to_datenum(records.gps_time(1))), datestr(epoch_to_datenum(records.gps_time(end))));
  fprintf(fid,'  records out of order (meaning that the previous segment has a gps time (%s to %s) that is greater than the start of this segment (%s to %s), but the current segment is listed later in the parameters and segments must be listed chronologically)!!!\n', ...
    datestr(epoch_to_datenum(old_time(1))), datestr(epoch_to_datenum(old_time(end))), ...
    datestr(epoch_to_datenum(records.gps_time(1))), datestr(epoch_to_datenum(records.gps_time(end))));
end

% old_time: output argument used to ensure segments are in chronological order
old_time = records.gps_time([1 end]);

nonmonotonic_records = diff(records.gps_time) < 0;
if any(nonmonotonic_records)
  warning('time not monotonically increasing: First non-monotonic record %d of %d total, %d total records.', ...
    find(nonmonotonic_records,1), sum(nonmonotonic_records), length(records.gps_time));
  fprintf(fid,'  time not monotonically increasing: First non-monotonic record %d of %d total, %d total records!!!', ...
    find(nonmonotonic_records,1), sum(nonmonotonic_records), length(records.gps_time));
end

if any(isnan(records.gps_time))
  warning('NaN in records.gps_time');
  fprintf(fid,'  NaN in records.gps_time!!!');
end

if any(isnan(records.lat) | isnan(records.lon) | isnan(records.elev)  | isnan(records.roll)  | isnan(records.pitch)  | isnan(records.heading))
  warning('NaN in record trajectory/attitude fields');
  fprintf(fid,'  NaN in record trajectory/attitude fields!!!');
end

diff_time = diff(records.gps_time);
if any(diff_time > param.records_check.gps_time_skip_limit)
  jump_idxs = find(diff_time > param.records_check.gps_time_skip_limit);
  warning('Time gap greater than limit %.1f sec, max skip found is %.1f sec', ...
    param.records_check.gps_time_skip_limit, max(diff_time));
  fprintf('Time gaps in seconds: '); fprintf('%f\t', diff_time(jump_idxs)); fprintf('\n');
  for jump_idx = jump_idxs
    fprintf('  Gap is at file index %d to %d of %d to %d files\n', find(records.relative_rec_num{1} > jump_idx,1), ...
      find(records.relative_rec_num{1} > jump_idx+1,1), 1, length(records.relative_rec_num{1}));
  end
  fprintf(fid,'  Time gap greater than limit %.1f sec, max skip found is %.1f sec!!!', ...
    param.records_check.gps_time_skip_limit, max(diff_time));
  fprintf(fid,'  Time gaps in seconds: '); fprintf(fid,'%f\t', diff_time(jump_idxs)); fprintf(fid,'\n');
  for jump_idx = jump_idxs
    fprintf(fid,'    Gap is at file index %d to %d of %d to %d files\n', find(records.relative_rec_num{1} > jump_idx,1), ...
      find(records.relative_rec_num{1} > jump_idx+1,1), 1, length(records.relative_rec_num{1}));
  end
end

%% along_track gaps
% =========================================================================
diff_along_track = diff(along_track);
if any(diff_along_track > param.records_check.along_track_skip_limit)
  jump_idxs = find(diff_along_track > param.records_check.along_track_skip_limit);
  warning('Along-track gap greater than limit %.1f m, max skip found is %.1f m', ...
    param.records_check.along_track_skip_limit, max(diff_along_track));
  fprintf('Along-track gaps: '); fprintf('%f\t', diff_along_track(jump_idxs)); fprintf('\n');
  for jump_idx = jump_idxs
    fprintf('  Gap is at file index %d to %d of %d to %d files\n', find(records.relative_rec_num{1} > jump_idx,1), ...
      find(records.relative_rec_num{1} > jump_idx+1,1), 1, length(records.relative_rec_num{1}));
  end
  fprintf(fid,'  Along-track gap greater than limit %.1f m, max skip found is %.1f m!!!', ...
    param.records_check.along_track_skip_limit, max(diff_along_track));
  fprintf(fid,'  Along-track gaps: '); fprintf(fid,'%f\t', diff_along_track(jump_idxs)); fprintf(fid,'\n');
  for jump_idx = jump_idxs
    fprintf(fid,'    Gap is at file index %d to %d of %d to %d files\n', find(records.relative_rec_num{1} > jump_idx,1), ...
      find(records.relative_rec_num{1} > jump_idx+1,1), 1, length(records.relative_rec_num{1}));
  end
end

%% stationary data
% =========================================================================
% along_track: generate without elevation since elevation errors can
% accumulate and the platform can appear to be moving when it is not
along_track = geodetic_to_along_track(records.lat,records.lon);
rec = 1;
cur_along_track = along_track(rec);
cur_rec = rec;
stationary = false(size(along_track));
stationary_list = [];
alongtrack_threshold = param.records_check.stationary_threshold_alongtrack(1);
for rec = 2:length(along_track)
  if along_track(rec) > cur_along_track + alongtrack_threshold ...
      || rec == length(along_track)
    cur_along_track = along_track(rec);
    if stationary(rec-1) == true
      alongtrack_threshold = param.records_check.stationary_threshold_alongtrack(1);
      stationary_duration = records.gps_time(rec) - cur_gps_time;
      if stationary_duration > param.records_check.stationary_threshold_sec
        stationary_list(end+1).rec = [cur_rec rec];
        stationary_list(end).gps_time = [cur_gps_time records.gps_time(rec)];
        stationary_list(end).duration = stationary_duration;
      end
    end
  else
    stationary(rec) = true;
    if stationary(rec-1) == false
      alongtrack_threshold = param.records_check.stationary_threshold_alongtrack(2);
      cur_rec = rec;
      cur_gps_time = records.gps_time(rec);
      stationary(rec) = true;
    end
  end
end
if ~isempty(stationary_list)
  warning('Stationary data exists.');
  for idx = 1:length(stationary_list)
    fprintf('  Stationary %.1f sec from %s to %s\n', stationary_list(idx).duration, ...
      datestr(epoch_to_datenum(stationary_list(idx).gps_time(1))), ...
      datestr(epoch_to_datenum(stationary_list(idx).gps_time(end))));
  end
  fprintf(fid,'  Stationary data exists.');
  for idx = 1:length(stationary_list)
    fprintf(fid,'    Stationary %.1f sec from %s to %s\n', stationary_list(idx).duration, ...
      datestr(epoch_to_datenum(stationary_list(idx).gps_time(1))), ...
      datestr(epoch_to_datenum(stationary_list(idx).gps_time(end))));
  end
end

%% cleanup
% =========================================================================
fclose(fid);

end
