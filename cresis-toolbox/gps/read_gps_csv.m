function gps = read_gps_csv(in_fn, param)
% gps = read_gps_csv(in_fn, param)
%
% Reads in .csv files from:
%  1. flight_tracker.m (which reads and saves NMEA strings).
%  2. Canadian CSRS_PPP xlsx files which are converted to CSV
%
% Format:
%   year	month	day	UTC_sod	latNdeg	lonEdeg	elevm
%   2011	4	15	34269	67.010721	-50.702475	52.1467
%
% Input Args:
%   in_fn (string) input .csv filename
%   param = control parameter structure
%     .time_reference = 'gps' or 'utc' (should always be 'utc')
%     .type = 1 (default) flight_tracker.m
%             2 (Canadian CSRS_PPP)
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
%   fn = 'C:\NASA\2011_Greenland_P3\gps_20110415.csv';
%   gps = read_gps_csv(fn, struct('time_reference','utc'));
%   plot(gps.lon,gps.lat);
%   datestr(epoch_to_datenum(gps.gps_time(1)));
%   gps.utc_time = gps.gps_time - utc_leap_seconds(gps.gps_time(1))
%   gps_plot(gps)
%
%   fn = 'I:\trimbleGPS\CSRS_PPP\28631210.csv';
%   gps = read_gps_csv(fn, struct('time_reference','utc','type',2));
%   plot(gps.lon,gps.lat);
%   datestr(epoch_to_datenum(gps.gps_time(1)));
%   gps.utc_time = gps.gps_time - utc_leap_seconds(gps.gps_time(1))
%   gps_plot(gps)
%
% Author: John Paden
%
% See also read_gps_*.m, gps_plot.m, gps_create.m

debug_level = 1;

if ~isfield(param,'type')
  param.type = 1;
end

if param.type == 1
  [year month day time_sod lat lon elev] = ...
       textread(in_fn,'%f%f%f%f%f%f%f','delimiter',',','emptyvalue',NaN,'headerlines',1);

  % ENSURE ALL VECTORS IN 1xN FORMAT
  year = reshape(year,[1 length(year)]);
  month = reshape(month,[1 length(month)]);
  day = reshape(day,[1 length(day)]);
  time_sod = reshape(time_sod,[1 length(time_sod)]);
  lat = reshape(lat,[1 length(lat)]);
  lon = reshape(lon,[1 length(lon)]);
  elev = reshape(elev,[1 length(elev)]);

  gps.gps_time = datenum_to_epoch(datenum(year,month,day,zeros(size(year)),zeros(size(year)),time_sod));

elseif param.type == 2
  [lat lon elev hour day year ortho] = ...
       textread(in_fn,'%f%f%f%f%f%f%s','delimiter',',','emptyvalue',NaN,'headerlines',1);

  % ENSURE ALL VECTORS IN 1xN FORMAT
  year = reshape(year,[1 length(year)]);
  day = reshape(day,[1 length(day)]);
  hour = reshape(hour,[1 length(hour)]);
  lat = reshape(lat,[1 length(lat)]);
  lon = reshape(lon,[1 length(lon)]);
  elev = reshape(elev,[1 length(elev)]);

  gps.gps_time = datenum_to_epoch(datenum(year,zeros(size(year)),day,hour,zeros(size(year)),zeros(size(year))));
elseif param.type == 3% as we need a new branch to process this param type 
  [year day time lat lon elev roll pitch heading]=...
        textread(in_fn,'%f%f%f%f%f%f%f%f%f','delimiter',',','emptyvalue',NaN,'headerlines',1);
  year = reshape(year,[1 length(year)]);
  day = reshape(day,[1 length(day)]);
  time= reshape(time,[1 length(time)]);
  lat = reshape(lat,[1 length(lat)]);
  lon = reshape(lon,[1 length(lon)]);
  elev = reshape(elev,[1 length(elev)]);  
  gps.gps_time=time;
  
else
  error('Unsupported param type %d', param.type);
end
  
% ===================================================================
% Store outputs in structure
% ===================================================================
if strcmpi(param.time_reference,'utc')
  % UTC time stored in file, so need to add leap seconds back in
  gps.gps_time = gps.gps_time + utc_leap_seconds(gps.gps_time(1));
else
  fprintf('CSV file from flight_tracker.m is usually UTC\n');
end

gps.lat = lat;
gps.lon = lon;
gps.elev = elev;
gps.roll = zeros(size(lat));
gps.pitch = zeros(size(lat));
gps.heading = zeros(size(lat));

% ===================================================================
% Find jumps in the GPS time that are probably due to day interval
% 86400 seconds.
day_jumps = find(diff(gps.gps_time) < -70000);
for jump_idx = day_jumps
  gps.gps_time(jump_idx+1:end) = gps.gps_time(jump_idx+1:end) + 86400;
end

return;
