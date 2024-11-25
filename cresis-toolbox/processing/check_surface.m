function check_surface(param,param_override)
% check_surface(param,param_override)
%
% 1. Loads coincident LIDAR data if it exists
%
% 2. Loads DTU sea surface DEM and arctic/antarctica land DEM, combines
% these two DEMS taking land DEM over sea surface DEM.
%
% 3. Combines LIDAR data and DEM data, taking LIDAR data over DEM data.
% Uses elevation to interpolate where data are not available.
%
% 4. Estimates Tadc_adjust or t_ref error by comparing radar surface from
% the specified layer source and the LIDAR/DEM combination.
%    * The error is calculated as the correction that needs to be applied.
%    In other words if the radar surface twtt is too large, then the error
%    is reported as a negative number.
%    * This error should be added to param.radar.wfs.Tadc_adjust for pulsed
%    systems.
%    * This error should be added to param.radar.wfs.t_ref for deramp
%    systems.
%
% 5. Estimates GPS offset by comparing radar surface to LIDAR and/or DEM
% surface. This offset should be added to the current
% param.records.gps.time_offset in the parameter spreadsheet. See wiki:
% https://gitlab.com/openpolarradar/opr/-/wikis/System-Time-Delay#updating-gps-offset
%
% 6. For deramp systems, uses the LIDAR/DEM data to determine the Nyquist
% zone and sets the records.settings.nyquist_zone based on this. The second
% decimal mask in frames.proc_mode is also set to one for frames that will
% be outside max_nyquist_zone.
%
% See run_check_surface.m for how to run.
%
% cat /N/dcwan/projects/cresis/output/ct_tmp/check_surface/snow/2017_Greenland_P3/*.txt
%
% Author: John Paden

% =====================================================================
%% General Setup
% =====================================================================
param = merge_structs(param, param_override);

fprintf('=====================================================================\n');
fprintf('%s: %s (%s)\n', mfilename, param.day_seg, datestr(now));
fprintf('=====================================================================\n');

% =====================================================================
%% Input checks
% =====================================================================

physical_constants();
[~,radar_type] = ct_output_dir(param.radar_name);

%% Input Checks: radar
if ~isfield(param,'radar') || isempty(param.radar)
  param.radar = [];
end

if ~isfield(param.radar,'wfs') || isempty(param.radar.wfs)
  param.radar.wfs = [];
end

wf = 1;
if ~isfield(param.radar.wfs,'Tadc_adjust') || isempty(param.radar.wfs(wf).Tadc_adjust)
  param.radar.wfs(wf).Tadc_adjust = 0;
end

if strcmpi(radar_type,'deramp') && (~isfield(param.radar,'nz_valid') || isempty(param.radar.nz_valid))
  warning('Default Nyquist zones not specified in param.radar.nz_valid. Setting to [0,1,2,3] which may not be correct.');
  param.radar.nz_valid = [0 1 2 3];
end

%% Input Checks: check_surface
if ~isfield(param,mfilename) || isempty(param.(mfilename))
  param.(mfilename) = [];
end

if ~isfield(param.(mfilename),'debug_out_dir') || isempty(param.(mfilename).debug_out_dir)
  param.(mfilename).debug_out_dir = mfilename;
end

if ~isfield(param.(mfilename),'debug_plots') || isempty(param.(mfilename).debug_plots)
  param.(mfilename).debug_plots = {'visible','twtt','gps','nz'};
end
enable_visible_plot = any(strcmp('visible',param.check_surface.debug_plots));
enable_twtt_plot = any(strcmp('twtt',param.check_surface.debug_plots));
enable_gps_plots = any(strcmp('gps',param.check_surface.debug_plots));
enable_nz_plot = any(strcmp('nz',param.check_surface.debug_plots));
if ~isempty(param.(mfilename).debug_plots)
  h_fig = get_figures(5,enable_visible_plot);
end
fn = ct_filename_ct_tmp(param,'',param.(mfilename).debug_out_dir,'');
fn_dir = fileparts(fn);
if ~exist(fn_dir,'dir')
  mkdir(fn_dir);
end

if ~isfield(param.check_surface,'max_twtt_diff') || isempty(param.check_surface.max_twtt_diff)
  param.check_surface.max_twtt_diff = 200e-9;
end

if ~isfield(param.check_surface,'radar_gps_max_lag') || isempty(param.check_surface.radar_gps_max_lag)
  % Default 40 seconds: this is the maximum number of seconds for the GPS time lag
  % search
  param.check_surface.radar_gps_max_lag = 40.0;
end

if ~isfield(param.check_surface,'radar_gps_time_offset') || isempty(param.check_surface.radar_gps_time_offset)
  % Default 0 seconds: this gps time offset will be added in the layer
  % interpolation. Used to test GPS offsets.
  param.check_surface.radar_gps_time_offset = 0.0;
end

if ~isfield(param.check_surface,'radar_layer_params') || isempty(param.check_surface.radar_layer_params)
  param.check_surface.radar_layer_params.name = 'surface';
  param.check_surface.radar_layer_params.source = 'layerdata';
end

if ~isfield(param.check_surface,'radar_twtt_offset') || isempty(param.check_surface.radar_twtt_offset)
  % Default zero: this value will be added to the radar twtt. Used to test
  % twtt offsets.
  param.check_surface.radar_twtt_offset = 0.0;
end

if ~isfield(param.check_surface,'radar_twtt_ratio') || isempty(param.check_surface.radar_twtt_ratio)
  % Default one: this value will be multiplied with the radar twtt. Used to
  % test incorrect sampling frequency (e.g. deramp on receive with wrong
  % f0/f1/Tpd parameters).
  param.check_surface.radar_twtt_ratio = 1.0;
end

if ~isfield(param.check_surface,'records_threshold') || isempty(param.check_surface.records_threshold)
  % Default 1000: minimum number of records to use for comparison before
  % trying to add more data from land DEM or mean sea level.
  param.check_surface.records_threshold = 1000;
end

if ~isfield(param.check_surface,'ref_interp_gaps_dist') || isempty(param.check_surface.ref_interp_gaps_dist)
  param.check_surface.ref_interp_gaps_dist = [150 75];
end

if ~isfield(param.check_surface,'ref_layer_params') || isempty(param.check_surface.ref_layer_params)
  param.check_surface.ref_layer_params.name = 'surface';
  param.check_surface.ref_layer_params.source = 'lidar';
  param.check_surface.ref_layer_params.lidar_source = 'atm';
  param.check_surface.ref_layer_params.lever_arm_en = true;
end
layer_params = cat_structs(2,param.check_surface.ref_layer_params,param.check_surface.radar_layer_params);

if ~isfield(param.check_surface,'refine_Tsys_en') || isempty(param.check_surface.refine_Tsys_en)
  param.check_surface.refine_Tsys_en = false;
end

if ~isfield(param.check_surface,'save_records_en') || isempty(param.check_surface.save_records_en)
  param.check_surface.save_records_en = false;
end

% =========================================================================
%% Setup
% =========================================================================

% Load records file
records = records_load(param);

% Load frames file
frames = frames_load(param);

% =========================================================================
%% Load in ocean mask, land DEM, and sea surface DEM
% =========================================================================

global gdem;
if isempty(gdem) || ~isa(gdem,'dem_class') || ~isvalid(gdem)
  gdem = dem_class(param,500);
end
gdem.set_res(500);
gdem.ocean_mask_mode = 'l';

gdem_str = sprintf('%s:%s:%s',param.radar_name,param.season_name,param.day_seg);
if ~strcmpi(gdem_str,gdem.name)
  gdem.set_vector(records.lat,records.lon,gdem_str);
end

% =====================================================================
%% Load layer data
% =====================================================================

ref_idx = 1; % Make the radar the master "slow" time axis
radar_idx = 2; % Make the radar the master "slow" time axis

% Load radar surface (default layerdata) and reference surface (default ATM
% lidar)
layers = opsLoadLayers(param,layer_params);

% Throw out low quality radar data
layers(radar_idx).twtt(layers(radar_idx).quality==3) = NaN;

% Add GPS offset in
new_gps_time = layers(radar_idx).gps_time - param.check_surface.radar_gps_time_offset;
layers(radar_idx).lat = interp1(layers(radar_idx).gps_time,layers(radar_idx).lat,new_gps_time,'linear','extrap');
layers(radar_idx).lon = interp1(layers(radar_idx).gps_time,layers(radar_idx).lon,new_gps_time,'linear','extrap');
layers(radar_idx).elev = interp1(layers(radar_idx).gps_time,layers(radar_idx).elev,new_gps_time,'linear','extrap');
layers(radar_idx).gps_time = new_gps_time;

% Interpolate ref layer to radar gps time
master = [];
master.GPS_time = layers(radar_idx).gps_time;
master.Latitude = layers(radar_idx).lat;
master.Longitude = layers(radar_idx).lon;
master.Elevation = layers(radar_idx).elev;

ops_layer = [];
ops_layer{1}.gps_time = layers(ref_idx).gps_time;
ops_layer{1}.type = layers(ref_idx).type;
ops_layer{1}.quality = layers(ref_idx).quality;
ops_layer{1}.twtt = layers(ref_idx).twtt;
ops_layer{1}.type(isnan(ops_layer{1}.type)) = 2;
ops_layer{1}.quality(isnan(ops_layer{1}.quality)) = 1;
lay = opsInterpLayersToMasterGPSTime(master,ops_layer,param.check_surface.ref_interp_gaps_dist);
layers(ref_idx).twtt_ref = lay.layerData{1}.value{2}.data;

% Stretch and offset the twtt
layers(radar_idx).twtt = layers(radar_idx).twtt * param.check_surface.radar_twtt_ratio;
layers(radar_idx).twtt = layers(radar_idx).twtt + param.check_surface.radar_twtt_offset;

% =====================================================================
%% Merge sea-surface/land DEM and elevation information with layer info
% =====================================================================

mdata.Longitude = layers(radar_idx).lon;
mdata.Latitude = layers(radar_idx).lat;
mdata.Elevation = layers(radar_idx).elev;

gdem.set_vector(mdata.Latitude,mdata.Longitude);
[mdata.land_dem,mdata.sea_dem,ocean_mask] = gdem.get_vector_dem();

% Merge land surface and sea surface DEMs
surf.dem = mdata.land_dem;
surf.dem(ocean_mask) = mdata.sea_dem(ocean_mask);
surf.dem_twtt = (mdata.Elevation - surf.dem) / (c/2);

% Merge land/sea surface with reference (usually lidar) layer
surf.dem_twtt = merge_vectors(layers(ref_idx).twtt_ref, surf.dem_twtt);

mdata.land_dem_twtt = (mdata.Elevation - mdata.land_dem) / (c/2);
mdata.sea_dem_twtt = (mdata.Elevation - mdata.sea_dem) / (c/2);

% =====================================================================
%% Check surface: System time delay
% =====================================================================

lay_idx = 1;
twtt_error_all = surf.dem_twtt - layers(radar_idx).twtt;
twtt_error = twtt_error_all;
twtt_error(abs(twtt_error) > param.check_surface.max_twtt_diff) = NaN;

mean_offset = nanmean(twtt_error);
origin = layers(radar_idx).gps_time(1);

if enable_twtt_plot
  figure(h_fig(1)); clf(h_fig(1));
  set(h_fig(1),'name',sprintf('TWTT error %s',param.day_seg));
  h_axes(1) = axes('parent',h_fig(1));
  plot(h_axes(1),layers(radar_idx).gps_time - origin, twtt_error_all*1e9)
  hold(h_axes(1),'on');
  plot(h_axes(1),layers(radar_idx).gps_time - origin, twtt_error*1e9,'g.')
  xlabel(h_axes(1),sprintf('Relative GPS time (sec from %s)', datestr(epoch_to_datenum(origin))));
  ylabel(h_axes(1),'TWTT error (ns)');
  grid(h_axes(1),'on');
  if max(twtt_error_all)>min(twtt_error_all)
    ylim(h_axes(1),[min(twtt_error_all) max(twtt_error_all)]*1e9);
  end
  legend(h_axes(1), 'All','Thresholded','location','best')
  
  fig_fn = ct_filename_ct_tmp(param,'',param.(mfilename).debug_out_dir,'twtt_error');
  fprintf('Saving %s\n', fig_fn);
  fig_fn_dir = fileparts(fig_fn);
  if ~exist(fig_fn_dir,'dir')
    mkdir(fig_fn_dir);
  end
  ct_saveas(h_fig(1),[fig_fn '.fig']);
  ct_saveas(h_fig(1),[fig_fn '.jpg']);
end

% =====================================================================
%% Check surface: GPS Offset
% =====================================================================

% Find the longest contiguous section of small twtt_error
% 1. Try LIDAR-only first
mask = ~isnan(twtt_error) & ~isnan(layers(ref_idx).twtt_ref);
mask_length = zeros(size(mask));
mask_length(1) = mask(1);
for idx=2:length(mask)
  mask_length(idx) = mask(idx)*mask_length(idx-1) + mask(idx);
end
[corr_len,corr_idx] = max(mask_length);
if corr_len==0
  recs = [];
else
  gpstime_coords = layers(radar_idx).gps_time(corr_idx+[-corr_len+1,0]);
  recs = find(layers(radar_idx).gps_time >= min(gpstime_coords) ...
    & layers(radar_idx).gps_time <= max(gpstime_coords));
end
dem_source = 'lidar';
% 2. Try LIDAR+Land next
if length(recs)<param.check_surface.records_threshold
  mask = ~isnan(twtt_error) & ~isnan(mdata.land_dem);
  mask_length = zeros(size(mask));
  mask_length(1) = mask(1);
  for idx=2:length(mask)
    mask_length(idx) = mask(idx)*mask_length(idx-1) + mask(idx);
  end
  [corr_len,corr_idx] = max(mask_length);
  if corr_len==0
    recs = [];
  else
    gpstime_coords = layers(radar_idx).gps_time(corr_idx+[-corr_len+1,0]);
    recs = find(layers(radar_idx).gps_time >= min(gpstime_coords) ...
      & layers(radar_idx).gps_time <= max(gpstime_coords));
  end
  dem_source = 'land';
end
% 3. Try LIDAR+Land+Sea next
if length(recs)<param.check_surface.records_threshold
  mask = ~isnan(twtt_error);
  mask_length = zeros(size(mask));
  mask_length(1) = mask(1);
  for idx=2:length(mask)
    mask_length(idx) = mask(idx)*mask_length(idx-1) + mask(idx);
  end
  [corr_len,corr_idx] = max(mask_length);
  if corr_len==0
    recs = [];
  else
    gpstime_coords = layers(radar_idx).gps_time(corr_idx+[-corr_len+1,0]);
    recs = find(layers(radar_idx).gps_time >= min(gpstime_coords) ...
      & layers(radar_idx).gps_time <= max(gpstime_coords));
  end
  dem_source = 'sea';
end

debug_gps_offset = 0;
debug_Tsys_offset = 0;
debug_Tsys_ratio = 1;

if any(~isnan(mdata.land_dem(recs)))
end
if any(~isnan(layers(ref_idx).twtt_ref(recs)))
end

if enable_twtt_plot
  clf(h_fig(2));
  set(h_fig(2),'name',sprintf('TWTT vs Frame %s',param.day_seg));
  h_axes(2) = axes('parent',h_fig(2));
  origin = layers(radar_idx).gps_time(1);
  h_plot = [];
  frms = interp1([records.gps_time(frames.frame_idxs), records.gps_time(end)+diff(records.gps_time(end-1:end))], ...
    [1:length(frames.frame_idxs), length(frames.frame_idxs)+1], layers(radar_idx).gps_time);
  h_plot(end+1) = plot(h_axes(2),frms, mdata.land_dem_twtt);
  hold(h_axes(2),'on');
  h_plot(end+1) = plot(h_axes(2),frms, mdata.sea_dem_twtt);
  h_plot(end+1) = plot(h_axes(2),frms, layers(ref_idx).twtt_ref);
  h_plot(end+1) = plot(h_axes(2),frms, surf.dem_twtt);
  if ~isempty(recs)
    h_plot(end+1) = plot(h_axes(2),frms(recs), mdata.land_dem_twtt(recs), 'x');
    h_plot(end+1) = plot(h_axes(2),frms(recs), mdata.sea_dem_twtt(recs), 'o');
    h_plot(end+1) = plot(h_axes(2),frms(recs), layers(ref_idx).twtt_ref(recs), '<');
    h_plot(end+1) = plot(h_axes(2),frms(recs), surf.dem_twtt(recs), '.');
    for idx=1:4
      set(h_plot(idx+4),'Color',get(h_plot(idx),'Color'));
    end
  end
  frms = interp1([records.gps_time(frames.frame_idxs), records.gps_time(end)+diff(records.gps_time(end-1:end))] + debug_gps_offset, ...
    [1:length(frames.frame_idxs), length(frames.frame_idxs)+1], layers(radar_idx).gps_time);
  h_plot(9) = plot(h_axes(2),frms, layers(radar_idx).twtt*debug_Tsys_ratio + debug_Tsys_offset,'k','LineWidth',2);
  legend(h_axes(2),h_plot([1:4 9]),'Land','Sea','Ref','Combined','Radar','location','best');
  grid(h_axes(2),'on');
  xlabel(h_axes(2),'Frame');
  ylabel(h_axes(2),'TWTT (sec)');
  fig_fn = ct_filename_ct_tmp(param,'',param.(mfilename).debug_out_dir,'twtt_frm');
  fprintf('Saving %s\n', fig_fn);
  ct_saveas(h_fig(2),[fig_fn '.fig']);
  ct_saveas(h_fig(2),[fig_fn '.jpg']);
  
  clf(h_fig(3));
  set(h_fig(3),'name',sprintf('TWTT vs GPS time %s',param.day_seg));
  h_axes(3) = axes('parent',h_fig(3));
  origin = layers(radar_idx).gps_time(1);
  h_plot = [];
  h_plot(end+1) = plot(h_axes(3),layers(radar_idx).gps_time - origin, mdata.land_dem_twtt);
  hold(h_axes(3),'on');
  h_plot(end+1) = plot(h_axes(3),layers(radar_idx).gps_time - origin, mdata.sea_dem_twtt);
  h_plot(end+1) = plot(h_axes(3),layers(radar_idx).gps_time - origin, layers(ref_idx).twtt_ref);
  h_plot(end+1) = plot(h_axes(3),layers(radar_idx).gps_time - origin, surf.dem_twtt);
  if ~isempty(recs)
    h_plot(end+1) = plot(h_axes(3),layers(radar_idx).gps_time(recs) - origin, mdata.land_dem_twtt(recs), 'x');
    h_plot(end+1) = plot(h_axes(3),layers(radar_idx).gps_time(recs) - origin, mdata.sea_dem_twtt(recs), 'o');
    h_plot(end+1) = plot(h_axes(3),layers(radar_idx).gps_time(recs) - origin, layers(ref_idx).twtt_ref(recs), '<');
    h_plot(end+1) = plot(h_axes(3),layers(radar_idx).gps_time(recs) - origin, surf.dem_twtt(recs), '.');
    for idx=1:4
      set(h_plot(idx+4),'Color',get(h_plot(idx),'Color'));
    end
  end
  h_plot(9) = plot(h_axes(3),layers(radar_idx).gps_time + debug_gps_offset - origin, layers(radar_idx).twtt*debug_Tsys_ratio + debug_Tsys_offset,'k','LineWidth',2);
  legend(h_axes(3),h_plot([1:4 9]),'Land','Sea','Ref','Combined','Radar','location','best');
  grid(h_axes(3),'on');
  xlabel(h_axes(3),sprintf('Relative GPS time (sec from %s)', datestr(epoch_to_datenum(origin))));
  ylabel(h_axes(3),'TWTT (sec)');
  fig_fn = ct_filename_ct_tmp(param,'',param.(mfilename).debug_out_dir,'twtt');
  fprintf('Saving %s\n', fig_fn);
  ct_saveas(h_fig(3),[fig_fn '.fig']);
  ct_saveas(h_fig(3),[fig_fn '.jpg']);
  
  if 0
    % Correlate to determine GPS offsets
    fprintf('Pick two points on figure 1 to constrain the cross correlation to a section of lidar elevation and radar elevation that are correct (but possibly offset in radar.wfs.Tsys and gps.time_offset).\n');
    fprintf('For each click hold mouse button still after click until cross hairs re-appear\n');
    [gpstime_coords,tmp] = ginput(2);
  end
end


% Uniformly time sample the two signals
dt = median(diff(layers(radar_idx).gps_time(recs)));
if length(recs) <= 1
  ref_corr = NaN;
  lags = NaN;
  peak_idx = 1;
else
  t0 = layers(radar_idx).gps_time(recs(1));
  gps_time = t0:dt:layers(radar_idx).gps_time(recs(end));
  radar_layer = interp1(layers(radar_idx).gps_time, ...
    layers(radar_idx).twtt, gps_time);
  if length(layers(radar_idx).gps_time) < 2
    ref_layer = NaN(size(gps_time));
  else
    ref_layer = interp1(layers(radar_idx).gps_time, ...
      surf.dem_twtt, gps_time);
  end
  
  radar_layer = radar_layer - mean(radar_layer);
  ref_layer = ref_layer - mean(ref_layer);
  
  if 0
    [ref_corr,lags] = xcorr(radar_layer,ref_layer);
  else
    max_lag = round(param.check_surface.radar_gps_max_lag/dt);
    lags = -max_lag:max_lag;
    ref_corr = zeros(1,length(lags));
    for lag_idx = 1:length(lags)
      lag = lags(lag_idx);
      ref_corr(lag_idx) = sum(abs(radar_layer(1+max_lag:end-max_lag)-ref_layer(lag + [1+max_lag:end-max_lag])));
    end
    ref_corr = 1./ref_corr;
  end
  [peak_val,peak_idx] = max(ref_corr);
  if peak_idx == 1 || isnan(peak_val)
    lags(peak_idx) = NaN;
  end
    
end

clf(h_fig(4));
set(h_fig(4),'name','GPS');
h_axes(4) = axes('parent',h_fig(4));
plot(h_axes(4),-lags*dt,ref_corr)
xlabel(h_axes(4),'Radar''s time lag relative to actual time (sec)');
ylabel(h_axes(4),'Cross correlation');
grid(h_axes(4),'on');
fig_fn = ct_filename_ct_tmp(param,'',param.(mfilename).debug_out_dir,'gps');
fprintf('Saving %s\n', fig_fn);
ct_saveas(h_fig(4),[fig_fn '.fig']);
ct_saveas(h_fig(4),[fig_fn '.jpg']);


% =====================================================================
%% Check surface: Nyquist Zone
% =====================================================================
if strcmpi(radar_type,'deramp')
  
  param.load.imgs = {[1 1]};
  [wfs,~] = data_load_wfs(param,records);
  
  % Calculate Nyquist zone based on above ground level (AGL) altitude
  wf = 1;
  adc = 1;
  nz_twtt = param.radar.fs/2 / abs(wfs(wf).chirp_rate);
  
  nz = floor((surf.dem_twtt+wfs(wf).Tsys(wfs(wf).rx_paths(adc))-wfs(wf).t_ref) / nz_twtt);
  interp_nz = isnan(nz);
  nz = round(interp_finite(nz,NaN));
  
  default_nz = mode(nz(nz <=  max(param.radar.nz_valid) & ~isnan(nz)));
  
  nz(isnan(nz)) = default_nz;
  nz(nz<min(param.radar.nz_valid)) = min(param.radar.nz_valid);
  nz(nz>max(param.radar.nz_valid)) = max(param.radar.nz_valid);
  
  if isfield(records,'nyquist_zone_sig')
    original_nz = records.nyquist_zone_sig;
  else
    original_nz = nan(size(records.gps_time));
  end
  records.nyquist_zone_sig = interp1(layers(radar_idx).gps_time,nz,records.gps_time,'nearest','extrap');
  
  if param.check_surface.save_records_en
    records_fn = ct_filename_support(param,'','records');
    ct_save(records_fn,'-append','-struct','records','nyquist_zone_sig');
  end
  
  clf(h_fig(5));
  set(h_fig(5),'name','NZ');
  h_axes(5) = axes('parent',h_fig(5));
  plot(h_axes(5),layers(radar_idx).gps_time - origin, nz,'o');
  hold(h_axes(5),'on');
  plot(layers(radar_idx).gps_time(~interp_nz) - origin, nz(~interp_nz), 'r.');
  plot(h_axes(5),records.gps_time - origin, original_nz,'g-');
  title(h_axes(5),'Nyquist Zone');
  ylim(h_axes(5),[-0.1+min(param.radar.nz_valid), max(param.radar.nz_valid)+0.1]);
  
  fig_fn = ct_filename_ct_tmp(param,'',param.(mfilename).debug_out_dir,'nz');
  fprintf('Saving %s\n', fig_fn);
  ct_saveas(h_fig(5),[fig_fn '.fig']);
  ct_saveas(h_fig(5),[fig_fn '.jpg']);
else
  default_nz = NaN;
end

% =====================================================================
%% Check surface: Text file
% =====================================================================
wf = 1;
if strcmpi(radar_type,'deramp')
  % Find the new t_ref value
  BW = diff(param.radar.wfs(wf).BW_window);
  dt = 1/BW;
  t_ref_new = param.radar.wfs(wf).t_ref + param.check_surface.radar_twtt_offset + round(nanmedian(twtt_error)/dt)*dt;
else
  % Find the new Tadc_adjust (called t_ref_new to match deramp) value
  t_ref_new = param.radar.wfs(wf).Tadc_adjust + param.check_surface.radar_twtt_offset + round(nanmedian(twtt_error)*1e10)/1e10;
end

txt_headers_fn = fullfile(fn_dir,'time_00000000_00.txt');
fprintf('Saving headers %s\n', txt_headers_fn);
[fid,msg] = fopen(txt_headers_fn,'wb');
if fid < 0
  error('Could not open file:\n  %s\nError message: %s.', txt_headers_fn, msg);
end
fprintf(fid,'%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n', ...
  'Segment', 'Mean error', ...
  'Median error', ...
  'Std error', ...
  'Max error', ...
  'Mean error all', ...
  'Median error all', '#records', 'GPS lag', 'Default NZ', 't_ref_or_Tadc_adjust', 'DEM');
fclose(fid);

txt_fn = [ct_filename_ct_tmp(param,'',param.(mfilename).debug_out_dir,'time') '.txt'];
fprintf('Saving %s\n', txt_fn);
[fid,msg] = fopen(txt_fn,'wb');
if fid < 0
  error('Could not open file:\n  %s\nError message: %s.', txt_fn, msg);
end
fprintf(fid,'%s\t%.3f\t%.3f\t%.3f\t%.3f\t%.3f\t%.3f\t%d\t%.1f\t%.0f\t%.12g\t%s\n', ...
  param.day_seg, 1e9*mean_offset, ...
  1e9*nanmedian(twtt_error), ...
  1e9*nanstd(twtt_error), ...
  1e9*nanmax(abs(twtt_error-mean_offset)), ...
  1e9*nanmean(twtt_error_all), ...
  1e9*nanmedian(twtt_error_all), numel(recs), lags(peak_idx)*dt, default_nz, 1e9*t_ref_new, dem_source);
fclose(fid);

fprintf(1,'%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n', ...
  'Segment', 'Mean error', ...
  'Median error', ...
  'Std error', ...
  'Max error', ...
  'Mean error all', ...
  'Median error all', '#records', 'GPS lag', 'Default NZ', 't_ref_or_Tadc_adjust', 'DEM');
fprintf(1,'%s\t%.3f\t%.3f\t%.3f\t%.3f\t%.3f\t%.3f\t%d\t%.1f\t%.0f\t%.12g\t%s\n', ...
  param.day_seg, 1e9*mean_offset, ...
  1e9*nanmedian(twtt_error), ...
  1e9*nanstd(twtt_error), ...
  1e9*nanmax(abs(twtt_error-mean_offset)), ...
  1e9*nanmean(twtt_error_all), ...
  1e9*nanmedian(twtt_error_all), numel(recs), lags(peak_idx)*dt, default_nz, 1e9*t_ref_new, dem_source);
fprintf('All twtt times are in ns\n');

% =====================================================================
%% Check surface: Tsys Refinement
% =====================================================================
if param.check_surface.refine_Tsys_en
  % Uses specular leads to check Tsys
  deconv_fn = fullfile(ct_filename_out(param, 'noise', '', 1), sprintf('specular_%s.mat', param.day_seg));
  fprintf('Loading %s (%s)\n', deconv_fn, datestr(now))
  spec = load(deconv_fn);
  spec_gps_time = spec.gps_time(spec.peakiness > 40);
  fprintf('  %d specularity records\n', length(spec_gps_time));
  records = load(ct_filename_support(param,'','records'));
  along_track = geodetic_to_along_track(records.lat,records.lon);
  frames = frames_load(param);
  
  record = [];
  spec_frm = [];
  spec_gps = [];
  spec_fn = {};
  spec_radar_surf = [];
  spec_radar_peak = [];
  spec_atm = [];
  spec_atm_slope = [];
  spec_radar_slope = [];
  old_spec_fn = '';
  for idx = 1:length(spec_gps_time)
    record(idx) = find(records.gps_time > spec_gps_time(idx), 1);
    spec_gps(idx) = records.gps_time(record(idx));
    spec_frm(idx) = find(frames.frame_idxs < record(idx), 1, 'last');
    
    spec_fn{idx} = fullfile(ct_filename_out(param, 'deconv', ''), sprintf('Data_%s_%03d.mat', param.day_seg, spec_frm(idx)));
    if ~exist(spec_fn{idx},'file')
      spec_radar_peak(idx) = NaN;
      spec_radar_surf(idx) = NaN;
      spec_atm(idx) = NaN;
      spec_atm_slope(idx) = NaN;
      spec_radar_slope(idx) = NaN;
      continue;
    end
    if ~strcmpi(old_spec_fn,spec_fn{idx})
      mdata = load(spec_fn{idx});
    end
    old_spec_fn = spec_fn{idx};
    [time_offset,rline] = min(abs(mdata.GPS_time - spec_gps_time(idx)));
    if time_offset > 1
      warning('Time offset too large (%d sec)\n', time_offset);
    end
    
    [~,spec_radar_peak(idx)] = max(mdata.Data(:,rline));
    spec_radar_peak(idx) = mdata.Time(spec_radar_peak(idx));
    spec_radar_surf(idx) = mdata.Surface(rline);
    warning off 'MATLAB:interp1:NaNinY'
    spec_atm(idx) = interp1(layers(radar_idx).gps_time, layers(ref_idx).twtt_ref, spec_gps_time(idx));
    warning on 'MATLAB:interp1:NaNinY'
    
    % Find the time 50 m before and after
    slope_along_track = 50;
    start_record = record(idx);
    while start_record > 1 && along_track(record(idx)) - along_track(start_record) < slope_along_track
      start_record = start_record - 1;
    end
    stop_record = record(idx);
    while stop_record < length(along_track) && along_track(stop_record) - along_track(record(idx)) < slope_along_track
      stop_record = stop_record + 1;
    end
    dx = along_track(stop_record) - along_track(start_record);
    elev_time = records.elev(start_record:stop_record);
    delev = (elev_time - mean(elev_time)) / (c/2);
    atm_times = layers(ref_idx).twtt_ref(start_record:stop_record) - delev;
    radar_times = records.surface(start_record:stop_record) - delev;
    spec_atm_slope(idx) = max(atm_times) - min(atm_times);
    spec_radar_slope(idx) = max(radar_times) - min(radar_times);
    
    if enable_visible_plot && ~isnan(spec_atm(idx))
      fprintf('%d of %d (%s)\n', idx, length(spec_gps_time), datestr(now));
      spec_error = spec_atm(idx) - spec_radar_surf(idx)
      figure(1); clf;
      imagesc(mdata.GPS_time, mdata.Time, lp(mdata.Data))
      hold on
      plot(spec_gps_time(idx), spec_radar_peak(idx), 'bx');
      plot(spec_gps_time(idx), spec_radar_surf(idx), 'kx');
      plot(layers(radar_idx).gps_time, surf.dem_twtt, 'k-');
      plot([spec_gps_time(idx) spec_gps_time(idx)], mdata.Time([1 end]), 'k-');
      hold off;
      xlim(mdata.GPS_time(rline) + [-3 3]);
      ylim(spec_atm(idx) + [-10e-9 10e-9]);
      keyboard
    end
  end
  
  save(deconv_fn,'-append','spec_gps_time','spec_radar_surf','spec_radar_peak','spec_atm','spec_frm','spec_atm_slope','spec_radar_slope');
  
  spec_error = spec_radar_surf - spec_atm;
  spec_error = spec_error(~isnan(spec_error));
  fprintf('  Median error (ns)\t%.2f\n', median(spec_error)*1e9);
  figure(1); clf;
  title(param.day_seg,'interpreter','none')
  plot(sort(spec_error))
  if ~isempty(spec_error)
    ylim(median(spec_error) + [-3e-9 3e-9])
  end
  grid on;
  drawnow;
end

% =====================================================================
%% Clean up
% =====================================================================

fprintf('Done %s (%s)\n', param.day_seg, datestr(now));

if enable_visible_plot
  for idx=1:length(h_fig); figure(h_fig(idx)); end;
  keyboard
else
  try
    delete(h_fig);
  end
end
