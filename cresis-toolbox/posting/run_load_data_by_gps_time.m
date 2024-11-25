% script run_load_data_by_gps_time
%
% This script prepares data for publication. It is an example script for
% setting up parameters and calling load_data_by_gps_time which does the
% real work.
%
% To use this function, go through and set the parameters highlighted by:
%   "<== CHANGE HERE"
% In the section "User Settings for Comparison Image", you only need to set
% these parameters if you are loading additional images to compare.
%
% Note that the text and axes are scaled to the size of the figure when
% the command is run. Therefore, it is best to size the figure window to
% the size you want and then run this command.
%
% Authors: John Paden, Reece Mathews

%% User Settings
% ====================================================================
clear param echo_param lay ds;

% data_load_method: string containing "file" or "arbitrary"
%   picker: Loads a GPS date range from cursor information from imb.picker
%   arbitrary: Allows a specific GPS date range to be specified
%   file: Loads a data frame and plots the whole data frame
data_load_method = 'file'; % <== CHANGE HERE

if strcmpi(data_load_method,'picker')
  
  param.start.picker = '19930702_11_010: 71.001638 N, -39.078796 E, X:214.197 km, Y:-2065.268 km, 1993-07-02 13:50:58.60'; % <== CHANGE HERE
  param.stop.picker = '19930702_11_011: 70.869065 N, -40.912414 E, X:149.056 km, Y:-2085.777 km, 1993-07-02 13:58:20.47'; % <== CHANGE HERE
  
  param.start.picker = param.start.picker(max([1 find(param.start.picker==',',1,'last')+2]):end);
  param.start.gps_time = datenum_to_epoch(datenum(param.start.picker));
  param.stop.picker = param.stop.picker(max([1 find(param.stop.picker==',',1,'last')+2]):end);
  param.stop.gps_time = datenum_to_epoch(datenum(param.stop.picker));

elseif strcmpi(data_load_method,'arbitrary')
  % Load data for an arbitrary time period
  param.start.hour = 13; % <== CHANGE HERE
  param.start.minute = 17; % <== CHANGE HERE
  param.start.sec = 27; % <== CHANGE HERE
  
  param.stop.hour = 13; % <== CHANGE HERE
  param.stop.minute = 26; % <== CHANGE HERE
  param.stop.sec = 46; % <== CHANGE HERE
  
  param.start.year = 2009; % <== CHANGE HERE
  param.start.month = 4; % <== CHANGE HERE
  param.start.day = 9; % <== CHANGE HERE
  param.stop.year = param.start.year;
  param.stop.month = param.start.month;
  param.stop.day = param.start.day;
  
  param.start.gps_time = datenum_to_epoch(datenum(param.start.year,param.start.month,param.start.day,param.start.hour,param.start.minute,param.start.sec));
  param.stop.gps_time = datenum_to_epoch(datenum(param.stop.year,param.stop.month,param.stop.day,param.stop.hour,param.stop.minute,param.stop.sec));
  
elseif strcmpi(data_load_method,'file')
  % Load data associated with a frame
  load('X:/ct_data/snow/2012_Greenland_P3/CSARP_post/CSARP_qlook/20120330_04/Data_20120330_04_063.mat','GPS_time') % <== CHANGE HERE
  param.start.gps_time = GPS_time(1);
  param.stop.gps_time = GPS_time(end);
  
else
  error('Unsupported data_load_method.\n');
end

% param.radar_name: 'accum', 'kaband', 'kuband', 'rds', or 'snow'
param.radar_name = 'snow'; % <== CHANGE HERE

param.season_name = '2012_Greenland_P3'; % <== CHANGE HERE

% echo_param.elev_comp: Elevation compensation 0=none, 1=relative, 2=surface flattened, 3=WGS-84
echo_param.elev_comp = 2; % <== CHANGE HERE

echo_param.plot_quality = false; % <== CHANGE HERE

% param.out: output data product to use. For example:
%   'qlook', 'standard', 'mvdr', 'CSARP_post/standard', 'CSARP_post/mvdr'
param.out = 'CSARP_post/qlook'; % <== CHANGE HERE

gaps_dist = [100 30];

% surface_source: location of surface information (used in elevation
% compensation). For example:
%  struct('name','surface','source','layerdata', 'layerdata_source','layer')
%  struct('name','surface','source','ops')
surface_source = struct('name','surface','source','layerdata', 'layerdata_source','layer'); % <== CHANGE HERE

% param.img_name: output data product image. For example:
%   '': combined product, 'img_01_': image 1, , 'img_02_': image 2, etc.
param.img_name = '';

if echo_param.elev_comp == 3
  echo_param.depth = '[min(Surface_Elev)-3500 max(Surface_Elev)+200]'; % <== CHANGE HERE
  %echo_param.depth = '[1594.9 1635.1]';
else
  echo_param.depth = '[min(Surface_Depth)-2 max(Surface_Depth) +20]'; % <== CHANGE HERE
  %echo_param.depth = '[-5 120]';
end
echo_param.depth_offset = 0;
echo_param.time_offset = 0;
echo_param.caxis = [];
echo_param.er_ice = 3.15;

% echo_param.axis_type: Units representation 'bars' or 'standard'
echo_param.axis_type = 'standard';

% param.create_map_en: set to true to produce a map
param.create_map_en = false;

% param.post.map.type: 'combined', 'singles', 'contour', 'contour-singles', or 'ASCAT'
param.post.map.type = 'combined';

% param.post.map.location: map choice 'Greenland', 'Antarctica', 'Arctic', 'Norway', or 'Canada'
param.post.map.location = 'Greenland';

% Enable for detrending
if 0
  echo_param.detrend.mode = 'polynomial';
  echo_param.detrend.poly_order = 4;
  echo_param.detrend.depth = '[min(Surface_Depth)+1 max(Surface_Depth)+20.1]';
  %echo_param.filter = inline('wiener2(N,[3 31])');
else
  echo_param.detrend = [];
end
% echo_param.filter = inline('fir_dec(N,ones([1 11])/11,1)');

% param.use_master_surf: set to true if you want to use the previous
% surface loaded by this function (this is useful when comparing to
% different systems and you want the second system loaded to use the
% surface from the first system loaded)
param.use_master_surf = 0;

% param.layer_params: set to plot layers on echograms
layer_params = []; idx = 0;
if 0 % Enable to plot layers on echograms
  layer_params = struct('name','surface','source','layerdata','layerdata_source','layerData_koenig');
  for idx = 2:30
    layer_params(end+1) = struct('name',sprintf('Koenig_%d',idx),'source','layerdata','layerdata_source','layerData_koenig');
  end
end
param.layer_params = layer_params;

params = param;
echo_params = echo_param;

%% User Settings for Comparison Image
% ====================================================================
% ====================================================================
% Enable by changing to "1". Copy and paste this section to compare many
% images. These images will all be interpolated onto the first image.

if 1
  % data_load_method: string containing "file" or "arbitrary"
  %   picker: Loads a GPS date range from cursor information from imb.picker
  %   arbitrary: Allows a specific GPS date range to be specified
  %   file: Loads a data frame and plots the whole data frame
  data_load_method = 'file'; % <== CHANGE HERE
  
  if strcmpi(data_load_method,'picker')
    
    param.start.picker = '19930709_08_012: 70.996954 N, -39.076055 E, X:214.350 km, Y:-2065.776 km, 1993-07-09 15:37:11.26'; % <== CHANGE HERE
    param.stop.picker = '19930709_08_013: 70.860179 N, -40.899761 E, X:149.587 km, Y:-2086.730 km, 1993-07-09 15:44:31.31'; % <== CHANGE HERE
    
    param.start.picker = param.start.picker(max([1 find(param.start.picker==',',1,'last')+2]):end);
    param.start.gps_time = datenum_to_epoch(datenum(param.start.picker));
    param.stop.picker = param.stop.picker(max([1 find(param.stop.picker==',',1,'last')+2]):end);
    param.stop.gps_time = datenum_to_epoch(datenum(param.stop.picker));
    
  elseif strcmpi(data_load_method,'arbitrary')
    % Load data for an arbitrary time period
    
    param.start.hour = 13; % <== CHANGE HERE
    param.start.minute = 17; % <== CHANGE HERE
    param.start.sec = 27; % <== CHANGE HERE
    
    param.stop.hour = 13; % <== CHANGE HERE
    param.stop.minute = 26; % <== CHANGE HERE
    param.stop.sec = 46; % <== CHANGE HERE
    
    param.start.year = 2009; % <== CHANGE HERE
    param.start.month = 4; % <== CHANGE HERE
    param.start.day = 9; % <== CHANGE HERE
    param.stop.year = param.start.year;
    param.stop.month = param.start.month;
    param.stop.day = param.start.day;
    
    param.start.gps_time = datenum_to_epoch(datenum(param.start.year,param.start.month,param.start.day,param.start.hour,param.start.minute,param.start.sec));
    param.stop.gps_time = datenum_to_epoch(datenum(param.stop.year,param.stop.month,param.stop.day,param.stop.hour,param.stop.minute,param.stop.sec));
    
  elseif strcmpi(data_load_method,'file')
    % Load data associated with a frame
    load('X:/ct_data/snow/2012_Greenland_P3/CSARP_post/CSARP_qlook/20120330_04/Data_20120330_04_063.mat','GPS_time') % <== CHANGE HERE
    param.start.gps_time = GPS_time(1);
    param.stop.gps_time = GPS_time(end);
    
  else
    error('Unsupported data_load_method.\n');
  end
  
  % param.radar_name: 'accum', 'kaband', 'kuband', 'rds', or 'snow'
  param.radar_name = 'snow'; % <== CHANGE HERE
  
  param.season_name = '2012_Greenland_P3'; % <== CHANGE HERE
  
  % echo_param.elev_comp: Elevation compensation 0=none, 1=relative, 2=surface flattened, 3=WGS-84
  echo_param.elev_comp = 2; % <== CHANGE HERE
  
  echo_param.plot_quality = false; % <== CHANGE HERE

  % param.out: output data product to use. For example:
  %   'qlook', 'standard', 'mvdr', 'CSARP_post/standard', 'CSARP_post/mvdr'
  param.out = 'CSARP_post/qlook'; % <== CHANGE HERE
  
  % param.img_name: output data product image. For example:
  %   '': combined product, 'img_01_', , 'img_02_'
  param.img_name = '';
  
  if echo_param.elev_comp == 3
    echo_param.depth = '[min(Surface_Elev)-3500 max(Surface_Elev)+200]'; % <== CHANGE HERE
    %echo_param.depth = '[1594.9 1635.1]';
  else
    echo_param.depth = '[min(Surface_Depth)-2 max(Surface_Depth) +20]'; % <== CHANGE HERE
    %echo_param.depth = '[-5 120]';
  end
  echo_param.depth_offset = 0;
  echo_param.time_offset = 0;
  echo_param.caxis = [];
  echo_param.er_ice = 3.15;
  
  % echo_param.axis_type: Units representation 'bars' or 'standard'
  echo_param.axis_type = 'standard';
  
  % param.create_map_en: set to true to produce a map
  param.create_map_en = false;
  
  % param.post.map.type: 'combined', 'singles', 'contour', 'contour-singles', or 'ASCAT'
  param.post.map.type = 'combined';
  
  % param.post.map.location: map choice 'Greenland', 'Antarctica', 'Arctic', 'Norway', or 'Canada'
  param.post.map.location = 'Greenland';
  
  % Enable for detrending
  if 0
    echo_param.detrend.mode = 'polynomial';
    echo_param.detrend.poly_order = 4;
    echo_param.detrend.depth = '[min(Surface_Depth)+1 max(Surface_Depth)+20.1]';
    %echo_param.filter = inline('wiener2(N,[3 31])');
  else
    echo_param.detrend = [];
  end
  % echo_param.filter = inline('fir_dec(N,ones([1 11])/11,1)');
  
  % param.use_master_surf: set to true if you want to use the previous
  % surface loaded by this function (this is useful when comparing to
  % different systems and you want the second system loaded to use the
  % surface from the first system loaded)
  param.use_master_surf = 0;

  % param.layer_params: set to plot layers on echograms
  layer_params = []; idx = 0;
  if 0 % Enable to plot layers on echograms
    layer_params = struct('name','surface','source','layerdata','layerdata_source','layerData_koenig');
    for idx = 2:30
      layer_params(end+1) = struct('name',sprintf('Koenig_%d',idx),'source','layerdata','layerdata_source','layerData_koenig');
    end
  end
  param.layer_params = layer_params;
  
  params(end+1) = param;
  echo_params(end+1) = echo_param;
end

%% Automated Section
% ====================================================================
% ====================================================================
  
physical_constants;

for param_idx = 1:length(params)
  param = params(param_idx);
  
  out_fn_dir_name = '';
  if ispc
    out_fn_dir = fullfile(getenv('USERPROFILE'),'Documents','load_data_by_gps_time',out_fn_dir_name,datestr(epoch_to_datenum(param.start.gps_time),'yyyymmdd'));
  else
    out_fn_dir = fullfile(getenv('HOME'),'load_data_by_gps_time',out_fn_dir_name,datestr(epoch_to_datenum(param.start.gps_time),'yyyymmdd'));
  end
  
  [output_dir,radar_type,radar_name] = ct_output_dir(param.radar_name);
  
  ds = load_data_by_gps_time(param);
    
  %% Uniform sampling in along-track of echogram
  % ===================================================================
  along_track = geodetic_to_along_track(ds.Latitude,ds.Longitude,0*ds.Elevation);
  if along_track(end)-along_track(1) > 100
    along_track = geodetic_to_along_track(ds.Latitude,ds.Longitude,0*ds.Elevation,50);
  end
  Nx = numel(along_track);
  dx = (along_track(end)-along_track(1)) / (Nx-1);
  new_along_track = dx*(0:Nx-1);
  ds.Data = interp1(along_track,ds.Data.',new_along_track,'linear','extrap').';
  ds.Latitude = interp1(along_track,ds.Latitude,new_along_track,'linear','extrap');
  ds.Longitude = interp1(along_track,ds.Longitude,new_along_track,'linear','extrap');
  ds.Elevation = interp1(along_track,ds.Elevation,new_along_track,'linear','extrap');
  ds.GPS_time = interp1(along_track,ds.GPS_time,new_along_track,'linear','extrap');
  ds.Surface = interp1(along_track,ds.Surface,new_along_track,'linear','extrap');
  
  if param_idx == 1
    mdata = ds;
  else
    field_names = fieldnames(ds);
    for field_idx = 1:length(field_names);
      mdata(param_idx).(field_names{field_idx}) = ds.(field_names{field_idx}); % MATLAB BUG???
    end
  end

  if param_idx > 1
    master = mdata(1);
    slave = mdata(param_idx);
    
    wgs84 = wgs84Ellipsoid('meters');
    master.ecef = zeros(3,length(master.Latitude));
    [master.ecef(1,:),master.ecef(2,:),master.ecef(3,:)] = geodetic2ecef(wgs84,master.Latitude,master.Longitude,zeros(size(master.Longitude)));
    slave.ecef = zeros(3,length(slave.Latitude));
    [slave.ecef(1,:),slave.ecef(2,:),slave.ecef(3,:)] = geodetic2ecef(wgs84,slave.Latitude,slave.Longitude,zeros(size(slave.Longitude)));
    
    reverse_test = dot(master.ecef(:,end)-master.ecef(:,1), slave.ecef(:,end)-slave.ecef(:,1)) < 0;
    if reverse_test
      slave.Latitude = slave.Latitude(1,end:-1:1);
      slave.Longitude = slave.Longitude(1,end:-1:1);
      slave.Elevation = slave.Elevation(1,end:-1:1);
      slave.Surface = slave.Surface(1,end:-1:1);
      slave.GPS_time = slave.GPS_time(1,end:-1:1);
      slave.ecef = slave.ecef(:,end:-1:1);
      slave.Data = slave.Data(:,end:-1:1);
    end
    
    %% Find the closest point on the master transect for each point in the slave
    rline_master = 1;
    for rline = 1:length(slave.Longitude)
      min_dist = master.ecef(:,rline_master)-slave.ecef(:,rline);
      min_dist = sqrt(dot(min_dist,min_dist));
      while rline_master < length(master.Longitude)
        dist = master.ecef(:,rline_master+1)-slave.ecef(:,rline);
        dist = sqrt(dot(dist,dist));
        if dist > min_dist
          break
        end
        min_dist = dist;
        rline_master = rline_master + 1;
      end
      slave.master_idx(rline) = rline_master;
      slave.master_dist(rline) = min_dist;
    end
    
    %% Trim repeat master_idx at the start and end
%     last_one_idx = find(slave.master_idx == 1,1,'last');
%     if isempty(last_one_idx)
%       last_one_idx = 1;
%     end
%     first_end_idx = find(slave.master_idx == length(master.Longitude),1);
%     
%     slave_idxs = last_one_idx:first_end_idx;
%     
%     slave.GPS_time = slave.GPS_time(slave_idxs);
%     slave.Latitude = slave.Latitude(slave_idxs);
%     slave.Longitude = slave.Longitude(slave_idxs);
%     slave.Elevation = slave.Elevation(slave_idxs);
%     slave.Surface = slave.Surface(slave_idxs);
%     slave.Data = slave.Data(:,slave_idxs);
%     slave.ecef = slave.ecef(:,slave_idxs);
    
    %% Interpolate slave onto master along track axis
    
    % 1. For each position on the slave trajectory, create coordinate system
    gps = [];
    gps.lat = master.Latitude;
    gps.lon = master.Longitude;
    gps.elev = zeros(size(master.Elevation));
    gps.gps_time = zeros(size(master.Elevation));
    gps.roll = zeros(size(master.Elevation));
    gps.pitch = zeros(size(master.Elevation));
    gps.heading = zeros(size(master.Elevation));
    gps.surface = master.Surface;
    ref = gps;
    SAR_coord_param.type = 2;
    SAR_coord_param.squint = [0 0 -1].';
    SAR_coord_param.Lsar = 500; % Increase this to create more smoothing in along-track
    along_track = geodetic_to_along_track(master.Latitude,master.Longitude);
    output_along_track = along_track;
    
    fcs = SAR_coord_system(SAR_coord_param,gps,ref,along_track,output_along_track);
    [lat,lon,elev] = ecef2geodetic(fcs.origin(1,:),fcs.origin(2,:),fcs.origin(3,:),wgs84);
    
    % 2. Use that coordinate system to determine where the master points would
    % lie on it
    slave.along_track = zeros(size(slave.Latitude));
    for rline = 1:length(slave.Latitude)
      fcs_idx = slave.master_idx(rline);
      slave.along_track(rline) = along_track(fcs_idx) ...
        + dot(fcs.x(:,fcs_idx), slave.ecef(:,rline)-master.ecef(:,fcs_idx));
    end
    
    % 3. Resample the slave data onto these master points
    slave.Data = interp1(slave.along_track,slave.Data.',along_track,'nearest').';
    slave.GPS_time = interp1(slave.along_track,slave.GPS_time.',along_track,'linear','extrap');
    slave.Latitude = interp1(slave.along_track,slave.Latitude.',along_track,'nearest','extrap');
    slave.Longitude = interp1(slave.along_track,slave.Longitude.',along_track,'nearest','extrap');
    slave.Latitude = master.Latitude;
    slave.Longitude = master.Longitude;
    slave.Elevation = interp1(slave.along_track,slave.Elevation.',along_track,'nearest','extrap');
    slave.Surface = interp1(slave.along_track,slave.Surface.',along_track,'nearest','extrap');

    ds = slave;
  end
  
  % Create time-stamp strings used in filenames
  start_time_stamp_str = datestr(epoch_to_datenum(param.start.gps_time),'yyyymmdd_HHMMSS');
  stop_time_stamp_str = datestr(epoch_to_datenum(param.stop.gps_time),'yyyymmdd_HHMMSS');
  
  if strcmp(output_dir,'accum')
    echo_param.fig_hand = 3 + 10*(param_idx-1);
  elseif strcmp(param.radar_name,'kuband')
    echo_param.fig_hand = 4 + 10*(param_idx-1);
  elseif strcmp(param.radar_name,'rds')
    echo_param.fig_hand = 5 + 10*(param_idx-1);
  elseif strcmp(param.radar_name,'snow')
    echo_param.fig_hand = 6 + 10*(param_idx-1);
  elseif strcmp(param.radar_name,'kaband')
    echo_param.fig_hand = 7 + 10*(param_idx-1);
  else
    error('Unsupported radar type %s', param.radar_name);
  end

  % Create output directory
  param.save_files = false;
  if param.save_files && ~exist(out_fn_dir,'dir')
    fprintf('Creating output directory %s\n', out_fn_dir);
    mkdir(out_fn_dir);
  end

  %% Create map template using publish_map.m
  % =========================================================================
  if ~strcmpi(param.post.map.type,'none') && param.create_map_en
    fprintf('Creating map template (%s)\n', datestr(now));
    
    % --------------------------------------------------
    % Create base map to publish in with publish_map
    map_param = [];
    map_param.type = param.post.map.type;
    map_param.location = param.post.map.location;
    map_param.fig_hand = 1;
    map_param.map_title = '';
    map_param.decimate_seg = false;
    map_param.resample = false;
    % structure fields necessary for ASCAT maps
    if strcmpi(param.post.map.type, 'ASCAT')
      map_param.year = param.start.year;
      map_param.month = param.start.month;
      map_param.day = param.start.day;
    end
    map_info = publish_map('setup',map_param);
    
    % --------------------------------------------------
    % Create flight path variables for publish_map
    vectors.lat = Latitude;
    vectors.lon = Longitude;
    
    [x,y] = projfwd(map_info.proj,vectors.lat,vectors.lon);
    day_segs_idx(1) = 1;
    day_seg_x{1} = x/1e3;
    day_seg_y{1} = y/1e3;
    
    % --------------------------------------------------
    % Plot flightlines over geotiff using publish_map
    map_param.day_seg_x = day_seg_x{1}*1000;
    map_param.day_seg_y = day_seg_y{1}*1000;
    [frame_X,frame_Y] = projfwd(map_info.proj,Latitude,Longitude);
    map_param.frame_X = {frame_X};
    map_param.frame_Y = {frame_Y};
    map_info = publish_map('delete',map_param,map_info);
    map_info = publish_map('plot',map_param,map_info);
    
    % --------------------------------------------------
    % Save map file
    time_stamp_str = datestr(epoch_to_datenum(param.start.gps_time),'yyyymmdd_HHMMSS');
    out_fn = fullfile(out_fn_dir, sprintf('%s_%s_0map.jpg',start_time_stamp_str, ...
      stop_time_stamp_str));
    if param.save_files
      fprintf('Saving to %s\n', out_fn);
      saveas(map_param.fig_hand,out_fn);
    end
  end
  
  %% Create echogram plot
  % ===================================================================
  
  echo_param.num_x_tics = 4;
  echo_param.frm_id = '';
  
  lay = [];
  lay.GPS_time = ds.GPS_time;
  lay.Elevation = ds.Elevation;
      
  master = [];
  master.GPS_time = ds.GPS_time;
  master.Latitude = ds.Latitude;
  master.Longitude = ds.Longitude;
  master.Elevation = ds.Elevation;

  if ds.Latitude<0
    ds.param_records.post.ops.location = 'antarctic';
  else
    ds.param_records.post.ops.location = 'arctic';
  end
  
  global gRadar;
  param = merge_structs(param,ds.param_records);
  param = merge_structs(param,gRadar);

  surface_layer = {opsLoadLayers(param, surface_source)};
  
  surface_lay = opsInterpLayersToMasterGPSTime(master,surface_layer,gaps_dist);
  surface_data = surface_lay.layerData{1}.value{2}.data;

  lay.layerData{1}.value{1}.data = NaN*zeros(size(surface_data));

  if param.use_master_surf
    % Use master surface (useful when comparing multiple radar outputs
    % which each have their own surface variable and a common surface should be used
    if exist('master_surf_filt','var')
      lay.layerData{1}.value{2}.data = interp1(master_surf_gps_time,master_surf_filt,lay.GPS_time,'linear','extrap');
      if master_surf_gps_time(1)-5 > lay.GPS_time(1) ...
          || master_surf_gps_time(end)+5 < lay.GPS_time(end)
        warning('Using master surface on nonmatching GPS times');
        keyboard
      end
    else
      master_surf_filt = surface_data;
      master_surf_gps_time = lay.GPS_time;
      lay.layerData{1}.value{2}.data = surface_data;
    end
  else
    lay.layerData{1}.value{2}.data = surface_data;
  end
  
  layer_params = param.layer_params;
  
  if isempty(layer_params)
    lay.layerData{2}.value{1}.data = NaN*zeros(size(surface_data));
    lay.layerData{2}.value{2}.data = NaN*zeros(size(surface_data));
    
  else
    %% Load bottom layer
    
    layers = opsLoadLayers(param,layer_params);
    
    % Interpolate all layers onto a common master reference
    for lay_idx = 1:length(layers)
      ops_layer = [];
      ops_layer{1}.gps_time = layers(lay_idx).gps_time;
      ops_layer{1}.type = layers(lay_idx).type;
      ops_layer{1}.quality = layers(lay_idx).quality;
      ops_layer{1}.twtt = layers(lay_idx).twtt;
      ops_layer{1}.type(isnan(ops_layer{1}.type)) = 2;
      ops_layer{1}.quality(isnan(ops_layer{1}.quality)) = 1;
      
      load_lay = opsInterpLayersToMasterGPSTime(master,ops_layer,gaps_dist);
      
      lay.layerData{end+1} = load_lay.layerData{1};

    end
  end
  
  % Use first layerData as surface layer for publish_echogram
  surface_layer = lay.layerData{1};
  layers_to_plot = lay;
  % Use remaining layerDatas as layers to be plotted in publish_echogram
  layers_to_plot.layerData = layers_to_plot.layerData(2:end);

  echo_info = publish_echogram(echo_param,ds,layers_to_plot,surface_layer);
  season_name = param.season_name;
  season_name(season_name=='_') = ' ';
  title(sprintf('%s %s %s to %s', param.radar_name, season_name, ...
    datestr(epoch_to_datenum(param.start.gps_time)), datestr(epoch_to_datenum(param.stop.gps_time),'HH:MM:SS')));
  % set(echo_info.echo_title,'Visible', 'off');

  %% Save echogram file
  if param.save_files
    out_fn = fullfile(out_fn_dir, sprintf('%s_%s_%s.jpg',start_time_stamp_str, ...
      stop_time_stamp_str, param.radar_name));
    fprintf('Saving to %s\n', out_fn);
    saveas(echo_param.fig_hand,out_fn);

    out_fn = fullfile(out_fn_dir, sprintf('%s_%s_%s.fig',start_time_stamp_str, ...
      stop_time_stamp_str, param.radar_name));
    fprintf('Saving to %s\n', out_fn);
    saveas(echo_param.fig_hand,out_fn);
  end
end