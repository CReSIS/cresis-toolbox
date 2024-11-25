function records_bit_mask(param,param_override)
%
% GPR profiles usually contain stops, 270+ deg loop turns, etc that may be
% undesirable for SAR processing. Use this script to help find the data
% records associated with these maneuvers and mask them for SAR processing.
% Usually it is not necessary to do this unless there are long sections of
% stationary data which can cause the SAR processor to run out of memory.
%
% param = struct with processing parameters
% param_override = parameters in this struct will override parameters
%         in param.  This struct must also contain the gRadar fields.
%         Typically global gRadar; param_override = gRadar;
%
% Author: Nick Holschuh, John Paden
%
% See also: run_records_bit_mask.m, records_bit_mask.m

%% General Setup
% =====================================================================
param = merge_structs(param, param_override);

fprintf('=====================================================================\n');
fprintf('%s: %s (%s)\n', mfilename, param.day_seg, datestr(now));
fprintf('=====================================================================\n');

%% Input Checks: records_bit_mask
% =====================================================================

% Here we set threshold values for the velocity and heading
if ~isfield(param.records_bit_mask,'bad_vel_threshold') || isempty(param.records_bit_mask.bad_vel_threshold)
  param.records_bit_mask.bad_vel_threshold = 0.25;
end
bad_vel_threshold = param.records_bit_mask.bad_vel_threshold;

if ~isfield(param.records_bit_mask,'bad_heading_diff_threshold') || isempty(param.records_bit_mask.bad_heading_diff_threshold)
  param.records_bit_mask.bad_heading_diff_threshold = 1;
end
bad_heading_diff_threshold = param.records_bit_mask.bad_heading_diff_threshold;

if ~isfield(param.records_bit_mask,'debug_plot') || isempty(param.records_bit_mask.debug_plot)
  param.records_bit_mask.debug_plot = 1;
end

if ~isfield(param.records_bit_mask,'manual_masking_en') || isempty(param.records_bit_mask.manual_masking_en)
  param.records_bit_mask.manual_masking_en = 1;
end

if ~isfield(param.records_bit_mask,'mode') || isempty(param.records_bit_mask.mode)
  param.records_bit_mask.mode = 1;
end

%% Load records and background geotiff for GUI

geotiff_fn = ct_filename_gis(param,param.records.frames.geotiff_fn);

records = records_load(param);

proj = geotiffinfo(geotiff_fn);

[x,y] = projfwd(proj,records.lat,records.lon);

%% Fabricating a heading now (code copied from gps_create.m)
gps = records;
along_track = geodetic_to_along_track(gps.lat,gps.lon);
rlines = get_equal_alongtrack_spacing_idxs(along_track,0.75);
physical_constants; % Load WGS84.spheroid
est_heading = size(gps.heading);
clear origin heading east north;
for rline_idx = 1:length(rlines)
  rline = rlines(rline_idx);
  if rline_idx < length(rlines)
    rline_end = rlines(rline_idx+1);
  else
    rline_end = length(along_track);
  end
  [origin(1),origin(2),origin(3)] = geodetic2ecef(WGS84.spheroid, gps.lat(rline),gps.lon(rline),gps.elev(rline));
  [heading(1),heading(2),heading(3)] = geodetic2ecef(WGS84.spheroid, gps.lat(rline_end),gps.lon(rline_end),gps.elev(rline_end));
  heading = heading - origin;
  % Determine east vector
  [east(1) east(2) east(3)] = enu2ecef(1,0,0,gps.lat(rline),gps.lon(rline),gps.elev(rline),WGS84.spheroid);
  east = east - origin;
  % Determine north vector
  [north(1) north(2) north(3)] = enu2ecef(0,1,0,gps.lat(rline),gps.lon(rline),gps.elev(rline),WGS84.spheroid);
  north = north - origin;
  % Determine heading
  est_heading(rline:rline_end) = atan2(dot(east,heading),dot(north,heading));
end

% Slow velocity mask
speed = [inf diff(along_track) ./ diff(records.gps_time)];
speed_mask = speed < bad_vel_threshold;

% Fast heading change mask
heading_diff = [0 diff(est_heading)];
heading_mask = abs(heading_diff) > bad_heading_diff_threshold;

clip_vectors_param = [];
clip_vectors_param.fh_button_motion = @records_bit_mask_button_motion;
clip_vectors_param.fh_close_win = @records_bit_mask_close_window;
clip_vectors_param.user_data.param = param;
clip_vectors_param.user_data.x = x;
clip_vectors_param.user_data.y = y;
clip_vectors_param.user_data.records = records;
clip_vectors_param.user_data.speed = speed;
clip_vectors_param.user_data.speed_mask = speed_mask;
clip_vectors_param.user_data.heading_diff = heading_diff;
clip_vectors_param.user_data.heading_mask = heading_mask;

% This either initiates the manual removal of records or does it
% automatically based on thresholds.
if param.records_bit_mask.manual_masking_en == 1
  % Plot records
  h_fig = figure;
  h_axes = axes('parent',h_fig);
  h_plots = [];
  switch (param.records_bit_mask.mode)
    case 0
      h_plots(end+1) = plot(x/1e3,y/1e3,'parent',h_axes);
    case 2
      x_cur = x;
      x_cur(speed_mask | heading_mask) = NaN;
      y_cur = y;
      y_cur(speed_mask | heading_mask) = NaN;
      h_plots(end+1) = plot(x_cur/1e3,y_cur/1e3,'parent',h_axes);
    otherwise % case 1
      x_cur = x;
      x_cur(logical(bitand(records.bit_mask(1,:),2))) = NaN;
      y_cur = y;
      y_cur(logical(bitand(records.bit_mask(1,:),2))) = NaN;
      h_plots(end+1) = plot(x_cur/1e3,y_cur/1e3,'parent',h_axes);
  end
  hold on;
  fprintf('\nRed indicates slow speed records\n');
  h_plots(end+1) = plot(x(speed_mask)/1e3,y(speed_mask)/1e3,'r.','parent',h_axes);
  fprintf('\nGreen indicates fast heading change records\n');
  if ~any(heading_mask)
    h_plots(end+1) = plot(NaN,NaN,'g.','parent',h_axes);
  else
    h_plots(end+1) = plot(x(heading_mask)/1e3,y(heading_mask)/1e3,'g.','parent',h_axes);
  end
  % Manual tool for removing records
  h_clip_vectors = clip_vectors(h_plots,clip_vectors_param);
  set(h_clip_vectors.sf.h_fig,'Visible','off'); % Selection filter not useful so hide it
  
  fprintf('\nRemove bad records (press F1 in plot for help). Once done, close the window and the changes will be saved to records.bit_mask.\n');
  h_clip_vectors.key_press([],struct('Modifier',{{}},'Key','f1'));
else
  % Accept the automatically determined stationary/fast-heading change
  % records without opening the manual GUI.
  records_bit_mask_close_window(clip_vectors_param);
end

end

%% records_bit_mask_button_motion
function records_bit_mask_button_motion(h_clip_vector,src,event)

mouse_pos = get(h_clip_vector.h_axes,'CurrentPoint');
x = mouse_pos(1,1)*1e3;
y = mouse_pos(1,2)*1e3;

[~,idx] = min((h_clip_vector.user_data.x-x).^2+(h_clip_vector.user_data.y-y).^2);
h=title(sprintf('%8d: (%+5.0f km,%+5.0f km) %3.1f m/s %4.1f deg heading change', idx, ...
  round(h_clip_vector.user_data.x(idx)/1e3), ...
  round(h_clip_vector.user_data.y(idx)/1e3), ...
  round(h_clip_vector.user_data.speed(idx)*10)/10, ...
  abs(round(h_clip_vector.user_data.heading_diff(idx)*180/pi*10)/10) ),'FontName','FixedWidth','FontSize',8,'parent',h_clip_vector.h_axes);

end

%% records_bit_mask_close_window
function records_bit_mask_close_window(h_clip_vector)

param = h_clip_vector.user_data.param;
records = h_clip_vector.user_data.records;
heading_mask = h_clip_vector.user_data.heading_mask;
speed_mask = h_clip_vector.user_data.speed_mask;

if isa(h_clip_vector,'clip_vectors')
  % Find the bad records
  ydata = get(h_clip_vector.h_plots(1),'YData');
  good_mask = ~isnan(ydata);
else
  good_mask = [~heading_mask & ~speed_mask];
end


if param.records_bit_mask.debug_plot == 1
  h_fig = figure; h_axes = axes('parent',h_fig);
  plot(records.lon(good_mask),records.lat(good_mask),'parent',h_axes);
  title([num2str(sum(good_mask)),' of ',num2str(length(good_mask)),' remaining']);
  fprintf('Check to make sure you are happy with the results. Once done, run "dbcont" or press F5 to continue. If not, run "dbquit" and start over.\n');
  keyboard
end

% Here we use the good_mask info to produce records.bit_mask.
% This preserves data already masked for bad headers (bit_mask bit 0 set), but adds masks
% to stationary or incorrectly moving records.
if ~isfield(records,'bit_mask')
  records.bit_mask = zeros(size(records.offset),'uint8');
end
for board_idx = 1:size(records.offset,1)
  records.bit_mask(board_idx,:) ...
    = bitand(records.bit_mask(board_idx,:),bin2dec('11111101')) + 2*~good_mask;
end

records_fn = ct_filename_support(param,'','records');
fprintf('  Saving records %s\n', records_fn);
ct_save(records_fn,'-struct','records');

end
