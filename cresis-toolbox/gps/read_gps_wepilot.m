function gps = read_gps_mat(in_fn, param)
% gps = read_gps_mat(in_fn, param)
%
% Reads in Matlab mat files. A generic Variable and Attribute mapping is
% possible with the param structure. Includes wePilot.
%
% Input Args:
%   in_fn (string) input .mat filename
%   param = control parameter structure
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
%   See make_gps_2016_Greenland_G1XB.m
%
%   fn = 'E:\tmp\uav_gps_imu\weData_20160413_1851AUX.mat';
%   gps = read_gps_wepilot(fn);
%
% Author: John Paden
%
% See also read_gps_*.m, gps_plot.m, gps_create.m

load(in_fn);

gps = [];

if any(strcmp(OnBoard.signals.labels,'UTCYEAR'))
  utc_year = OnBoard.signals.values(:,find(strcmp(OnBoard.signals.labels,'UTCYEAR')));
  utc_month = OnBoard.signals.values(:,find(strcmp(OnBoard.signals.labels,'UTCMONTH')));
  utc_day = OnBoard.signals.values(:,find(strcmp(OnBoard.signals.labels,'UTCDAY')));
  utc_hours = OnBoard.signals.values(:,find(strcmp(OnBoard.signals.labels,'UTCHOURS')));
  utc_min = OnBoard.signals.values(:,find(strcmp(OnBoard.signals.labels,'UTCMIN')));
  utc_sec = OnBoard.signals.values(:,find(strcmp(OnBoard.signals.labels,'UTCSEC')));
  utc_time = datenum(utc_year,utc_month,utc_day,utc_hours,utc_min,utc_sec);
  datestr(utc_time(1))
  gps.gps_time = datenum_to_epoch(utc_time);
  gps.gps_time = gps.gps_time + utc_leap_seconds(gps.gps_time(1));
  
  relative_time = OnBoard.signals.values(:,find(strcmp(OnBoard.signals.labels,'TIME')));
  relative_time = relative_time-relative_time(1);
  
  old_gps_time = gps.gps_time(1);
  for gps_idx = 2:length(gps.gps_time)
    if (gps.gps_time(gps_idx) - old_gps_time) < 1e-3
      gps.gps_time(gps_idx) = gps.gps_time(gps_idx-1) + (relative_time(gps_idx) - relative_time(gps_idx-1));
    else
      old_gps_time = gps.gps_time(gps_idx);
    end
  end
  
  gps_relative_time = gps.gps_time-gps.gps_time(1);
  relative_time = relative_time + median(gps_relative_time-relative_time);
  
  plot(gps_relative_time-relative_time,'.')
  pause;
  ref_idx = find(abs(gps_relative_time-relative_time)<1e-3,1);
  gps.gps_time = gps.gps_time(ref_idx) + relative_time - relative_time(ref_idx);
  
else
  gps_date = OnBoard.signals.values(:,find(strcmp(OnBoard.signals.labels,'GPSDATE')));
  gps_time = OnBoard.signals.values(:,find(strcmp(OnBoard.signals.labels,'GPSTIME')));
  error('Unsupported format');
  utc_time = datenum(utc_year,utc_month,utc_day,utc_hours,utc_min,utc_sec);
  datestr(utc_time(1))
  gps.gps_time = datenum_to_epoch(utc_time);
  gps.gps_time = gps.gps_time + utc_leap_seconds(gps.gps_time(1));
end

gps.roll = OnBoard.signals.values(:,find(strcmp(OnBoard.signals.labels,'ROLL')));
gps.pitch = OnBoard.signals.values(:,find(strcmp(OnBoard.signals.labels,'PITCH')));
gps.heading = OnBoard.signals.values(:,find(strcmp(OnBoard.signals.labels,'YAW')));
gps.lat = OnBoard.signals.values(:,find(strcmp(OnBoard.signals.labels,'LAT')))*180/pi;
gps.lon = OnBoard.signals.values(:,find(strcmp(OnBoard.signals.labels,'LON')))*180/pi;
gps.elev = OnBoard.signals.values(:,find(strcmp(OnBoard.signals.labels,'ALT')));

return;

fns = get_filenames('E:\tmp\uav_gps_imu','','','AUX.mat');
for fn_idx=1:length(fns)-1
  fns{fn_idx}
  gps = read_gps_wepilot(fns{fn_idx})
  gps_plot(gps);
  pause
end

% fns = get_filenames('E:\tmp\uav_gps_imu','','','AUX.mat');
% for fn_idx=1:length(fns)
%   gps = load(fns{fn_idx})
% end

% tmp = load('weData_010714_35MHz_flight3.mat');
% tmp.OnBoard = tmp.data;
% tmp = rmfield(tmp,'data');
% save('weData_201604XX_XXXAUX.mat','-struct','tmp');
