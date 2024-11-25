function gps = read_gps_netcdf(in_fn, param)
% gps = read_gps_netcdf(in_fn, param)
%
% Reads in netcdf files. A generic Variable and Attribute mapping is
% possible with the param structure. Includes AWI netcdf.
%
% Input Args:
%   in_fn (string) input .nc filename
%   param = control parameter structure
%     .time_reference = 'gps' or 'utc' (should always be 'utc' if from AWI)
%     .nc_fields: Nf element cell array of strings which contain the
%       variable or attribute that is to be read. This is the name in the
%       netcdf file that is being read.
%     .nc_type: Nf element cell array corresponding to nc_fields that holds
%       either 'v' or 'a' to indicate the field is a variable or an
%       attribute
%     .types: Nf element cell array corresponding to nc_fields that holds
%       the field type string for each field. Valid field types are:
%       'year'
%       'month'
%       'day'
%       'hour'
%       'minute'
%       'sec'
%       'mjd_18581117'
%       'lat_deg'
%       'lon_deg'
%       'elev_m'
%       'roll_deg'
%       'pitch_deg'
%       'heading_deg'
%      .scale: optional field which defaults to one. If specified, it
%        should be an Nf element matrix corresponding to nc_fields that
%        holds a double value which will be applied as a multiplicative
%        scaling factor to the values read in from the file. This causes
%        the fields in the file to be converted to double.
%      .scale_en: optional field which defaults to true. If specified, it
%        should be an Nf element matrix corresponding to nc_fields that holds
%        a boolean value indicating whether or not a field should be scaled
%        by the scaling factor.
%      .custom_flag: optional field which defaults to false. If specified,
%        it should be an Nf element cell array corresponding to nc_fields
%        that holds the flag value for each field. If true, then field will
%        be copied directly to the output with no checking or processing.
%        Additional checking and processing may occur if the "types" field
%        is set to one of the valid field types.
%      .reshape_en: optional field which defaults to true. Fields are
%        reshaped to be row vectors. Ignored for noncustom fields. If
%        specified, it should be an Nf element matrix corresponding to
%        nc_fields that holds a boolean value indicating whether or not a
%        field should be reshaped.
%
% Output Args:
% gps = output structure with fields
%  .time = GPS time in seconds since Jan 1, 1970 epoch (sec)
%  .lat = latitude (deg)
%  .lon = longitude (deg)
%  .elev = elevation (m)
%  .roll = roll (rad)
%  .pitch = pitch (rad)
%  .heading = true heading (rad)
%
% Example:
%   See make_gps_2015_Greenland_Polar6.m
%
%   param = struct('time_reference','utc');
%   param.nc_field = {'TIME','LATITUDE','LONGITUDE','ELEVATION','MJD'};
%   param.nc_type = {'v','v','v','v','v'};
%   param.types = {'sec','lat_deg','lon_deg','elev_m','mjd_18581117'};
%   param.scale = [1 1 1 1 1 1 1];
%   fn = '/cresis/snfs1/dataproducts/metadata/AWI_lidar/2015_Greenland_Polar6/ALS_L1B_20150911T134604_141010_cb.nc';
%   gps = read_gps_netcdf(fn,param);
%
% Author: John Paden
%
% See also read_gps_*.m, gps_plot.m, gps_create.m

%% Check Inputs
if ~isfield(param,'scale') || isempty(param.scale)
  param.scale = ones(size(param.types));
end

if ~isfield(param,'scale_en') || isempty(param.scale_en)
  param.scale_en = ones(size(param.types));
end

if ~isfield(param,'custom_flag') || isempty(param.custom_flag)
  param.custom_flag = zeros(size(param.types));
end

if ~isfield(param,'reshape_en') || isempty(param.reshape_en)
  param.reshape_en = ones(size(param.types));
end

%% Initialize output
gps = [];

%% Convert from cell to struct/fieldnames for better readability below
tmp_gps = [];
for idx = 1:length(param.types)
  % Reading variable or attribute
  if strcmpi(param.nc_type{idx},'v')
    tmp_gps.(param.types{idx}) = ncread(in_fn,param.nc_field{idx});
  elseif strcmpi(param.nc_type{idx},'a')
    tmp_gps.(param.types{idx}) = ncreadatt(in_fn, '/', param.nc_field{idx});
    
  else
    error('Invalid type (%s) in field %d', param.nc_type{idx}, idx);
  end
  
  % Convert to double and apply scaling factor
  if param.scale_en(idx)
    tmp_gps.(param.types{idx}) = double(tmp_gps.(param.types{idx})) * param.scale(idx);
  end
  
  if param.reshape_en(idx)
    tmp_gps.(param.types{idx}) = reshape(tmp_gps.(param.types{idx}),[1 numel(tmp_gps.(param.types{idx}))]);
  end
  
  if param.custom_flag(idx)
    % Write directly to output for custom fields
    gps.(param.types{idx}) = tmp_gps.(param.types{idx});
  end
end

%% Interpret fields that were read in and create the output "gps" struct
num_rows = -1;

% Create gps time field
if isfield(tmp_gps,'year')
  year = tmp_gps.year;
elseif isfield(param,'year')
  year = param.year;
else
  year = 0;
end
if isfield(tmp_gps,'month')
  month = tmp_gps.month;
elseif isfield(param,'month')
  month = param.month;
else
  month = 0;
end
if isfield(tmp_gps,'day')
  day = tmp_gps.day;
elseif isfield(param,'day')
  day = param.day;
else
  day = 0;
end
if isfield(tmp_gps,'mjd_18581117')
  % Modified Julian date relative to Nov 17, 1858
  % May also include a fractional time of day field
  year = 1858;
  month = 11;
  day = 17 + floor(tmp_gps.mjd_18581117);
  sec = 86400 * mod(tmp_gps.mjd_18581117,1);
end
if isfield(tmp_gps,'hour')
  hour = tmp_gps.hour;
else
  hour = 0;
end
if isfield(tmp_gps,'minute')
  minute = tmp_gps.minute;
else
  minute = 0;
end
if isfield(tmp_gps,'sec')
  sec = tmp_gps.sec;
else
  sec = 0;
end
gps.gps_time = datenum_to_epoch(datenum(year,month,day,hour,minute,sec));

% Look for trajectory fields
if isfield(tmp_gps,'lat_deg')
  if num_rows == -1
    num_rows = length(tmp_gps.lat_deg);
  elseif length(tmp_gps.lat_deg) < num_rows
    tmp_gps.lat_deg(end+1:num_rows) = NaN;
  elseif length(tmp_gps.lat_deg) < num_rows
    tmp_gps.lat_deg = tmp_gps.lat_deg(1:num_rows);
  end
  gps.lat = tmp_gps.lat_deg;
end
if isfield(tmp_gps,'lon_deg')
  if num_rows == -1
    num_rows = length(tmp_gps.lon_deg);
  elseif length(tmp_gps.lon_deg) < num_rows
    tmp_gps.lon_deg(end+1:num_rows) = NaN;
  elseif length(tmp_gps.lon_deg) < num_rows
    tmp_gps.lon_deg = tmp_gps.lon_deg(1:num_rows);
  end
  gps.lon = tmp_gps.lon_deg;
end
if isfield(tmp_gps,'elev_m')
  if num_rows == -1
    num_rows = length(tmp_gps.elev_m);
  elseif length(tmp_gps.elev_m) < num_rows
    tmp_gps.elev_m(end+1:num_rows) = NaN;
  elseif length(tmp_gps.elev_m) < num_rows
    tmp_gps.elev_m = tmp_gps.elev_m(1:num_rows);
  end
  gps.elev = tmp_gps.elev_m;
end

% Look for attitude fields
if isfield(tmp_gps,'roll_deg')
  if num_rows == -1
    num_rows = length(tmp_gps.roll_deg);
  elseif length(tmp_gps.roll_deg) < num_rows
    tmp_gps.roll_deg(end+1:num_rows) = NaN;
  elseif length(tmp_gps.roll_deg) < num_rows
    tmp_gps.roll_deg = tmp_gps.roll_deg(1:num_rows);
  end
  gps.roll = tmp_gps.roll_deg/180*pi;
end
if isfield(tmp_gps,'pitch_deg')
  if num_rows == -1
    num_rows = length(tmp_gps.pitch_deg);
  elseif length(tmp_gps.pitch_deg) < num_rows
    tmp_gps.pitch_deg(end+1:num_rows) = NaN;
  elseif length(tmp_gps.pitch_deg) < num_rows
    tmp_gps.pitch_deg = tmp_gps.pitch_deg(1:num_rows);
  end
  gps.pitch = tmp_gps.pitch_deg/180*pi;
end
if isfield(tmp_gps,'heading_deg')
  if num_rows == -1
    num_rows = length(tmp_gps.heading_deg);
  elseif length(tmp_gps.heading_deg) < num_rows
    tmp_gps.heading_deg(end+1:num_rows) = NaN;
  elseif length(tmp_gps.heading_deg) < num_rows
    tmp_gps.heading_deg = tmp_gps.heading_deg(1:num_rows);
  end
  gps.heading = tmp_gps.heading_deg/180*pi;
end

%% Final clean up to make sure all fields are present
if isfield(gps,'gps_time')
  if strcmpi(param.time_reference,'utc')
    % UTC time stored in file, so need to add leap seconds back in
    gps.gps_time = gps.gps_time + utc_leap_seconds(gps.gps_time(1));
  end
else
  gps.gps_time = NaN*zeros(1,num_rows);
end

if ~isfield(gps,'lat')
  gps.lat = NaN*zeros(1,num_rows);
end

if ~isfield(gps,'lon')
  gps.lon = NaN*zeros(1,num_rows);
end
% Wrap longitude to +/-180 deg
gps.lon = mod(gps.lon+180,360) - 180;

if ~isfield(gps,'elev')
  gps.elev = NaN*zeros(1,num_rows);
end

if ~isfield(gps,'roll')
  gps.roll = zeros(1,num_rows);
end

if ~isfield(gps,'pitch')
  gps.pitch = zeros(1,num_rows);
end

if ~isfield(gps,'heading')
  gps.heading = zeros(1,num_rows);
end

return;
