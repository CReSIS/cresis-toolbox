function gps_check(param,param_override)
% gps_check(param,param_override)
%
% Checks the fields in the gps files for potential errors.
% Use run_all_gps_check to run on all seasons.
%
% To concatenate and look at all the outputs in Linux:
% grep "^"  `find /cresis/snfs1/dataproducts/ct_data/ct_tmp/gps_check -iname "*output*" -print | sort` | less
%
% param = parameter structure indicating which radar and season to load.
%   This causes the standard parameter spreadsheet filename to be created
%   and loaded.  Therefore it will not work if you don't have the parameter
%   spreadsheet in the standard location with the standard name.
%   ALTERNATE MODE: pass in a string containing the filename of a specific
%   gps to load
%
% Example:
%
% % csarp_support/gps filename
% gps_check('/cresis/snfs1/dataproducts/csarp_support/gps/2019_Antarctica_Ground/gps_20200106.mat');
% gps_check('/cresis/snfs1/dataproducts/csarp_support/gps/2019_Antarctica_Ground/gps_20200107.mat');
%
% % Parameter structure
% param = [];
% param.radar_name = 'rds';
% param.season_name = '2019_Antarctica_Ground';
% gps_check(param)
%
% Author: John Paden
%
% See also: check_data_products, frames_check, gps_check, records_check
% gps_load, gps_create
% run_all_frames_check, run_all_gps_check, run_all_records_check


%% gps_check ==============================================================

%% Input checks
global gRadar;
if exist('param_override','var')
  param_override = merge_structs(gRadar,param_override);
else
  param_override = gRadar;
end

old_time = [-inf -inf];
if ischar(param)
  %% param is a string containing the filename
  % =======================================================================
  gps_fn = param;
  
  gps = gps_load(gps_fn);
  param = [];
  param.season_name = gps.season_name;
  param.gps_check.date_str = gps.date_str;
  
  fprintf('%d of %d: Checking gps %s\n', 1, 1, gps_fn);
  gps_check_support_func(gps_fn,param,old_time);
  
elseif isstruct(param)
  %% param is a struct
  % =======================================================================
  % struct indicates radar/season to check (checks all segments)
  [output_dir,radar_type] = ct_output_dir(param.radar_name);
  
  param_fn = ct_filename_param(sprintf('%s_param_%s.xls', output_dir, param.season_name));
  params = read_param_xls(param_fn);

  for param_idx = 1:length(params)
    param = params(param_idx);
    
    % Skip segment if the same day as the last segment or if set as "do not
    % process"
    if param_idx > 1 && strcmp(param.day_seg(1:8),params(param_idx-1).day_seg(1:8)) ...
        || ~isempty(regexpi(param.cmd.notes,'do not process'))
      continue;
    end
    
    % DEBUG OPTION TO JUST CHECK GPS BASED ON GENERIC COLUMN IN SPREADSHEET
    % Uses the generic column of the parameter spreadsheet to determine which segments
    % to check.
    %if ~isfield(param.cmd,'generic') || iscell(param.cmd.generic) || ischar(param.cmd.generic) || ~param.cmd.generic
    %  continue;
    %end
    
    if ~isfield(param.records.gps,'fn')
      param.records.gps.fn = '';
    end
    gps_fn = ct_filename_support(param,param.records.gps.fn,'gps',true);
    
    fprintf('%d of %d: Checking gps %s\n', param_idx, length(params), gps_fn);
    
    param = merge_structs(param,param_override);
    
    param.gps_check.date_str = param.day_seg(1:8);
    
    old_time = gps_check_support_func(gps_fn,param,old_time);
  end
  
else
  error('Invalid argument')
end

end

%% gps_check_support_func =============================================
function old_time = gps_check_support_func(gps_fn,param,old_time)
% gps_check_support_func(gps_fn,param,old_time)
%
% Support function which does the actual checking of the gps

%% input checks
% =========================================================================

command_window_out_fn = ct_filename_ct_tmp(ct_rmfield(param,{'day_seg','radar_name'}),'','gps_check', sprintf('output_%s.txt',param.gps_check.date_str));
command_window_out_fn_dir = fileparts(command_window_out_fn);
if ~exist(command_window_out_fn_dir,'dir')
  mkdir(command_window_out_fn_dir);
end
fid = fopen(command_window_out_fn,'wb');
fprintf('  Console output: %s\n', command_window_out_fn);
fprintf(fid, '%s\n', param.gps_check.date_str);

% fixable_error: Set to true if a fixable error was found in which case the
% gps file will be updated at the end of this function.
fixable_error = false;

% gps_source_check: logical scalar, default true, if true prints non-final GPS source error
if ~isfield(param.gps_check,'gps_source_check') || isempty(param.gps_check.gps_source_check)
  param.gps_check.gps_source_check = true;
end

% roll_limit: positive numeric scalar, default 25, units deg, threshold for
%   bad roll
if ~isfield(param.gps_check,'roll_limit') || isempty(param.gps_check.roll_limit)
  param.gps_check.roll_limit = 25;
end

if ~exist(gps_fn,'file')
  warning('Missing gps file %s\n', gps_fn);
  fclose(fid);
  return;
end

gps = gps_load(gps_fn);

if old_time(2) > gps.gps_time(1)
  warning('gps out of order (meaning that the previous day has a gps time (%s to %s) that is greater than the start of this day (%s to %s), but the current day is later and must be listed chronologically)', ...
    datestr(epoch_to_datenum(old_time(1))), datestr(epoch_to_datenum(old_time(end))), ...
    datestr(epoch_to_datenum(gps.gps_time(1))), datestr(epoch_to_datenum(gps.gps_time(end))));
  fprintf(fid,'  gps out of order (meaning that the previous day has a gps time (%s to %s) that is greater than the start of this day (%s to %s), but the current day is later and must be listed chronologically)', ...
    datestr(epoch_to_datenum(old_time(1))), datestr(epoch_to_datenum(old_time(end))), ...
    datestr(epoch_to_datenum(gps.gps_time(1))), datestr(epoch_to_datenum(gps.gps_time(end))));
end

% old_time: output argument used to ensure gps files are in chronological order
old_time = gps.gps_time([1 end]);

%% gps_time and gps_source checks
% =========================================================================

% Print out start/stop times in several formats
% -------------------------------------------------------------------------
gps_time_datenum = epoch_to_datenum(gps.gps_time);
[year month day hour minute sec] = datevec(gps_time_datenum(1));
gps_sod = (gps_time_datenum - datenum([year month day 0 0 0])) * 86400;

along_track = geodetic_to_along_track(gps.lat,gps.lon,gps.elev);

fprintf('  Start: %16.14g %s %12.3f %12.3f m UTC is %3f sec\n', gps.gps_time(1), datestr(gps_time_datenum(1)), gps_sod(1), along_track(1), -utc_leap_seconds(gps.gps_time(1)));
fprintf('  Stop:  %16.14g %s %12.3f %12.3f m\n', gps.gps_time(end), datestr(gps_time_datenum(end)), gps_sod(end), along_track(end));
fprintf(fid,'  Start: %16.14g %s %12.3f %12.3f m UTC is %3f sec\n', gps.gps_time(1), datestr(gps_time_datenum(1)), gps_sod(1), along_track(1), -utc_leap_seconds(gps.gps_time(1)));
fprintf(fid,'  Stop:  %16.14g %s %12.3f %12.3f m\n', gps.gps_time(end), datestr(gps_time_datenum(end)), gps_sod(end), along_track(end));

if ~isfield(gps,'gps_source')
  fprintf('gps_source: field does not exist!!!\n');
  fprintf(fid,'  gps_source: field does not exist!!!\n');
  gps.gps_source = '';
  fixable_error = true;
end

if isempty(regexpi(gps.gps_source,'final'))
  warning('GPS source is %s and not final\n', gps.gps_source);
  fprintf(fid,'  GPS source is %s and not final!!!\n', gps.gps_source);
end

dgps_time = diff(gps.gps_time);

nonmonotonic_idxs = find(dgps_time <= 0);
if ~isempty(nonmonotonic_idxs)
  warning('%d indexes are nonmonotonically increasing with diff(gps_time) <= 0', length(nonmonotonic_idxs));
  fprintf(fid,'  %d indexes are nonmonotonically increasing with diff(gps_time) <= 0!!!', length(nonmonotonic_idxs));
end

skip_idxs = find(dgps_time > 1.1);
if ~isempty(skip_idxs)
  warning('%d indexes skip more than 1 second with diff(gps_time) <= 1.1. Largest is %g sec.', length(skip_idxs), max(dgps_time));
  fprintf(fid, '  %d indexes skip more than 1 second with diff(gps_time) <= 1.1. Largest is %g sec.', length(skip_idxs), max(dgps_time));
end

if any(isnan(gps.gps_time))
  warning('NaN in gps.gps_time');
  fprintf(fid,'  NaN in gps.gps_time!!!');
end

if any(isnan(gps.lat) | isnan(gps.lon) | isnan(gps.elev)  | isnan(gps.roll)  | isnan(gps.pitch)  | isnan(gps.heading))
  warning('NaN in gps trajectory/attitude fields');
  fprintf(fid,'  NaN in gps trajectory/attitude fields!!!');
end

%% length of vectors
% =========================================================================

Nx = length(gps.gps_time);

if length(gps.lat) ~= Nx
  warning('Length of lat does not match gps_time.\n', length(gps.lat), Nx);
  fprintf(fid,'  Length of lat does not match gps_time.!!!\n', length(gps.lat), Nx);
end
if length(gps.lon) ~= Nx
  warning('Length of lon does not match gps_time.\n', length(gps.lon), Nx);
  fprintf(fid,'  Length of lon does not match gps_time.!!!\n', length(gps.lon), Nx);
end
if length(gps.elev) ~= Nx
  warning('Length of elev does not match gps_time.\n', length(gps.elev), Nx);
  fprintf(fid,'  Length of elev does not match gps_time!!!.\n', length(gps.elev), Nx);
end
if length(gps.roll) ~= Nx
  warning('Length of roll does not match gps_time.\n', length(gps.roll), Nx);
  fprintf(fid,'  Length of roll does not match gps_time.!!!\n', length(gps.roll), Nx);
end
if length(gps.pitch) ~= Nx
  warning('Length of pitch does not match gps_time.\n', length(gps.pitch), Nx);
  fprintf(fid,'  Length of pitch does not match gps_time.!!!\n', length(gps.pitch), Nx);
end
if length(gps.heading) ~= Nx
  warning('Length of heading does not match gps_time.\n', length(gps.heading), Nx);
  fprintf(fid,'  Length of heading does not match gps_time.!!!\n', length(gps.heading), Nx);
end

if isfield(gps,'comp_time') && length(gps.comp_time) ~= length(gps.sync_gps_time)
  warning('Length of comp_time does not match sync_gps_time.\n', length(gps.comp_time), length(gps.sync_gps_time));
  fprintf(fid,'  Length of comp_time does not match sync_gps_time.!!!\n', length(gps.comp_time), length(gps.sync_gps_time));
end
if isfield(gps,'radar_time') && length(gps.radar_time) ~= length(gps.sync_gps_time)
  warning('Length of radar_time does not match sync_gps_time.\n', length(gps.radar_time), length(gps.sync_gps_time));
  fprintf(fid,'  Length of radar_time does not match sync_gps_time.!!!\n', length(gps.radar_time), length(gps.sync_gps_time));
end
if isfield(gps,'sync_lat') && length(gps.sync_lat) ~= length(gps.sync_gps_time)
  warning('Length of sync_lat does not match sync_gps_time.\n', length(gps.sync_lat), length(gps.sync_gps_time));
  fprintf(fid,'  Length of sync_lat does not match sync_gps_time.!!!\n', length(gps.sync_lat), length(gps.sync_gps_time));
end
if isfield(gps,'sync_lon') && length(gps.sync_lon) ~= length(gps.sync_gps_time)
  warning('Length of sync_lon does not match sync_gps_time.\n', length(gps.sync_lon), length(gps.sync_gps_time));
  fprintf(fid,'  Length of sync_lon does not match sync_gps_time.!!!\n', length(gps.sync_lon), length(gps.sync_gps_time));
end
if isfield(gps,'sync_elev') && length(gps.sync_elev) ~= length(gps.sync_gps_time)
  warning('Length of sync_elev does not match sync_gps_time.\n', length(gps.sync_elev), length(gps.sync_gps_time));
  fprintf(fid,'  Length of sync_elev does not match sync_gps_time.!!!\n', length(gps.sync_elev), length(gps.sync_gps_time));
end

%% lat, lon, elev
% =========================================================================
if any(gps.lat >= 90 | gps.lat <= -90)
  warning('lat out of bounds');
  fprintf(fid,'  lat out of bounds!!!');
end

if any(gps.lon >= 360 | gps.lon <= -360)
  warning('lon out of bounds');
  fprintf(fid,'  lon out of bounds!!!');
end

if any(gps.elev >= 40000 | gps.elev <= -10000)
  warning('elev out of bounds');
  fprintf(fid,'  elev out of bounds!!!');
end

%% roll, pitch, heading
% =========================================================================
if any(gps.roll >= param.gps_check.roll_limit/180*pi | gps.roll <= -param.gps_check.roll_limit/180*pi)
  warning('abs(roll) > %g deg: max %.1f min %.1f', param.gps_check.roll_limit, max(gps.roll)*180/pi, min(gps.roll)*180/pi);
  fprintf(fid,'  abs(roll) > %g deg: max %.1f min %.1f', param.gps_check.roll_limit, max(gps.roll)*180/pi, min(gps.roll)*180/pi);
end

if any(gps.pitch >= 25/180*pi | gps.pitch <= -25/180*pi)
  warning('abs(pitch) > 25 deg: max %.1f min %.1f', max(gps.pitch)*180/pi, min(gps.pitch)*180/pi);
  fprintf(fid,'  abs(pitch) > 25 deg: max %.1f min %.1f', max(gps.pitch)*180/pi, min(gps.pitch)*180/pi);
end

if any(gps.heading >= 2*pi | gps.heading <= -2*pi)
  warning('abs(heading) > 2*pi');
  fprintf(fid,'  abs(heading) > 2*pi');
end

%% Speed
% =========================================================================
speed = diff(along_track) ./ diff(gps.gps_time);

%% Sync GPS Time Plot
% =========================================================================
if isfield(gps,'sync_gps_time')
  dgps_time = diff(gps.sync_gps_time);
  
  nonmonotonic_idxs = find(dgps_time <= 0);
  if ~isempty(nonmonotonic_idxs)
    warning('%d indexes are nonmonotonically increasing with diff(sync_gps_time) <= 0', length(nonmonotonic_idxs));
    fprintf(fid,'  %d indexes are nonmonotonically increasing with diff(sync_gps_time) <= 0!!!', length(nonmonotonic_idxs));
  end
  
  skip_idxs = find(dgps_time > 1.1);
  if ~isempty(skip_idxs)
    warning('%d indexes skip more than 1 second with diff(sync_gps_time) <= 1.1. Largest is %g sec.', length(skip_idxs), max(dgps_time));
    fprintf(fid, '  %d indexes skip more than 1 second with diff(sync_gps_time) <= 1.1. Largest is %g sec.', length(skip_idxs), max(dgps_time));
  end
end

%% radar_time check
% =========================================================================
if isfield(gps,'radar_time')
  dgps_time = diff(gps.radar_time);
  
  nonmonotonic_idxs = find(dgps_time <= 0);
  if ~isempty(nonmonotonic_idxs)
    warning('%d indexes are nonmonotonically increasing with diff(radar_time) <= 0', length(nonmonotonic_idxs));
    fprintf(fid,'  %d indexes are nonmonotonically increasing with diff(radar_time) <= 0!!!', length(nonmonotonic_idxs));
  end
  
  skip_idxs = find(dgps_time > 1.1);
  if ~isempty(skip_idxs)
    warning('%d indexes skip more than 1 second with diff(radar_time) <= 1.1. Largest is %g sec.', length(skip_idxs), max(dgps_time));
    fprintf(fid, '  %d indexes skip more than 1 second with diff(radar_time) <= 1.1. Largest is %g sec.', length(skip_idxs), max(dgps_time));
  end
end

%% Cleanup
% =========================================================================

fclose(fid);

end
