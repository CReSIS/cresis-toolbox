function gps = gps_load(gps_fn)
% gps = gps_load(gps_fn)
%
% gps_load('/cresis/snfs1/dataproducts/csarp_support/gps/2019_Antarctica_Ground/gps_20200107.mat');
%
% Author: John Paden
%
% See also: gps_check, gps_load, gps_create

gps = load(gps_fn);
old_gps = gps;

%% Update header fields
if ~isfield(gps,'file_version') || isempty(gps.file_version)
  warning('gps file missing file_version field. Adding field.');
  gps.file_version = '0';
end

file_version = gps.file_version(isstrprop(gps.file_version,'digit'));
if str2double(file_version) < 2
  warning('gps file is old file_version. Updating field.');
  if any(file_version == 'L')
    gps.file_version = '2L';
  else
    gps.file_version = '2';
  end
end

if ~isfield(gps,'season_name') || isempty(gps.season_name)
  warning('gps file missing season_name field. Adding field.');
  % Default param.season_name is the directory where the file is if the
  % file is in the standard location.
  [gps_fn_dir,gps_fn_name] = fileparts(gps_fn);
  [~,gps.season_name] = fileparts(gps_fn_dir);
  % Verify param.season_name
  if 0
    season_name = input(sprintf('gps_load: Please enter the season name [%s]: ',gps.season_name),'s');
    if ~all(isstrprop(season_name,'white'))
      gps.season_name = season_name;
    end
  end
end

if ~isfield(gps,'date_str') || isempty(gps.date_str)
  warning('gps file missing date_str field. Adding field.');
  % Default param.date_str is in the gps filename by default.
  gps.date_str = gps_fn_name(5:end);
  if 0
    date_str = input(sprintf('gps_load: Please enter the date string (YYYYMMDD) [%s]: ',gps.date_str),'s');
    if ~all(isstrprop(date_str,'white'))
      gps.date_str = date_str;
    end
  end
end

if ~isfield(gps,'file_type') || isempty(gps.file_type)
  warning('gps file missing file_type field. Adding field.');
  gps.file_type = 'gps';
end

if ~isfield(gps,'gps_source') || isempty(gps.gps_source)
  warning('gps file missing gps_source field. Adding field.');
  gps.gps_source = '';
end

if ~isfield(gps,'sw_version') || isempty(gps.sw_version)
  warning('gps file missing sw_version field. Adding field.');
  gps.sw_version = current_software_version;
end

%% correct shape of vectors (1xN arrays)
if size(gps.gps_time,1) > 1
  warning('gps file has column vector for gps_time. Making into row vector.');
  gps.gps_time = gps.gps_time(:).';
end
if size(gps.lat,1) > 1
  warning('gps file has column vector for lat. Making into row vector.');
  gps.lat = gps.lat(:).';
end
if size(gps.lon,1) > 1
  warning('gps file has column vector for lon. Making into row vector.');
  gps.lon = gps.lon(:).';
end
if size(gps.elev,1) > 1
  warning('gps file has column vector for elev. Making into row vector.');
  gps.elev = gps.elev(:).';
end
if size(gps.roll,1) > 1
  warning('gps file has column vector for roll. Making into row vector.');
  gps.roll = gps.roll(:).';
end
if size(gps.pitch,1) > 1
  warning('gps file has column vector for pitch. Making into row vector.');
  gps.pitch = gps.pitch(:).';
end
if size(gps.heading,1) > 1
  warning('gps file has column vector for heading. Making into row vector.');
  gps.heading = gps.heading(:).';
end
if isfield(gps,'radar_time') && size(gps.radar_time,1) > 1
  warning('gps file has column vector for radar_time. Making into row vector.');
  gps.radar_time = gps.radar_time(:).';
end
if isfield(gps,'comp_time') && size(gps.comp_time,1) > 1
  warning('gps file has column vector for comp_time. Making into row vector.');
  gps.comp_time = gps.comp_time(:).';
end
if isfield(gps,'sync_gps_time') && size(gps.sync_gps_time,1) > 1
  warning('gps file has column vector for sync_gps_time. Making into row vector.');
  gps.sync_gps_time = gps.sync_gps_time(:).';
end
if isfield(gps,'sync_lat') && size(gps.sync_lat,1) > 1
  warning('gps file has column vector for sync_lat. Making into row vector.');
  gps.sync_lat = gps.sync_lat(:).';
end
if isfield(gps,'sync_lon') && size(gps.sync_lon,1) > 1
  warning('gps file has column vector for sync_lon. Making into row vector.');
  gps.sync_lon = gps.sync_lon(:).';
end
if isfield(gps,'sync_elev') && size(gps.sync_elev,1) > 1
  warning('gps file has column vector for sync_elev. Making into row vector.');
  gps.sync_elev = gps.sync_elev(:).';
end

%% Remove nonmonotonically increasing records
tmp_gps = struct('gps_time',gps.gps_time);
tmp_gps.lat = gps.lat;
tmp_gps.lon = gps.lon;
tmp_gps.elev = gps.elev;
tmp_gps.roll = gps.roll;
tmp_gps.pitch = gps.pitch;
tmp_gps.heading = gps.heading;
[tmp_gps,error_flag] = gps_force_monotonic(tmp_gps);
if error_flag
  warning('gps file has nonmonotonic records. Correcting.');
  gps.gps_time = tmp_gps.gps_time;
  gps.lat = tmp_gps.lat;
  gps.lon = tmp_gps.lon;
  gps.elev = tmp_gps.elev;
  gps.roll = tmp_gps.roll;
  gps.pitch = tmp_gps.pitch;
  gps.heading = tmp_gps.heading;
end
%% Remove records with NaN in gps_time or trajectory
good_mask = ~(isnan(gps.gps_time) | isnan(gps.lat) ...
  | isnan(gps.lon) | isnan(gps.elev));
if any(~good_mask)
  warning('gps file has NaN gps_time or trajectory. Removing.');
  gps.gps_time = gps.gps_time(good_mask);
  gps.lat = gps.lat(good_mask);
  gps.lon = gps.lon(good_mask);
  gps.elev = gps.elev(good_mask);
  gps.roll = gps.roll(good_mask);
  gps.pitch = gps.pitch(good_mask);
  gps.heading = gps.heading(good_mask);
end

%% Interpolate through NaN attitude data
good_mask = ~(isnan(gps.roll) | isnan(gps.pitch) | isnan(gps.heading));
if any(~good_mask)
  warning('gps file has NaN attitute. Interpolating.');
  gps.roll = interp_finite(gps.roll,0);
  gps.pitch = interp_finite(gps.pitch,0);
  gps.heading = interp_finite(gps.heading,0,@gps_interp1);
end

%% sync_gps_time
if isfield(gps,'sync_gps_time')
  %% sync_gps_time: Remove nonmonotonically increasing records
  sync_gps = struct('gps_time',gps.sync_gps_time);
  sync_gps.lat = gps.sync_lat;
  sync_gps.lon = gps.sync_lon;
  sync_gps.elev = gps.sync_elev;
  if isfield(gps,'radar_time')
    sync_gps.radar_time = gps.radar_time;
  end
  if isfield(gps,'comp_time')
    sync_gps.comp_time = gps.comp_time;
  end
  [sync_gps,error_flag] = gps_force_monotonic(sync_gps);
  if error_flag
    warning('gps file has nonmonotonic sync_gps_time or radar_time records. Correcting.');
  end

  %% sync_gps_time: Remove records with NaN in gps_time or trajectory
  if isfield(sync_gps,'radar_time')
    good_mask = ~(isnan(sync_gps.gps_time) | isnan(sync_gps.radar_time));
  else
    good_mask = ~(isnan(sync_gps.gps_time) | isnan(sync_gps.comp_time));
  end
  if any(~good_mask)
    warning('gps file has NaN sync_gps_time. Removing.');
    if isfield(sync_gps,'radar_time')
      sync_gps.radar_time = sync_gps.radar_time(good_mask);
    end
    sync_gps.gps_time = sync_gps.gps_time(good_mask);
    sync_gps.comp_time = sync_gps.comp_time(good_mask);
    sync_gps.lat = sync_gps.lat(good_mask);
    sync_gps.lon = sync_gps.lon(good_mask);
    sync_gps.elev = sync_gps.elev(good_mask);
  end
  
  %% sync_gps_time: Update
  if error_flag || any(~good_mask)
    gps.sync_gps_time = sync_gps.gps_time;
    gps.sync_lat = sync_gps.lat;
    gps.sync_lon = sync_gps.lon;
    gps.sync_elev = sync_gps.elev;
    gps.comp_time = sync_gps.comp_time;
    if isfield(gps,'radar_time')
      gps.radar_time = sync_gps.radar_time;
    end
  end
end

%% Save updated gps record
if ~isequal(gps,old_gps)
  if cluster_job_check()
    error('gps file needs to be updated but may not be from cluster_job (gRadar.cluster.is_cluster_job is currently set to true). To remove this error, run gps_load on: %s', gps_fn);
  end
  fprintf('  Saving updated gps file %s.\n', gps_fn);
  ct_save(gps_fn,'-struct','gps');
end
