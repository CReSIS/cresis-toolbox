function gps = read_gps_txt(in_fn, param)
% gps = read_gps_txt(in_fn, param)
%
% Reads in .xyz files from Sanders Geophysics Gravimeter group.
%
% Format:
%   DATE    DAY  UTCSECOND   PITCH      ROLL     HEADING     LAT           LONG                 UPSX           UPSY    WGSHGT           
%   20110316  075  37954.00     0.324     0.442   178.276     76.5352757    -68.7202024      600831.40     1455055.22     81.34           
%
% Input Args:
%   in_fn (string) input .txt filename
%   param = control parameter structure
%     .time_reference = 'gps' or 'utc' (should always be 'utc')
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
%   fn = 'C:\NASA\2011_Greenland_P3\AIRGrav_Attitude_Flight_010.xyz';
%   gps = read_gps_txt(fn, struct('time_reference','utc'));
%   plot(gps.lon,gps.lat);
%   datestr(epoch_to_datenum(gps.gps_time(1)));
%   gps.utc_time = gps.gps_time - utc_leap_seconds(gps.gps_time(1))
%   gps_plot(gps)
%
% Author: John Paden
%
% See also read_gps_*.m, gps_plot.m, gps_create.m

debug_level = 1;

[date_val day time_sod pitch roll heading lat lon upsx upsy elev] = ...
     textread(in_fn,'%f%f%f%f%f%f%f%f%f%f%f','emptyvalue',NaN,'headerlines',6);

% ENSURE ALL VECTORS IN 1xN FORMAT
date_val = reshape(date_val,[1 length(date_val)]);
time_sod = reshape(time_sod,[1 length(time_sod)]);
lat = reshape(lat,[1 length(lat)]);
lon = reshape(lon,[1 length(lon)]);
elev = reshape(elev,[1 length(elev)]);
roll = reshape(roll,[1 length(roll)]);
pitch = reshape(pitch,[1 length(pitch)]);
heading = reshape(heading,[1 length(heading)]);

year = floor(date_val/10000);
month = floor((date_val - year*10000)/100);
day = date_val - year*10000 - month*100;
% An interesting quirk of the data file is that the day field may increment
% but the time_sod does not always wrap over to zero seconds like it
% should when this happens
day_skips = find(diff(day) > 0);
while ~isempty(day_skips)
  % Detect if there is NOT a backward jump in GPS time at the day skip
  % and subtract a day worth of seconds if that is the case
  if time_sod(day_skips(1)+1) - time_sod(day_skips(1)) > 0
    time_sod(day_skips(1)+1:end) = time_sod(day_skips(1)+1:end) - 86400;
  end
  day_skips = day_skips(2:end);
end
gps.gps_time = datenum_to_epoch(datenum(year,month,day,zeros(size(year)),zeros(size(year)),time_sod));

% ===================================================================
% Store outputs in structure
% ===================================================================
if strcmpi(param.time_reference,'utc')
  % UTC time stored in file, so need to add leap seconds back in
  gps.gps_time = gps.gps_time + utc_leap_seconds(gps.gps_time(1));
else
  fprintf('XYZ file from gravimeter group is usually UTC\n');
end

gps.lat = lat;
gps.lon = lon;
gps.elev = elev;
gps.roll = roll/180*pi;
gps.pitch = pitch/180*pi;
gps.heading = heading/180*pi;

return;
