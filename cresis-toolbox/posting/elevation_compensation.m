function [mdata,x_axis,y_axis,surf_comp,layers_comp] = elevation_compensation(mdata,param,layers_twtt)
% function [data,x_axis,y_axis,surf_comp,layers_comp] = elevation_compensation(mdata,param,layers_twtt)
%
% Inputs radar echogram (mdata.Data) and optional layers (layers_twtt) and
% creates a reinterpolated output image and layers onto a "WGS-84"
% elevation axis or a "depth" axis.
%
% Inputs
% =========================================================================
%
% mdata: L1B data structure from load_L1B.m. Requires
%
%   .Data: Nt x Nx numeric matrix
%
%   .Time: is Nt x 1 numeric vector
%
%   .Elevation: 1 x Nx numeric vector
%
%   .Surface: 1 x Nx numeric vector (an air-ice surface is required)
%
% param: structure controlling how elevation compensation is done. See
% "Input Checks" section for details.
%
% layers_twtt: cell array of numeric vectors. Each numeric vector contains
% the two way travel time to a layer.
% 
% Outputs
% =========================================================================
%
% mdata: The input L1B data structure with resampled variables:
%
%  .Data will be Nt_out by Nx_out output matrix sampled at the specified
%  x-axis and y-axis units
%
%  .GPS_time, .Lat, .Lon, .Elev, .Roll, .Pitch, .Heading, .Surface,
%  .Bottom: all Nx_out by 1
%
%  .Time: Remains unchanged, but no longer will match the data matrix if
%  y-axis resampling is done. Use y_axis instead.
% 
% x_axis: 1 by Nx_out numeric vector holding the x-axis corresponding to
% the row dimension of data output
%
% y_axis: Nt_out by 1 numeric vector holding the y-axis corresponding to
% the column dimension of data output
%
% surf_comp: 1 by Nx_out numeric vector holding the surface in y-axis units
%
% layers_comp: cell array of layers in y-axis units; corresponds with
% layers_twtt. Each cell array contains a 1 by Nx_out numeric vector.
%
% Examples:
%
% param = read_param_xls(ct_filename_param('snow_param_2012_Greenland_P3.xls'),'20120330_04');
% [mdata,echo_fn] = echo_load(param,'CSARP_post/qlook',3);
% [data,x_axis,y_axis] = elevation_compensation(mdata,echo_plot_profile('DEPTH'));
% imagesc(x_axis,y_axis,10*log10(data));
%
% % Also see echo_plot.m for examples
%
% Author: John Paden, Dhagash Kapadia
%
% See also: echo_plot.m, echo_plot_profile.m, elevation_compensation.m,
% load_L1B.m, run_echo_plot.m

%% Input checks

physical_constants;

if ~exist('param','var')
  param = [];
end

% .er_depth: Numeric vector of same length as er_ice field and aligns with
% the same. Default value is 0.
if ~isfield(param, 'er_depth') || isempty(param.er_depth)
  param.er_depth = 0;
end
% Force param.er_depth to be a column vector
param.er_depth = param.er_depth(:);

% .er_freq: Scalar numeric. Frequency to evaluate the permittivity at to
% determine loss. Only needed when the imaginary part of er_ice is
% non-zero.
if ~isfield(param,'er_freq')
  param.er_freq = 150e6;
end

% .er_ice: Nonempty numeric vector. Default value is a scalar pulled from
% physical_constants "er_ice" variable. Represents the relative
% permittivity of the medium at each depth specified in er_depth. A value
% of 1 represents a vacuum.
if ~isfield(param, 'er_ice') || isempty(param.er_ice)
  param.er_ice = er_ice;
end
% Force param.er_ice to be a column vector
param.er_ice = param.er_ice(:);

% .mode_x_axis: String specifying the x-axis type. The options are
% 'ALONG_TRACK', 'GPS_TIME', or 'RANGE_LINE'.
%
%   'ALONG_TRACK': interpolates onto uniform along-track spatial sampling.
%
%   'GPS_TIME': interpolates onto uniform gps time sampling.
%
%   'RANGE_LINE': Default mode. Data are assumed to be uniformily sampled
%   in range lines and no interpolation occurs.
if ~isfield(param, 'mode_x_axis') || isempty(param.mode_x_axis)
  param.mode_x_axis = 'RANGE_LINE';
end

% .mode_y_axis: String specifying the y-axis type. The options are 'DEPTH',
% 'RANGE', 'TWTT', or 'WGS84'.
%
%   'DEPTH': flattens the surface and interpolates onto a constant depth
%   grid where the surface is zero depth.
%
%   'RANGE': interpolates onto range grid (each row is a constant range
%   from the radar).
%
%   'TWTT': Default mode. Data are assumed to be uniformily sampled in time
%   and no interpolation occurs.
%
%   'WGS84': interpolates onto WGS-84 elevation grid (each row is a
%   constant WGS-84 value).
if ~isfield(param, 'mode_y_axis') || isempty(param.mode_y_axis)
  param.mode_y_axis = 'TWTT';
end

% .surf: fields dealing with surface
if ~isfield(param,'surf') || isempty(param.surf)
  param.surf = [];
end

% .filter_en: enables low pass filtering of the surface to reduce high
% frequency content distorting the interpolation result. Useful when
% surface has a lot of high frequency content.
if ~isfield(param.surf,'filter_en') || isempty(param.surf.filter_en)
  param.surf.filter_en = false;
end

% .filter_percent: scalar numeric, sets the filtering length, default is
% 0.05 or 5% of the whole dataset/range-line axis
if ~isfield(param.surf,'filter_percent') || isempty(param.surf.filter_percent)
  param.surf.filter_percent = 0.05;
end

% surf.source: source of the surface (0 to use mdata.Surface)
if ~isfield(param.surf,'source') || isempty(param.surf.source)
  param.surf.source = 0;
end

% surf.update_en: logical to update the surface using layer_tracker_task.m,
% useful when the surface is missing or poorly tracked
if ~isfield(param.surf,'update_en') || isempty(param.surf.update_en)
  param.surf.update_en = false;
end

% surf.update_params: layer_tracker parameters to be used with
% layer_tracker_task.m
% NOT IMPLEMENTED

% .trim_nan_en: logical scalar, default true, if true, it removes rows that
% are all NaN from the top and bottom of the image.
if ~exist('param.trim_nan_en','var') || isempty(param.trim_nan_en)
  param.trim_nan_en = true;
end

% .ylims_cmd: Matlab command string to be evaluated in the calculation of
% y_axis. This specifies which bins to include in case a subset of the
% data is desired. Several variables are made available to use with the
% ylims_cmd command:
%
%  .elev: elevation 1 by Nx vector
%
%  .layers_comp: Cell array that corresponds to layers_twtt in y-axis units
%
%  .surf_comp: Numeric vector of surface location in y-axis units
% 
% Default value: '[-inf inf]'
%
% Example for 'depth' mode_y_axis: '[-2 20]';
%
% Example for 'wgs84' mode_y_axis: '[min(surf_comp)-600 max(surf_comp)+20]';
if ~isfield(param,'ylims_cmd') || isempty(param.ylims_cmd)
  param.ylims_cmd = '[-inf inf]';
end

if ~exist('layers_twtt','var')
  layers_twtt = {};
end

%% Setup

Nt = size(mdata.Data,1);
Nx = size(mdata.Data,2);

%% Get surface
if param.surf.source == 0
  if isfield(mdata,'Surface')
    surf = interp_finite(mdata.Surface,0);
  else
    surf = zeros(1,Nx);
  end
else
  surf = interp_finite(layers_twtt{param.surf.source},0);
end

if param.surf.update_en
  %% Update surface:
  
  surf_param = param;
  surf_param.layer_tracker.frms = frm;
  surf_param.layer_tracker.echogram_source = struct('Data',Data_Surface,'Time',Time_Surface,'GPS_time',GPS_time,'Latitude',Latitude,'Longitude',Longitude,'Elevation',Elevation,'Roll',Roll);
  if length(Time_Surface) < 2
    % This frame has all bad records, so surface tracking cannot be completed.
    Surface = nan(size(GPS_time));
  else
    Surface = layer_tracker_task(surf_param);
  end
  
  
  surf_bin = zeros(1,size(mdata.Data,2));
  for rline = 1:size(mdata.Data,2)
    new_surf = find(mdata.Data(:,rline) ...
      > max(param.threshold,max(mdata.Data(:,rline))*param.sidelobe),1);
    if isempty(new_surf)
      surf_bin(rline) = NaN;
    else
      surf_bin(rline) = new_surf;
    end
  end
  layers_twtt{1} = interp1(1:length(mdata.Time),mdata.Time, surf_bin);
  nan_mask = isnan(layers_twtt{1});
  layers_twtt{1} = interp1(find(~nan_mask),layers_twtt{1}(~nan_mask),1:length(layers_twtt{1}));
end


if param.surf.filter_en
  %% Filter surface
  if length(layers_twtt{1}) >= 100
    [Bfilt,Afilt] = butter(2,length(layers_twtt{1}) * param.surf.filter_percent);
    surf_filt = filtfilt(Bfilt,Afilt,layers_twtt{1});
    tmp = polyval(polyfit(1:51,reshape(layers_twtt{1}(1:51),[1 51]),2),1:51);
    surf_filt(1:50) = tmp(1:50) - tmp(51) + surf_filt(51);
    tmp = polyval(polyfit(1:51,reshape(layers_twtt{1}(end-50:end),[1 51]),2),1:51);
    surf_filt(end-49:end) = tmp(2:51) - tmp(1) + surf_filt(end-50);
    layers_twtt{1} = surf_filt;
  else
    surf_filt = medfilt1(layers_twtt{1},round(length(layers_twtt{1})/20)*2+1);
    layers_twtt{1} = surf_filt;
  end
else
  surf_filt = surf;
end

%% Resample data in x-dimension as required
if strcmpi(param.mode_x_axis,'along_track')
  % Resample data to be uniformily sampled in along_track
  along_track = geodetic_to_along_track(mdata);
  dx = median(diff(along_track));
  x_axis = along_track(1) : dx : along_track(end);
  mdata.Data = interp1(along_track,mdata.Data.',x_axis).';
  surf_filt = interp1(along_track,surf_filt,x_axis);
  Nx = length(x_axis);
  elev = interp1(along_track,mdata.Elevation,x_axis);
  for layer_idx = 1:length(layers_twtt)
    layers_twtt{layer_idx} = interp1(along_track,layers_twtt{layer_idx},x_axis);
  end
  if isfield(mdata,'Latitude')
    mdata.Latitude = interp1(along_track,mdata.Latitude,x_axis);
  end
  if isfield(mdata,'Longitude')
    mdata.Longitude = interp1(along_track,mdata.Longitude,x_axis);
  end
  if isfield(mdata,'Elevation')
    mdata.Elevation = interp1(along_track,mdata.Elevation,x_axis);
  end
  if isfield(mdata,'Roll')
    mdata.Roll = interp1(along_track,mdata.Roll,x_axis);
  end
  if isfield(mdata,'Pitch')
    mdata.Pitch = interp1(along_track,mdata.Pitch,x_axis);
  end
  if isfield(mdata,'Heading')
    mdata.Heading = interp1(along_track,mdata.Heading,x_axis);
  end
  if isfield(mdata,'Surface')
    mdata.Surface = interp1(along_track,mdata.Surface,x_axis);
  end
  if isfield(mdata,'Bottom')
    mdata.Bottom = interp1(along_track,mdata.Bottom,x_axis);
  end
  if isfield(mdata,'GPS_time')
    mdata.GPS_time = interp1(along_track,mdata.GPS_time,x_axis);
  end
elseif strcmpi(param.mode_x_axis,'gps_time')
  % Resample data to be uniformily sampled in mdata.GPS_time
  dx = median(diff(mdata.GPS_time));
  x_axis = mdata.GPS_time(1) : dx : mdata.GPS_time(end);
  mdata.Data = interp1(mdata.GPS_time,mdata.Data.',x_axis).';
  surf_filt = interp1(mdata.GPS_time,surf_filt,x_axis);
  Nx = length(x_axis);
  elev = interp1(mdata.GPS_time,mdata.Elevation,x_axis);
  for layer_idx = 1:length(layers_twtt)
    layers_twtt{layer_idx} = interp1(mdata.GPS_time,layers_twtt{layer_idx},x_axis);
  end
  if isfield(mdata,'Latitude')
    mdata.Latitude = interp1(mdata.GPS_time,mdata.Latitude,x_axis);
  end
  if isfield(mdata,'Longitude')
    mdata.Longitude = interp1(mdata.GPS_time,mdata.Longitude,x_axis);
  end
  if isfield(mdata,'Elevation')
    mdata.Elevation = interp1(mdata.GPS_time,mdata.Elevation,x_axis);
  end
  if isfield(mdata,'Roll')
    mdata.Roll = interp1(mdata.GPS_time,mdata.Roll,x_axis);
  end
  if isfield(mdata,'Pitch')
    mdata.Pitch = interp1(mdata.GPS_time,mdata.Pitch,x_axis);
  end
  if isfield(mdata,'Heading')
    mdata.Heading = interp1(mdata.GPS_time,mdata.Heading,x_axis);
  end
  if isfield(mdata,'Surface')
    mdata.Surface = interp1(mdata.GPS_time,mdata.Surface,x_axis);
  end
  if isfield(mdata,'Bottom')
    mdata.Bottom = interp1(mdata.GPS_time,mdata.Bottom,x_axis);
  end
  if isfield(mdata,'GPS_time')
    mdata.GPS_time = x_axis;
  end
elseif strcmpi(param.mode_x_axis,'range_line')
  % Nothing needs to be done, the echogram is already uniformily in
  % range_line units.
  x_axis = 1:Nx;
  elev = mdata.Elevation;
else
  error('param.mode_x_axis %s not supported', param.mode_x_axis);
end

% Create two way travel time axis for below the surface based on the permittivity model
[TWtime,~,param.er_depth,param.er_ice] = genPropProfileFromPerm(param.er_depth,param.er_ice,param.er_freq);
% Add an extra point for "air/vacuum" above the ice/media surface
TWtime = [-1e-6 TWtime];
param.er_depth = [-1e-6*c/2 param.er_depth];

%% Resample data in y-dimension as required
if strcmpi(param.mode_y_axis,'depth')
  %% DEPTH elevation compensation ==============
  
  %% Depth: Find the min/max depths represented in the data
  
  % Find the maximum elevation above ground level represented in the
  % echogram (i.e. what is the maximum AGL of the first pixel over all of
  % the range lines). This code tries to handle all cases, including if the first
  % pixel in the echogram is below the surface.
  min_y = interp1(TWtime, param.er_depth, min(mdata.Time(1)-surf_filt),'linear','extrap');
  
  % Find the minimum elevation above ground level represented in the
  % echogram. Normally this will be negative since we are generally looking
  % at targets below the surface (i.e. what is the minimum AGL of the last
  % pixel over all of the range lines). This code tries to handle all
  % cases, including if the last pixel in the echogram is above the
  % surface.
  max_y = interp1(TWtime, param.er_depth, max(mdata.Time(end)-surf_filt),'linear','extrap');
  
  %% Depth: Convert surface and layers to new y-axis
  % Surface is at "zero" depth (surf_comp can be used in param.ylims_cmd)
  surf_comp = zeros(1,Nx);
  % layers_twtt-->layers_comp (layers_comp can be used in param.ylims_cmd)
  layers_comp = cell(size(layers_twtt));
  for layer_idx = 1:length(layers_twtt)
    layers_comp{layer_idx} = interp1(TWtime, param.er_depth, layers_twtt{layer_idx} - surf_filt,'linear','extrap');
  end
  
  %% Depth: Limit plotted y-axis according to input param.ylims_cmd
  % Example: param.ylims_cmd = '[-2 20]';
  ylims = eval(param.ylims_cmd);
  
  % Check for inf limits (which get clipped to the ends of the time gate)
  if ~isfinite(ylims(1))
    ylims(1) = min_y;
  end
  if ~isfinite(ylims(2))
    ylims(end) = max_y;
  end
    
  %% Depth: Create depth axis
  
  % Determine sampling
  max_er = max(param.er_ice);
  dt = mdata.Time(2) - mdata.Time(1);
  dz = dt * c/2/sqrt(max_er);

  % y_axis: y-axis for output elevation compensated echogram
  y_axis = (round(ylims(1)/dz)*dz : dz : round(ylims(end)/dz)*dz).';
  
  % Convert Y-axis into time relative to the surface return (above the
  % surface is negative and below the surface is positive time)
  y_axis_time = interp1(param.er_depth,TWtime,y_axis,'linear','extrap');
  
  %% Depth: Interpolate data onto new y-axis
  data = zeros(length(y_axis),Nx);
  for rline = 1:Nx
    data(:,rline) = interp1(mdata.Time-surf_filt(rline),mdata.Data(:,rline),y_axis_time);
  end
  
elseif strcmpi(param.mode_y_axis,'range')
  %% RANGE elevation compensation ==============
  
  %% Range: Find the min/max ranges represented in the data
  
  % Find the minimum range represented in the echogram. This code tries to
  % handle all cases, including if the first pixel in the echogram is below
  % the surface.
  min_surf_filt = min(surf_filt);
  min_y = min_surf_filt*c/2 + interp1(TWtime, param.er_depth, mdata.Time(1)-min_surf_filt,'linear','extrap');
  
  % Find the maximum range represented in the echogram. This code tries to
  % handle all cases, including if the last pixel in the echogram is above
  % or below the surface.
  max_surf_filt = max(surf_filt);
  max_y = max_surf_filt*c/2 + interp1(TWtime, param.er_depth, mdata.Time(end) - max_surf_filt,'linear','extrap');
  
  %% Range: Convert surface and layers to new y-axis
  % Surface range (surf_comp can be used in param.ylims_cmd)
  surf_comp = surf_filt*c/2;
  % layers_twtt-->layers_comp (layers_comp can be used in param.ylims_cmd)
  layers_comp = cell(size(layers_twtt));
  for layer_idx = 1:length(layers_twtt)
    layers_comp{layer_idx} = surf_filt*c/2 ...
      + interp1(TWtime, param.er_depth, layers_twtt{layer_idx}-surf_filt,'linear','extrap');
  end
  
  %% Range: Limit plotted y-axis according to input param.ylims_cmd
  % Example: param.ylims_cmd = 'surf_comp + [-2 20]';
  ylims = eval(param.ylims_cmd);
  
  % Check for inf limits (which get clipped to the ends of the time gate)
  if ~isfinite(ylims(1))
    ylims(1) = min_y;
  end
  if ~isfinite(ylims(2))
    ylims(end) = max_y;
  end
    
  %% Range: Create range axis
  
  % Determine sampling
  max_er = max(param.er_ice);
  dt = mdata.Time(2) - mdata.Time(1);
  dz = dt * c/2/sqrt(max_er);

  % y_axis: y-axis for output elevation compensated echogram
  y_axis = (round(ylims(1)/dz)*dz : dz : round(ylims(end)/dz)*dz).';
  
  %% Range: Interpolate data onto new y-axis
  data = zeros(length(y_axis),Nx);
  for rline = 1:Nx
    % Create range axis for this dataset
    range = surf_filt(rline)*c/2 ...
      + interp1(TWtime,param.er_depth,mdata.Time-surf_filt(rline),'linear','extrap');
    data(:,rline) = interp1(range,mdata.Data(:,rline),y_axis);
  end
  
elseif strcmpi(param.mode_y_axis,'twtt')
  %% TWTT elevation compensation ==============
  
  %% twtt: Find the min/max ranges represented in the data
  min_y = mdata.Time(1);
  max_y = mdata.Time(end);

  %% twtt: Convert surface and layers to new y-axis
  % Surface/layers are already in this format, so no work is needed.
  surf_comp = surf_filt;
  layers_comp = layers_twtt;

  %% twtt: Limit plotted y-axis according to input param.ylims_cmd
  % Example: param.ylims_cmd = 'surf_comp + [-2e-9 20e-9]';
  ylims = eval(param.ylims_cmd);
  
  % Check for inf limits (which get clipped to the ends of the time gate)
  if ~isfinite(ylims(1))
    ylims(1) = min_y;
  end
  if ~isfinite(ylims(2))
    ylims(end) = max_y;
  end

  %% twtt: Interpolate data onto new y-axis
  % Data is already in this format, so just need to truncate to ylims
  y_axis = mdata.Time(mdata.Time>=ylims(1) & mdata.Time<=ylims(end));
  data = mdata.Data(mdata.Time>=ylims(1) & mdata.Time<=ylims(end),:);
  
elseif strcmpi(param.mode_y_axis,'wgs84')
  %% WGS84 elevation compensation ==============
  
  %% wgs84: Find the min/max ranges represented in the data
  
  % Find the minimum wgs-84 elevation represented in the echogram. This
  % code tries to handle all cases, including if the last pixel in the
  % echogram is below the surface.
  min_y = min(elev ...
    - (surf_filt*c/2 + ...
    interp1(TWtime, param.er_depth, mdata.Time(end)-surf_filt,'linear','extrap')));
  
  % Find the maximum wgs-84 elevation represented in the echogram. This
  % code tries to handle all cases, including if the first pixel in the
  % echogram is above or below the surface.
  max_y = max(elev ...
    - (surf_filt*c/2 + ...
    interp1(TWtime, param.er_depth, mdata.Time(1)-surf_filt,'linear','extrap')));
  
  %% wgs84: Convert surface and layers to new y-axis
  % Surface range (surf_comp can be used in param.ylims_cmd)
  surf_comp = elev - surf_filt*c/2;
  % layers_twtt-->layers_comp (layers_comp can be used in param.ylims_cmd)
  layers_comp = cell(size(layers_twtt));
  for layer_idx = 1:length(layers_twtt)
    layers_comp{layer_idx} = elev ...
      - (surf_filt*c/2 ...
      + interp1(TWtime, param.er_depth, layers_twtt{layer_idx}-surf_filt,'linear','extrap'));
  end
  
  %% wgs84: Limit plotted y-axis according to input param.ylims_cmd
  ylims = eval(param.ylims_cmd);
  
  % Check for inf limits (which get clipped to the ends of the time gate)
  if ~isfinite(ylims(1))
    ylims(1) = min_y;
  end
  if ~isfinite(ylims(2))
    ylims(end) = max_y;
  end
    
  %% wgs84: Create range axis
  
  % Determine sampling
  max_er = max(param.er_ice);
  dt = mdata.Time(2) - mdata.Time(1);
  dz = dt * c/2/sqrt(max_er);

  % y_axis: y-axis for output elevation compensated echogram
  y_axis = (round(ylims(1)/dz)*dz : dz : round(ylims(end)/dz)*dz).';
  
  %% wgs84: Interpolate data onto new y-axis
  data = zeros(length(y_axis),Nx);
  for rline = 1:Nx
    % Create range axis for this dataset
    wgs84 = elev(rline) ...
      - (surf_filt(rline)*c/2 ...
      + interp1(TWtime,param.er_depth,mdata.Time-surf_filt(rline),'linear','extrap'));
    data(:,rline) = interp1(wgs84,mdata.Data(:,rline),y_axis);
  end
  
else
  error('param.mode_y_axis %s not supported', param.mode_y_axis);
end

mdata.Data = data;

%% Trim NaN from start/end of record
trim_nan_en = true;
if trim_nan_en
  start_bin = nan(1,Nx);
  stop_bin = nan(1,Nx);
  for rline = 1:Nx
    start_bin_tmp = find(~isnan(mdata.Data(:,rline)),1);
    if ~isempty(start_bin_tmp)
      start_bin(rline) = start_bin_tmp;
    end
    stop_bin_tmp = find(~isnan(mdata.Data(:,rline)),1,'last');
    if ~isempty(stop_bin_tmp)
      stop_bin(rline) = stop_bin_tmp;
    end
  end
  start_bin = min(start_bin);
  stop_bin = max(stop_bin);
  mdata.Data = mdata.Data(start_bin:stop_bin,:);
  y_axis = y_axis(start_bin:stop_bin);
end
