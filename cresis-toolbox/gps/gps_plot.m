function gps = gps_plot(fn, plot_color, plot_est_heading)
% gps = gps_plot(fn OR gps, plot_color, plot_est_heading)
%
% Function for testing the quality of the GPS data.
%
% fn = Matlab file with standard GPS structure in it.
%   OR gps struct from read_gps_reveal, read_gps_applanix, etc.
% plot_color = If empty or left blank, all plots are cleared.
%   If specified (e.g. 'r', 'g', etc), some of the plots will be
%   added to rather than cleared.
% plot_est_heading = Plot estimated heading, takes a long time
%   don't pass or leave empty for default which is false
%
% Example:
%
% % Check csarp_support/gps file
% gps_plot('/cresis/snfs1/dataproducts/csarp_support/gps/2019_Antarctica_Ground/gps_20200107.mat');
%
% % Compare two GPS sources:
% fn = '/cresis/snfs1/dataproducts/csarp_support/gps/2009_Antarctica_DC8_GPS/20091018_ALL_pos.mat';
% gps_plot(fn);
% fn = '/cresis/snfs1/dataproducts/csarp_support/gps/2009_Antarctica_DC8_DGPSwINS/20091018_ALL_pos.mat';
% gps_plot(fn,'r');
%
% % Use GPS struct
% fn = '/cresis/data2/MCoRDS/2009_Chile/GPS/IWG1_110209.log';
% gps = read_gps_reveal(fn);
% gps_plot(gps);
%
% fn = '/cresis/scratch1/mdce/csarp_support/gps/2009_Antarctica_DC8_DGPSwINS/Javadsbet_02Nov09_PPP_Revised.out'
% gps = read_gps_applanix(fn,struct('year',2009,'month',11,'day',2));
% gps_plot(gps);
%
% Author: John Paden
%
% See also read_gps_*.m, gps_plot.m, gps_create.m

if ~exist('plot_est_heading','var') || isempty(plot_est_heading)
  plot_est_heading = false;
end

if ~exist('plot_color','var') || isempty(plot_color)
  plot_color = 'b';
  clear_figures = true;
else
  clear_figures = false;
end

if ischar(fn)
  gps = load(fn);
else
  gps = fn;
end

fprintf('Start: %s GPS\n', datestr(epoch_to_datenum(gps.gps_time(1))));
fprintf('Stop: %s GPS\n', datestr(epoch_to_datenum(gps.gps_time(end))));

leap_sec = utc_leap_seconds(gps.gps_time(1));
fprintf('Start: %s UTC\n', datestr(epoch_to_datenum(gps.gps_time(1) - leap_sec)));
fprintf('Stop: %s UTC\n', datestr(epoch_to_datenum(gps.gps_time(end) - leap_sec)));

if isfield(gps,'gps_source')
  fprintf('gps_source: %s\n', gps.gps_source);
else
  fprintf('gps_source: field does not exist\n');
end

% Get the GPS seconds of day to sync to radar
gps_time_datenum = epoch_to_datenum(gps.gps_time);
[year month day hour minute sec] = datevec(gps_time_datenum);

day_jumps = day-day(1);
day_jumps(day_jumps<0) = 1; % this is the case at month jump
GPS_sod = day_jumps*86400+hour*3600+minute*60+sec;  % GPS seconds of day

fig = 7;
if isfield(gps,'sync_gps_time')
  fig = fig+1;
end
if isfield(gps,'radar_time')
  fig = fig+1;
end
h_fig = get_figures(fig,true);
fig = 0;
h_axes = [];

%% Longitude vs Latitude Plot
fig = fig+1;
figure(h_fig(fig));
if clear_figures
  clf(h_fig(fig));
  h_axes(fig) = axes;
else
  tmp = get(h_fig(fig),'Children');
  if isa(tmp,'matlab.graphics.axis.Axes')
    h_axes(fig) = tmp(1);
  else
    h_axes(fig) = axes;
  end
end
plot(h_axes(fig), gps.lon, gps.lat, [plot_color '.']);
hold(h_axes(fig),'on');
grid(h_axes(fig),'on');
xlabel(h_axes(fig), 'Longitude, E (deg)');
ylabel(h_axes(fig), 'Latitude, N (deg)');
set(h_fig(fig),'Name','Trajectory');

med_sample_rate = median(diff(gps.gps_time));

skip_idxs = find(diff(gps.gps_time) > med_sample_rate*1.5);
fprintf('Approx. number of skips in gps time: %d\n', length(skip_idxs))
plot(h_axes(fig),gps.lon(skip_idxs), gps.lat(skip_idxs), 'ro');

repeat_idxs = find(diff(gps.gps_time) <= 0);
fprintf('Approx. number of repeats (non-monotonically increasing points in gps time):\n  %d\n', length(repeat_idxs))
plot(h_axes(fig),gps.lon(repeat_idxs), gps.lat(repeat_idxs), 'go');

if length(gps.lat) ~= length(gps.gps_time)
  fprintf(2,'Length of lat does not match gps_time.\n', length(gps.lat), length(gps.gps_time));
end
if length(gps.lon) ~= length(gps.gps_time)
  fprintf(2,'Length of lon does not match gps_time.\n', length(gps.lon), length(gps.gps_time));
end
if length(gps.elev) ~= length(gps.gps_time)
  fprintf(2,'Length of elev does not match gps_time.\n', length(gps.elev), length(gps.gps_time));
end
if length(gps.roll) ~= length(gps.gps_time)
  fprintf(2,'Length of roll does not match gps_time.\n', length(gps.roll), length(gps.gps_time));
end
if length(gps.pitch) ~= length(gps.gps_time)
  fprintf(2,'Length of pitch does not match gps_time.\n', length(gps.pitch), length(gps.gps_time));
end
if length(gps.heading) ~= length(gps.gps_time)
  fprintf(2,'Length of heading does not match gps_time.\n', length(gps.heading), length(gps.gps_time));
end

if ~isfield(gps,'sync_gps_time');
  warning('GPS file does not have sync_gps_time field.');
else
  if isfield(gps,'comp_time') && length(gps.comp_time) ~= length(gps.sync_gps_time)
    fprintf(2,'Length of comp_time does not match sync_gps_time.\n', length(gps.comp_time), length(gps.sync_gps_time));
  end
  if isfield(gps,'radar_time') && length(gps.radar_time) ~= length(gps.sync_gps_time)
    fprintf(2,'Length of radar_time does not match sync_gps_time.\n', length(gps.radar_time), length(gps.sync_gps_time));
  end
  if isfield(gps,'sync_lat') && length(gps.sync_lat) ~= length(gps.sync_gps_time)
    fprintf(2,'Length of sync_lat does not match sync_gps_time.\n', length(gps.sync_lat), length(gps.sync_gps_time));
  end
  if isfield(gps,'sync_lon') && length(gps.sync_lon) ~= length(gps.sync_gps_time)
    fprintf(2,'Length of sync_lon does not match sync_gps_time.\n', length(gps.sync_lon), length(gps.sync_gps_time));
  end
  if isfield(gps,'sync_elev') && length(gps.sync_elev) ~= length(gps.sync_gps_time)
    fprintf(2,'Length of sync_elev does not match sync_gps_time.\n', length(gps.sync_elev), length(gps.sync_gps_time));
  end
end

%% Elevation Plot
fig = fig+1;
figure(h_fig(fig));
if clear_figures
  clf(h_fig(fig));
  h_axes(fig) = axes;
else
  tmp = get(h_fig(fig),'Children');
  if isa(tmp,'matlab.graphics.axis.Axes')
    h_axes(fig) = tmp(1);
  else
    h_axes(fig) = axes;
  end
end
plot(h_axes(fig),GPS_sod,gps.elev,plot_color);
hold(h_axes(fig),'on');
grid(h_axes(fig),'on');
xlabel(h_axes(fig),'GPS\_sod');
ylabel(h_axes(fig),'Elevation (m)');
set(h_fig(fig),'Name','Elevation');

%% GPS Time Plot
fig = fig+1;
figure(h_fig(fig));
if clear_figures
  clf(h_fig(fig));
  h_axes(fig) = axes;
else
  tmp = get(h_fig(fig),'Children');
  if isa(tmp,'matlab.graphics.axis.Axes')
    h_axes(fig) = tmp(1);
  else
    h_axes(fig) = axes;
  end
end
plot(h_axes(fig),diff(gps.gps_time));
hold(h_axes(fig),'on');
grid(h_axes(fig),'on');
xlabel(h_axes(fig),'Index');
ylabel(h_axes(fig),'Time step (sec)');
set(h_fig(fig),'Name','Diff GPS_time');

%% Roll Plot
fig = fig+1;
figure(h_fig(fig));
if clear_figures
  clf(h_fig(fig));
  h_axes(fig) = axes;
else
  tmp = get(h_fig(fig),'Children');
  if isa(tmp,'matlab.graphics.axis.Axes')
    h_axes(fig) = tmp(1);
  else
    h_axes(fig) = axes;
  end
end
plot(h_axes(fig),GPS_sod,gps.roll*180/pi,plot_color);
hold(h_axes(fig),'on');
grid(h_axes(fig),'on');
xlabel(h_axes(fig),'GPS sec of day (sec)');
ylabel(h_axes(fig),'Roll (deg)');
set(h_fig(fig),'Name','Roll');

%% Pitch Plot
fig = fig+1;
figure(h_fig(fig));
if clear_figures
  clf(h_fig(fig));
  h_axes(fig) = axes;
else
  tmp = get(h_fig(fig),'Children');
  if isa(tmp,'matlab.graphics.axis.Axes')
    h_axes(fig) = tmp(1);
  else
    h_axes(fig) = axes;
  end
end
plot(h_axes(fig),GPS_sod,gps.pitch*180/pi,plot_color);
hold(h_axes(fig),'on');
grid(h_axes(fig),'on');
xlabel(h_axes(fig),'GPS sec of day (sec)');
ylabel(h_axes(fig),'Pitch (deg)');
set(h_fig(fig),'Name','Pitch');

%% Heading Plot
fig = fig+1;
figure(h_fig(fig));
if clear_figures
  clf(h_fig(fig));
  h_axes(fig) = axes;
else
  tmp = get(h_fig(fig),'Children');
  if isa(tmp,'matlab.graphics.axis.Axes')
    h_axes(fig) = tmp(1);
  else
    h_axes(fig) = axes;
  end
end
plot(h_axes(fig),GPS_sod,gps.heading*180/pi,[plot_color '.']);
hold(h_axes(fig),'on');
grid(h_axes(fig),'on');
xlabel(h_axes(fig),'GPS sec of day (sec)');
ylabel(h_axes(fig),'True heading (deg)');
set(h_fig(fig),'Name','Heading');

if plot_est_heading
  % Estimated heading
  est_heading = zeros(size(gps.heading));
  % Only do every Mx records, because this is slow
  Mx = 100;
  for idx = 2:Mx:length(gps.heading)
    if ~mod(idx-2,1000)
      fprintf('Estimated heading idx %d of %d (%s sec)\n', idx, length(gps.heading), datestr(now));
    end
    [north,east] = geodetic_to_utm(gps.lat(idx-1:idx),gps.lon(idx-1:idx));
    est_heading(idx) = atan2(diff(north), diff(east));
  end
  plot(h_axes(fig),GPS_sod(2:Mx:end), est_heading(2:Mx:end)*180/pi, [plot_color 'x']);
end

%% Speed Plot
fig = fig+1;
figure(h_fig(fig));
if clear_figures
  clf(h_fig(fig));
  h_axes(fig) = axes;
else
  tmp = get(h_fig(fig),'Children');
  if isa(tmp,'matlab.graphics.axis.Axes')
    h_axes(fig) = tmp(1);
  else
    h_axes(fig) = axes;
  end
end
along_track = geodetic_to_along_track(gps.lat,gps.lon,gps.elev);
speed = diff(along_track) ./ diff(gps.gps_time);
plot(h_axes(fig),GPS_sod(2:end),speed,[plot_color '.']);
hold(h_axes(fig),'on');
grid(h_axes(fig),'on');
xlabel(h_axes(fig),'GPS sec of day (sec)');
ylabel(h_axes(fig),'Speed (m/s)');
title(h_axes(fig),'Should not be zero in flight, should be a very smooth function, need to filter if not')
set(h_fig(fig),'Name','Speed');

%% Sync GPS Time Plot
if isfield(gps,'sync_gps_time')
  fig = fig+1;
  figure(h_fig(fig));
  if clear_figures
    clf(h_fig(fig));
    h_axes(fig) = axes;
  else
    tmp = get(h_fig(fig),'Children');
    if isa(tmp,'matlab.graphics.axis.Axes')
      h_axes(fig) = tmp(1);
    else
      h_axes(fig) = axes;
    end
  end
  plot(h_axes(fig),diff(gps.sync_gps_time));
  hold(h_axes(fig),'on');
  grid(h_axes(fig),'on');
  xlabel(h_axes(fig),'Index');
  ylabel(h_axes(fig),'Time step (sec)');
  set(h_fig(fig),'Name','Diff Sync GPS_time');
  
  repeat_idxs = find(diff(gps.sync_gps_time) <= 0);
  fprintf('Approx. number of repeats (non-monotonically increasing points in sync gps time):\n  %d\n', length(repeat_idxs))
end

%% Radar Time Plot
if isfield(gps,'radar_time')
  fig = fig+1;
  figure(h_fig(fig));
  if clear_figures
    clf(h_fig(fig));
    h_axes(fig) = axes;
  else
    tmp = get(h_fig(fig),'Children');
    if isa(tmp,'matlab.graphics.axis.Axes')
      h_axes(fig) = tmp(1);
    else
      h_axes(fig) = axes;
    end
  end
  plot(h_axes(fig),diff(gps.radar_time));
  hold(h_axes(fig),'on');
  grid(h_axes(fig),'on');
  xlabel(h_axes(fig),'Index');
  ylabel(h_axes(fig),'Time step (sec)');
  set(h_fig(fig),'Name','Diff Radar Time');
  
  repeat_idxs = find(diff(gps.radar_time) <= 0);
  fprintf('Approx. number of repeats (non-monotonically increasing points in radar time):\n  %d\n', length(repeat_idxs))
end
