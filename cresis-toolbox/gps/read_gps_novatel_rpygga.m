function gps = read_gps_novatel_rpygga(in_fn, param)
% gps = read_gps_novatel_rpygga(in_fn, param)
%
% Reads in RPY and GGA files produced from the CRESIS Novatel system
% (e.g. 2009 Greenland TO).
%
% RPY file:
% 112049.00,-00.0869000000,008.5024000000,024.4317000000
% HHMMSS.SS,roll (deg),pitch (deg),heading (deg)
%
% GGA file:
% $GPGGA,112049.01,6549.0164857,N,03703.0877541,W,4,08,2.54,1044.132,M,50.606,M,,0100*73
%
% Input Args:
%   in_fn = string containing input RPY filename
%   param = tells the file GPS type and the year, month, day to determine
%     absolute time (GGA NMEA files just give the time of day)
%     .year
%     .month
%     .day
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
%   fn = '/cresis/data2/MCoRDS/2010_Antarctica/GPS_new/GGA/RevealGPS_20100103A';
%   gps = read_gps_nmea(fn, struct('year',2010,'month',1,'day',3));
%   plot(gps.lon,gps.lat);
%   datestr(epoch_to_datenum(gps.gps_time(1)));
%   gps.utc_time = gps.gps_time - utc_leap_seconds(gps.gps_time(1))
%   gps_plot(gps)
%
% Author: William Blake, John Paden, Anthony Hoch, Logan Smith
%
% See also read_gps_*.m, gps_plot.m, gps_create.m

global gRadar

debug_level = 1;

if ~exist('param','var') || isempty(param)
  error('Year, month, day must be specified in param struct');
end

[gps_time_hhmmss,roll,pitch,heading] ...
  = textread(in_fn,'%f%f%f%f','delimiter',',','headerlines',2);
roll = roll.' * pi/180;
pitch = pitch.' * pi/180;
heading = heading.' * pi/180;

% Convert HHMMSS format to ANSI-C standard, seconds since Jan 1 1970
sec = mod(gps_time_hhmmss,100);
min = mod([gps_time_hhmmss-sec]./100,100);
hour = [[gps_time_hhmmss-sec]./100 - min]./100;
gps_time = datenum_to_epoch(datenum(param.year,param.month,param.day,hour,min,sec)).';

% ===================================================================
% Find jumps in the GPS time that are probably due to day interval
% 86400 seconds.
day_jumps = find(diff(gps_time) < -86000);
for jump_idx = day_jumps
  gps_time(jump_idx+1:end) = gps_time(jump_idx+1:end) + 86400;
end

% ===================================================================
% Read in GGA file
param.format = 1;
gps = read_gps_nmea(param.gga_fns,param);

% ===================================================================
% Store outputs in structure
% ===================================================================
if strcmpi(param.time_reference,'utc')
  % UTC time stored in file, so need to add leap seconds back in
  gps_time = gps_time + utc_leap_seconds(gps_time(1));
end

gps.roll = interp1(gps_time,roll,gps.gps_time);
gps.pitch = interp1(gps_time,pitch,gps.gps_time);
gps.heading = interp1(gps_time,heading,gps.gps_time);

return;
