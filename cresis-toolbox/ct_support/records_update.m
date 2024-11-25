function records_update(param,param_override)
% records_update(param,param_override)
%
% This function updates the records according to the param struct. It
% really just resyncs the gps file to the records file. This is useful when
% the gps file is updated or the param.vectors.gps.time_offset is updated.
%
% params: parameter spreadsheet structure array
%
% Examples: See run_records_update.m
%
% Author: John Paden
%
% See also: run_all_records_update, run_records_update, records_update

param = merge_structs(param,param_override);

dbstack_info = dbstack;
fprintf('=====================================================================\n');
fprintf('%s: %s (%s)\n', dbstack_info(1).name, param.day_seg, datestr(now,'HH:MM:SS'));
fprintf('=====================================================================\n');

%% Prep (load records and gps files)
records_fn = ct_filename_support(param,'','records');
if cluster_job_check()
  error('records_update may not be called from cluster_job (gRadar.cluster.is_cluster_job is currently set to true). To remove this error, run records_update on: %s', records_fn);
end
if ~exist(records_fn,'file')
  warning('Records file does not exist: %s (%s).\n', records_fn, datestr(now));
  return;
end

records = load(records_fn);
if isfield(records,'settings') && isfield(records.settings,'wfs') && isfield(records.settings.wfs,'wfs')
  warning('Old records.settings format with "settings.wfs.wfs" field found in records file. Updating format.');
  records.settings.wfs = records.settings.wfs.wfs;
  if isfield(records.settings,'wfs_records')
    records.settings = rmfield(records.settings,'wfs_records');
  end
end
if isfield(records,'settings') && isfield(records.settings,'nyquist_zone_hw')
  warning('Old records.settings format with "settings.nyquist_zone_hw" field found in records file. Updating format.');
  records.nyquist_zone_hw = records.settings.nyquist_zone_hw;
  records.settings = rmfield(records.settings,'nyquist_zone_hw');
end
if isfield(records,'settings') && isfield(records.settings,'nyquist_zone')
  warning('Old records.settings format with "settings.nyquist_zone" field found in records file. Updating format.');
  records.nyquist_zone_sig = records.settings.nyquist_zone;
  records.settings = rmfield(records.settings,'nyquist_zone');
end
if isfield(records.param_records,'vectors')
  warning('Old parameter format with "vectors" field found in records file. Updating format.');
  records.param_records.records.file.start_idx = records.param_records.vectors.file.start_idx;
  records.param_records.records.file.stop_idx = records.param_records.vectors.file.stop_idx;
  records.param_records.records.file.base_dir = records.param_records.vectors.file.base_dir;
  records.param_records.records.file.board_folder_name = records.param_records.vectors.file.adc_folder_name;
  records.param_records.records.file.prefix = records.param_records.vectors.file.file_prefix;
  records.param_records.records.gps = records.param_records.vectors.gps;
  
  records.param_records.records.file.version = records.param_records.records.file_version;
  records.param_records.records.frames.geotiff_fn = records.param_records.records.geotiff_fn;
  records.param_records.records.frames.mode = records.param_records.records.frame_mode;
  records.param_records = rmfield(records.param_records,'vectors');
  try
    records.param_records.records.file = rmfield(records.param_records.records.file,'adcs');
  end
  try
    records.param_records.records.file = rmfield(records.param_records.records.file,'adc_headers');
  end
  try
    records.param_records.records.gps = rmfield(records.param_records.records.gps,'verification');
  end
  try
    records.param_records.records.gps = rmfield(records.param_records.records.gps,'fn');
  end
  if isfield(records.param_records.records.gps,'utc_time_halved') && isempty(records.param_records.records.gps.utc_time_halved)
    records.param_records.records.gps = rmfield(records.param_records.records.gps,'utc_time_halved');
  end
  try
    records.param_records.records = rmfield(records.param_records.records,'records_fn');
  end
  try
    records.param_records.records = rmfield(records.param_records.records,'force_all');
  end
  try
    records.param_records.records = rmfield(records.param_records.records,'frames_fn');
  end
  try
    records.param_records.records = rmfield(records.param_records.records,'geotiff_fn');
  end
  try
    records.param_records.records = rmfield(records.param_records.records,'frame_mode');
  end
  try
    records.param_records.records = rmfield(records.param_records.records,'debug_level');
  end
  try
    records.param_records.records = rmfield(records.param_records.records,'file_version');
  end
  try
    records.param_records.records = rmfield(records.param_records.records,'tmp_fn_uses_adc_folder_name');
  end
  try
    records.param_records.records = rmfield(records.param_records.records,'manual_time_correct');
  end
end

gps_fn = ct_filename_support(param,'','gps',1);

fprintf('  Using gps file %s\n', gps_fn);
gps = load(gps_fn);

%% Update the records
tmp_records = records;
if any(strcmpi(param.radar_name,{'accum2','mcrds'}))
  % Determine time offset delta and apply to radar time
  delta_offset = param.vectors.gps.time_offset - records.param_records.vectors.gps.time_offset
  records.param_records.vectors.gps.time_offset = param.vectors.gps.time_offset;
  records.raw.radar_time = records.raw.radar_time + delta_offset;
  
  % Find the section of the GPS file that is to be used for this record
  guard_time = 5;
  good_idxs = find(gps.comp_time >= records.raw.comp_time(1)-guard_time ...
    & gps.comp_time <= records.raw.comp_time(end)+guard_time);
  good_radar_time = gps.radar_time(good_idxs);
  good_sync_gps_time = gps.sync_gps_time(good_idxs);
  % From these good indexes, remove any repeat radar times (usually caused
  % by there being more than one NMEA string every 1 PPS
  good_idxs = 1+find(diff(good_radar_time) ~= 0);
  good_radar_time = good_radar_time(good_idxs);
  good_sync_gps_time = good_sync_gps_time(good_idxs);
  % Interpolate gps.sync_gps_time to records.gps_time using gps.radar_time
  % and records.radar_time
  records.gps_time = interp1(good_radar_time, good_sync_gps_time, ...
    records.raw.radar_time,'linear','extrap');
  
  % Interpolate to find new trajectory
  records.lat = double(interp1(gps.gps_time,gps.lat,records.gps_time));
  records.lon = double(mod(interp1(gps.gps_time,unwrap(gps.lon/180*pi),records.gps_time)*180/pi+180, 360)-180);
  records.elev = double(interp1(gps.gps_time,gps.elev,records.gps_time));
  records.roll = double(interp1(gps.gps_time,gps.roll,records.gps_time));
  records.pitch = double(interp1(gps.gps_time,gps.pitch,records.gps_time));
  records.heading = double(mod(interp1(gps.gps_time,unwrap(gps.heading),records.gps_time)+pi,2*pi)-pi);
  records.gps_source = gps.gps_source;
else
  % Determine time offset delta and apply to radar time
  if ~isfinite(param.records.gps.time_offset)
    warning('param.records.gps.time_offset must be finite. Trying to load value from spreadsheet.');
    try
      new_param = read_param_xls(param);
      param.records.gps.time_offset = new_param.records.gps.time_offset;
    catch ME
      error('param.records.gps.time_offset must be finite. Call records_update with a finite value.');
    end
    if ~isfinite(param.records.gps.time_offset)
      error('param.records.gps.time_offset must be finite. Call records_update with a finite value.');
    end
  end
  if ~isfinite(records.param_records.records.gps.time_offset)
    warning('records.param_records.records.gps.time_offset must be finite. Assuming that it is equal to param.records.gps.time_offset.');
    records.param_records.records.gps.time_offset = param.records.gps.time_offset;
  end
  delta_offset = max(param.records.gps.time_offset) - max(records.param_records.records.gps.time_offset);
  records.param_records.records.gps.time_offset = param.records.gps.time_offset;
  records.gps_time = records.gps_time + delta_offset;
  
  % Interpolate to find new trajectory
  records.lat = interp1(gps.gps_time, gps.lat, records.gps_time);
  records.lon = mod(interp1(gps.gps_time,unwrap(gps.lon/180*pi),records.gps_time)*180/pi+180, 360)-180;
  records.elev = interp1(gps.gps_time, gps.elev, records.gps_time);
  records.roll = interp1(gps.gps_time, gps.roll, records.gps_time);
  records.pitch = interp1(gps.gps_time, gps.pitch, records.gps_time);
  records.heading = mod(interp1(gps.gps_time,unwrap(gps.heading),records.gps_time)+pi,2*pi)-pi;
  records.gps_source = gps.gps_source;
end

fprintf('  Delta GPS time offset is %.1f sec\n', delta_offset);

if isfield(records,'surface')
  warning('Removing defunct field "surface" from records.');
  records = rmfield(records,'surface');
end

%% Save outputs
fprintf('  Saving records %s\n', records_fn);
if isfield(param,'ct_file_lock') && param.ct_file_lock
  records.file_version = '1L';
else
  records.file_version = '1';
end
records.file_type = 'records';
ct_save(records_fn,'-v7.3','-struct','records');

%% Update reference trajectory
ref_fn_dir = ct_filename_out(param,'reference_trajectory','',1);
ref_fn = fullfile(ref_fn_dir,sprintf('ref_%s.mat', param.day_seg));
% Only update the file if it exists
if exist(ref_fn,'file')
  fprintf('  Updating reference trajectory %s\n', ref_fn);
  records_reference_trajectory(param,param_override);
end
