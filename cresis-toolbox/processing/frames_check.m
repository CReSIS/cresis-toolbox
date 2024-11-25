function frames_check(param,param_override)
% frames_check(param,param_override)
%
% Checks the fields in the frames files for potential errors.
% Use run_all_frames_check to run on all seasons.
%
% To concatenate and look at all the outputs in Linux:
% grep "^"  `find /cresis/snfs1/dataproducts/ct_data/ct_tmp/frames_check -iname "*output*" -print | sort` | less
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
% param.radar_name = 'mcrds';
% param.season_name = '2009_Antarctica_TO';
% frames_check(param)
%
% param = [];
% param.radar_name = 'rds';
% param.season_name = '2018_Greenland_P3';
% frames_check(param)
%
% param = [];
% param.radar_name = 'snow3';
% param.season_name = '2013_Antarctica_Basler';
% frames_check(param)
%
% Author: John Paden
%
% See also: check_data_products, frames_check, gps_check, records_check
% run_all_frames_check, run_all_gps_check, run_all_records_check

%% frames_check ==========================================================

%% Input checks
global gRadar;
if exist('param_override','var')
  param_override = merge_structs(gRadar,param_override);
else
  param_override = gRadar;
end

if ischar(param)
  %% param is a string containing the filename
  % =======================================================================
  records_fn = param;
  records = records_load(records_fn,'param_records');
  if ~isfield(records,'param_records')
    error('This mode only supported for new records files with param_records field.');
  end
  
  param = merge_structs(records.param_records,param_override);
  
  frames_fn = ct_filename_support(param,'','frames');
  
  frames_create_support_func(frames_fn,param);
  
elseif isstruct(param)
  %% param is a struct
  % =======================================================================
  % struct indicates radar/season to check (checks all segments)
  [output_dir,radar_type,radar_name] = ct_output_dir(param.radar_name);

  param_fn = ct_filename_param(sprintf('%s_param_%s.xls', output_dir, param.season_name));
  params = read_param_xls(param_fn);
  
  for param_idx = 1:length(params)
    param = params(param_idx);
    param = merge_structs(param,param_override);
    
    if ~isempty(regexpi(param.cmd.notes,'do not process'))
      continue;
    end
    
    frames_fn = ct_filename_support(param,'','frames');
    
    % DEBUG OPTION TO JUST CHECK FRAMES BASED ON GENERIC COLUMN IN SPREADSHEET
    % Uses the generic column of the parameter spreadsheet to determine which segments
    % to check.
    %if ~isfield(param.cmd,'generic') || iscell(param.cmd.generic) || ischar(param.cmd.generic) || ~param.cmd.generic
    %  continue;
    %end

    fprintf('%s\tChecking\t%s\n', param.day_seg, frames_fn);
    
    frames_create_support_func(frames_fn,param);
  end
  
else
  error('Invalid argument')
end

end

%% frames_create_support_func =============================================
function frames_create_support_func(frames_fn,param)
% frames_create_support_func(frames_fn,param)
%
% Support function which does the actual checking of the frames

%% input checks
% =========================================================================

command_window_out_fn = ct_filename_ct_tmp(param,'','frames_check', 'output.txt');
command_window_out_fn_dir = fileparts(command_window_out_fn);
if ~exist(command_window_out_fn_dir,'dir')
  mkdir(command_window_out_fn_dir);
end
fid = fopen(command_window_out_fn,'wb');
fprintf('  Console output: %s\n', command_window_out_fn);
fprintf(fid, '%s\n', param.day_seg);

% fixable_error: Set to true if a fixable error in which case the frames
% file will be updated at the end of this function.
fixable_error = false;

if ~exist(frames_fn,'file')
  fprintf(2,'%s\tno_frames_file\t%s\n', param.day_seg, frames_fn);
  fprintf(fid,'%s\tno_frames_file\t%s!!!\n', param.day_seg, frames_fn);
  fclose(fid);
  return;
end

records_fn = ct_filename_support(param,'','frames');
if ~exist(records_fn,'file')
  fprintf(2,'%s\tno_records_file\t%s\n', param.day_seg, records_fn);
  fprintf(fid,'%s\tno_records_file\t%s!!!\n', param.day_seg, records_fn);
  fclose(fid);
  return;
end

records = records_load(param,'lat','lon');
along_track = geodetic_to_along_track(records.lat,records.lon);
frames = frames_load(param);

if frames.frame_idxs(1) ~= 1
  fprintf(2,'%s\tframe_idxs_1_not_1\t%d instead of 1\n', param.day_seg, frames.frame_idxs(1));
  fprintf(fid,'%s\tframe_idxs_1_not_1\t%d instead of 1\n', param.day_seg, frames.frame_idxs(1));
end

%% Check each field
% =========================================================================

if any(frames.frame_idxs > length(records.lat))
  fprintf(2,'%s\tframe_idxs_too_large\tindex %d > number of records %d\n', ...
    param.day_seg, max(frames.frame_idxs), length(records.lat));
  fprintf(fid,'%s\tframe_idxs_too_large\tindex %d > number of records %d!!!\n', ...
    param.day_seg, max(frames.frame_idxs), length(records.lat));
end

if isfield(frames,'nyquist_zone')
  fprintf(2,'%s\tnyquist_zone_remove\n', param.day_seg);
  frames = rmfield(frames,'nyquist_zone');
  fixable_error = true;
end

if length(frames.frame_idxs) ~= length(frames.proc_mode)
  fprintf(2,'%s\tproc_mode_length_mismatch\tlength %d does not match frame_idxs length %d\n', ...
    param.day_seg, length(frames.proc_mode), length(frames.frame_idxs));
  fixable_error = true;
  if length(frames.frame_idxs) > length(frames.proc_mode)
    frames.proc_mode(end+1 : length(frames.frame_idxs)) = NaN;
  else
    frames.proc_mode = frames.proc_mode(1:length(frames.frame_idxs));
  end
end

%% Check frame along-track
% =========================================================================

[output_dir,radar_type,radar_name] = ct_output_dir(param.radar_name);
if any(strcmpi(output_dir,'rds'))
  default_frame_len = 50000;
  default_min_rec = 1000;
elseif any(strcmpi(output_dir,'accum'))
  default_frame_len = 20000;
  default_min_rec = 1000;
elseif any(strcmpi(output_dir,{'kaband','kuband','snow'}))
  default_frame_len = 5000;
  default_min_rec = 1000;
end

for frm = 1:length(frames.frame_idxs)
  if frm < length(frames.frame_idxs)
    frame_len = along_track(frames.frame_idxs(frm+1)) - along_track(frames.frame_idxs(frm));
    frame_num_recs = frames.frame_idxs(frm+1) - frames.frame_idxs(frm);
  else
    frame_len = along_track(end) - along_track(frames.frame_idxs(frm));
    frame_num_recs = length(records.lat) - frames.frame_idxs(frm);
  end
  % Check length of frame
  if length(frames.frame_idxs) == 1 && frame_len < default_frame_len/10
    fprintf(2,'%s\tsingle_frame_too_short\t%g km < %g km for frame \t%d\n', param.day_seg, frame_len/1e3, 1/5*default_frame_len/1e3, frm);
    fprintf(fid,'%s\tsingle_frame_too_short\t%g km < %g km for frame \t%d\n', param.day_seg, frame_len/1e3, 1/5*default_frame_len/1e3, frm);
  elseif length(frames.frame_idxs) > 1 && frame_len < default_frame_len/5
    fprintf(2,'%s\ttoo_short\t%g km < %g km for frame \t%d\n', param.day_seg, frame_len/1e3, 1/5*default_frame_len/1e3, frm);
    fprintf(fid,'%s\ttoo_short\t%g km < %g km for frame \t%d\n', param.day_seg, frame_len/1e3, 1/5*default_frame_len/1e3, frm);
  end
  if frame_len > 5*default_frame_len
    % Add "!!!" to the end of string to indicate that this frame should be
    % fixed.
    fprintf(2,'%s\ttoo_long\t%g km > %g km for frame \t%d\n', param.day_seg, frame_len/1e3, 5*default_frame_len/1e3, frm);
    fprintf(fid,'%s\ttoo_long\t%g km > %g km for frame \t%d!!!\n', param.day_seg, frame_len/1e3, 5*default_frame_len/1e3, frm);
  elseif frame_len > 2*default_frame_len
    fprintf(2,'%s\ttoo_long\t%g km > %g km for frame \t%d\n', param.day_seg, frame_len/1e3, 2*default_frame_len/1e3, frm);
    fprintf(fid,'%s\ttoo_long\t%g km > %g km for frame \t%d\n', param.day_seg, frame_len/1e3, 2*default_frame_len/1e3, frm);
  end
  % Check number of records in frame
  if frame_num_recs < default_min_rec
    fprintf(2,'%s\tFrame has very few records\t%d\t%d\n', param.day_seg, frame_num_recs, frm);
    fprintf(fid, '%s\tFrame has very few records\t%d\t%d\n', param.day_seg, frame_num_recs, frm);
  end
end

%% Save updates/cleanup
% =========================================================================

if 1 && fixable_error
  fprintf('Save %s\n', frames_fn);
  ct_save(frames_fn,'frames');
end

fclose(fid);

end

